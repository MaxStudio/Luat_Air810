local base = _G
local string = require"string"
local table = require"table"
local sys = require"sys"
local ril = require"ril"
local net = require"net"
local rtos = require"rtos"
local sim = require"sim"
local socket = require"tcpipsock"
module("link",package.seeall)

local print = base.print
local pairs = base.pairs
local tonumber = base.tonumber
local tostring = base.tostring
local req = ril.request
local extapn
-- constant
local MAXLINKS = 7 -- id 0-7
local IPSTART_INTVL = 10000 --IP环境建立失败时间隔10秒重连

-- local var
local linklist = {}
local ipstatus,sckconning = "IP INITIAL"
local cgatt
local apn = "CMNET"
local connectnoretrestart = false
local connectnoretinterval

function setapn(a)
	apn = a
	extapn=true
end

local function connectingtimerfunc(id)
	print("connectingtimerfunc",id,connectnoretrestart)
	if connectnoretrestart then
		sys.restart("link.connectingtimerfunc")
	end
end

local function stopconnectingtimer(id)
	print("stopconnectingtimer",id)
	sys.timer_stop(connectingtimerfunc,id)
end

local function startconnectingtimer(id)
	print("startconnectingtimer",id,connectnoretrestart,connectnoretinterval)
	if id and connectnoretrestart and connectnoretinterval and connectnoretinterval > 0 then
		sys.timer_start(connectingtimerfunc,connectnoretinterval,id)
	end
end

function setconnectnoretrestart(flag,interval)
	connectnoretrestart = flag
	connectnoretinterval = interval
end

local function setupIP()
	print("link.setupIP:",ipstatus,cgatt)
	if ipstatus ~= "IP INITIAL" then
		return
	end

	if cgatt ~= "1" then
		print("setupip: wait cgatt")
		return
	end

	socket.pdp_activate(apn,"","")
end

local function emptylink()
	for i = 0,MAXLINKS do
		if linklist[i] == nil then
			return i
		end
	end

	return nil
end

local function validaction(id,action)
	if linklist[id] == nil then
		print("link.validaction:id nil",id)
		return false
	end

	if action.."ING" == linklist[id].state then -- 同一个状态不重复执行
		print("link.validaction:",action,linklist[id].state)
		return false
	end

	local ing = string.match(linklist[id].state,"(ING)",-3)

	if ing then
		--有其他任务在处理时,不允许处理连接,断链或者关闭是可以的
		if action == "CONNECT" then
			print("link.validaction: action running",linklist[id].state,action)
			return false
		end
	end

	-- 无其他任务在执行,允许执行
	return true
end

function openid(id,notify,recv)
	if id > MAXLINKS or linklist[id] ~= nil then
		print("openid:error",id)
		return false
	end

	local link = {
		notify = notify,
		recv = recv,
		state = "INITIAL",
	}

	linklist[id] = link

	-- 初始化IP环境
	if ipstatus ~= "IP STATUS" and ipstatus ~= "IP PROCESSING" then
		setupIP()
	end

	return true
end

function open(notify,recv)
	local id = emptylink()

	if id == nil then
		return nil,"no empty link"
	end

	openid(id,notify,recv)

	return id
end

function close(id)
	if validaction(id,"CLOSE") == false then
		return false
	end

	linklist[id].state = "CLOSING"

	socket.sock_close(id,1)

	return true
end

function asyncLocalEvent(msg,cbfunc,id,val)
	cbfunc(id,val)
end

sys.regapp(asyncLocalEvent,"LINK_ASYNC_LOCAL_EVENT")

function connect(id,protocol,address,port)
	if validaction(id,"CONNECT") == false or linklist[id].state == "CONNECTED" then
		return false
	end

	linklist[id].state = "CONNECTING"

	if cc and cc.anycallexist() then
		-- 如果打开了通话功能 并且当前正在通话中使用异步通知连接失败
		print("link.connect:failed cause call exist")
		sys.dispatch("LINK_ASYNC_LOCAL_EVENT",statusind,id,"CONNECT FAIL")
		return true
	end

	local connstr = string.format("AT+CIPSTART=%d,\"%s\",\"%s\",%s",id,protocol,address,port)

	if (ipstatus ~= "IP STATUS" and ipstatus ~= "IP PROCESSING") or sckconning then
		-- ip环境未准备好先加入等待
		linklist[id].pending = connstr
	else
		socket.sock_conn(id,(protocol=="TCP") and 0 or 1,tonumber(port),address)
		startconnectingtimer(id)
		sckconning = true
	end

	return true
end

function disconnect(id)
	if validaction(id,"DISCONNECT") == false then
		return false
	end

	if linklist[id].pending then
		linklist[id].pending = nil
		if ipstatus ~= "IP STATUS" and ipstatus ~= "IP PROCESSING" and linklist[id].state == "CONNECTING" then
			print("link.disconnect: ip not ready",ipstatus)
			linklist[id].state = "DISCONNECTING"
			sys.dispatch("LINK_ASYNC_LOCAL_EVENT",closecnf,id,"DISCONNECT","OK")
			return
		end
	end

	linklist[id].state = "DISCONNECTING"

	socket.sock_close(id,1)

	return true
end

function send(id,data)
	if linklist[id] == nil or linklist[id].state ~= "CONNECTED" then
		print("link.send:error",id)
		return false
	end

	if cc and cc.anycallexist() then
		-- 如果打开了通话功能 并且当前正在通话中使用异步通知连接失败
		print("link.send:failed cause call exist")
		return false
	end
	print("link.send",id,string.len(data),(string.len(data) > 200) and "" or data)
	socket.sock_send(id,data)

	return true
end

function getstate(id)
	return linklist[id] and linklist[id].state or "NIL LINK"
end

local function recv(id,data)
	print("link.recv",id,string.len(data)>200 and "" or data)
	if not id or not linklist[id] then
		print("link.recv:error",id)
		return
	end

	if linklist[id].recv then
		linklist[id].recv(id,data)
	else
		print("link.recv:nil recv",id)
	end
end

function linkstatus(data)

end

local function sendcnf(id,result)
	if not id or not linklist[id] then print("link.sendcnf:error",id) return end
	local str = string.match(result,"([%u ])")
	if str == "TCP ERROR" or str == "UDP ERROR" or str == "ERROR" then
		linklist[id].state = result
	end
	linklist[id].notify(id,"SEND",result)
end

function closecnf(id,result)
	if not id or not linklist[id] then
		print("link.closecnf:error",id)
		return
	end
	-- 不管任何的close结果,链接总是成功断开了,所以直接按照链接断开处理
	if linklist[id].state == "DISCONNECTING" then
		linklist[id].state = "CLOSED"
		linklist[id].notify(id,"DISCONNECT","OK")
		stopconnectingtimer(id)
	elseif linklist[id].state == "CLOSING" then
		-- 连接注销,清除维护的连接信息,清除urc关注
		local tlink = linklist[id]
		linklist[id] = nil
		tlink.notify(id,"CLOSE","OK")
		stopconnectingtimer(id)
	elseif linklist[id].state == "SHUTING" then
		linklist[id].state = "CLOSED"
		linklist[id].notify(id,"STATE","CLOSED")
	else
		print("link.closecnf:error",linklist[id].state)
	end
end

-- 状态urc上报,有两种情况:cipstart返回或者链接状态变化
function statusind(id,state)
	if linklist[id] == nil then
		print("link.statusind:nil id",id)
		return
	end

	if state == "SEND FAIL" then -- 快发失败的提示会变成URC
		if linklist[id].state == "CONNECTED" then
			linklist[id].notify(id,"SEND",state)
		else
			print("statusind:send fail state",linklist[id].state)
		end
		return
	end

	local evt

	if linklist[id].state == "CONNECTING" or state == "CONNECT OK" then
		evt = "CONNECT"
	else
		evt = "STATE"
	end

	-- 除非连接成功,否则连接仍然还是在关闭状态
	if state == "CONNECT OK" then
		linklist[id].state = "CONNECTED"
	else
		linklist[id].state = "CLOSED"
	end

	linklist[id].notify(id,evt,state)
	stopconnectingtimer(id)
end

local function connpend()
	for k,v in pairs(linklist) do
		print("link.connpend",v.pending)
		if v.pending then
			local id,protocol,address,port = string.match(v.pending,"AT%+CIPSTART=(%d+),\"(%a+)\",\"(.+)\",(%d+)")
			if id then
				id = tonumber(id)
				socket.sock_conn(id,(protocol=="TCP") and 0 or 1,tonumber(port),address)
				startconnectingtimer(id)
				sckconning = true
			end
			v.pending = nil
			break
		end
	end
end

local function setIPStatus(status)
	print("ipstatus:",status,ipstatus)

	if ipstatus ~= status then
		ipstatus = status
		if ipstatus == "IP STATUS" then
			connpend()
		elseif ipstatus == "IP INITIAL" then -- 重新连接
			sys.timer_start(setupIP,IPSTART_INTVL)		
		else -- 其他异常状态关闭至IP INITIAL
			shut()
		end
	elseif status == "IP INITIAL" then
		sys.timer_start(setupIP,IPSTART_INTVL)
	end
end

local function closeall()
	local i
	for i = 0,MAXLINKS do
		if linklist[i] then
			if linklist[i].state == "CONNECTING" and linklist[i].pending then
				-- 对于尚未进行过的连接请求 不提示close,IP环境建立后自动连接
			elseif linklist[i].state == "INITIAL" then -- 未连接的也不提示
			else
				linklist[i].state = "SHUTING"
				socket.sock_close(i,0)
			end
			stopconnectingtimer(i)
		end
	end
end

function shut()
	closeall()
	socket.pdp_deactivate()
end
reset = shut

local function pdpactcnf(result)
	if result == 1 then
		setIPStatus("IP STATUS")
	else
		socket.pdp_deactivate()
	end
end

local function pdpdeactcnf(result)
	setIPStatus("IP INITIAL")
end

local function pdpdeactind(result)
	closeall()
	setIPStatus("IP INITIAL")
end

local function sockconncnf(id,result)
	statusind(id,(result == 1) and "CONNECT OK" or "ERROR")
	sckconning = nil
	connpend()
end

local function socksendcnf(id,result)
	sendcnf(id,(result == 1) and "SEND OK" or "ERROR")
end

local function sockrecvind(id,cnt)
	if cnt > 0 then
		recv(id,socket.sock_recv(id,cnt))
	end
end

local function sockclosecnf(id,result)
	closecnf(id,(result == 1) and "CLOSE OK" or "ERROR")
end

local function sockcloseind(id,result)
	statusind(id,"CLOSED")
end

local tntfy =
{
	[rtos.MSG_PDP_ACT_CNF] = {nm="PDP_ACT_CNF",hd=pdpactcnf},
	[rtos.MSG_PDP_DEACT_CNF] = {nm="PDP_DEACT_CNF",hd=pdpdeactcnf},
	[rtos.MSG_PDP_DEACT_IND] = {nm="PDP_DEACT_IND",hd=pdpdeactind},
	[rtos.MSG_SOCK_CONN_CNF] = {nm="SOCK_CONN_CNF",hd=sockconncnf},
	[rtos.MSG_SOCK_SEND_CNF] = {nm="SOCK_SEND_CNF",hd=socksendcnf},
	[rtos.MSG_SOCK_RECV_IND] = {nm="SOCK_RECV_IND",hd=sockrecvind},
	[rtos.MSG_SOCK_CLOSE_CNF] = {nm="SOCK_CLOSE_CNF",hd=sockclosecnf},
	[rtos.MSG_SOCK_CLOSE_IND] = {nm="SOCK_CLOSE_IND",hd=sockcloseind},
}

local function ntfy(msg,v1,v2,v3)
	print("link.ntfy",tntfy[msg] and tntfy[msg].nm or "unknown",v1,v2,v3)
	if tntfy[msg] then		
		tntfy[msg].hd(v1,v2,v3)
	end
end

sys.regmsg("sock",ntfy)

-- 在网络正常后初始化ip
local QUERYTIME = 2000
local querycgatt

local function cgattrsp(cmd,success,response,intermediate)
	print("syy cgattrsp",intermediate)
	if intermediate == "+CGATT: 1" then
		if cgatt ~= "1" then
			cgatt = "1"
			sys.dispatch("NET_GPRS_READY",true)

			-- 如果存在链接,那么在gprs附着上以后自动初始化ip环境
			if base.next(linklist) then
				if ipstatus == "IP INITIAL" then
					setupIP()
				else
					setIPStatus("IP STATUS")
				end
			end
		end
		sys.timer_start(querycgatt,60000)
	elseif intermediate == "+CGATT: 0" then
		if cgatt ~= "0" then
			cgatt = "0"
			sys.dispatch("NET_GPRS_READY",false)
		end
		setcgatt(1)
		sys.timer_start(querycgatt,QUERYTIME)
	end
end

querycgatt = function()
	req("AT+CGATT?",nil,cgattrsp,nil,{skip=true})
end

function setquicksend() end
local function netmsg(id,data)
	print("syy netmsg",data)
	if data == "REGISTERED" then
		--mtk需要主动attach
		setcgatt(1)
		sys.timer_start(querycgatt,QUERYTIME)
	elseif  data == "UNREGISTER" then 
		if cgatt ~= "0" then
			cgatt = "0"
			sys.dispatch("NET_GPRS_READY",false)
		end	
	end
	return true
end
local apntable =
{
	["46000"] = "CMNET",
	["46002"] = "CMNET",
	["46004"] = "CMNET",
	["46007"] = "CMNET",
	["46001"] = "UNINET",
	["46006"] = "UNINET",
}

local function proc(id)
	if not extapn then
		apn=apntable[sim.getmcc()..sim.getmnc()] or "CMNET"
	end
	return true
end

function setcgatt(v)
	req("AT+CGATT="..v,nil,nil,nil,{skip=true})
end

function getcgatt()
	return cgatt
end

function getipstatus()
	return ipstatus
end

sys.regapp(proc,"IMSI_READY")
sys.regapp(netmsg,"NET_STATE_CHANGED")
