--[[
模块名称：网络管理
模块功能：信号查询、GSM网络状态查询、网络指示灯控制、临近小区信息查询
模块最后修改时间：2017.02.17
]]

--定义模块,导入依赖库
local base = _G
local string = require"string"
local sys = require "sys"
local ril = require "ril"
local sim = require"sim"
module("net")

--加载常用的全局函数至本地
local dispatch = sys.dispatch
local req = ril.request
local smatch = string.match
local tonumber,tostring = base.tonumber,base.tostring

--GSM网络状态：
--INIT：开机初始化中的状态
--REGISTERED：注册上GSM网络
--UNREGISTER：未注册上GSM网络
local state,cengset = "INIT"

--lac：位置区ID
--ci：小区ID
--rssi：信号强度
local lac,ci,rssi = "","",0

--csqqrypriod：信号强度定时查询间隔
--cengqrypriod：当前和临近小区信息定时查询间隔
local csqqrypriod,cengqrypriod = 60*1000
--当前小区和临近小区信息表
local cellinfo = {}

--[[
函数名：creg
功能  ：解析CREG信息
参数  ：
		data：CREG信息字符串，例如+CREG: 2、+CREG: 1,"18be","93e1"、+CREG: 5,"18a7","cb51"
返回值：无
]]
local function creg(data)
	local p1,s
	--获取注册状态
	_,_,p1 = string.find(data,"%d,%s*(%d)")
	if p1 == nil then
		_,_,p1 = string.find(data,"(%d)")
		if p1 == nil then
			return
		end
	end
	--已注册
	if p1 == "1" or p1 == "5" then
		s = "REGISTERED"
	--未注册
	else
		s = "UNREGISTER"
		-- req("AT+ESIMS?")
	end
	--注册状态发生了改变
	if s ~= state then
		--[[
		if not cengqrypriod and s == "REGISTERED" then
			setcengqueryperiod(60000)
		else
			cengquery()
		end
		--]]
		state = s
		dispatch("NET_STATE_CHANGED",s)
	end
	--已注册并且lac或ci发生了变化
	if state == "REGISTERED" then
		local p2,p3 = string.match(data,"\"(%x+)\",%s*\"(%x+)\"")
		if lac ~= p2 or ci ~= p3 then
			lac = p2
			ci = p3
			--产生一个内部消息NET_CELL_CHANGED，表示lac或ci发生了变化
			dispatch("NET_CELL_CHANGED")
		end
		if not cengset then
			cengset = true
			req("AT+CENG=1")
		end
	end
end

--[[
函数名：resetcellinfo
功能  ：重置当前小区和临近小区信息表
参数  ：无
返回值：无
]]
local function resetcellinfo()
	local i
	cellinfo.cnt = 11 --最大个数
	for i=1,cellinfo.cnt do
		cellinfo[i] = {}
		cellinfo[i].mcc,cellinfo[i].mnc = nil
		cellinfo[i].lac = 0
		cellinfo[i].ci = 0
		cellinfo[i].rssi = 0
		cellinfo[i].ta = 0
	end
end

--[[
函数名：ceng
功能  ：解析当前小区和临近小区信息
参数  ：
		data：当前小区和临近小区信息字符串，例如下面中的每一行：
		+CENG:1,1
		+CENG:0,"573,24,99,460,0,13,49234,10,0,6311,255"
		+CENG:1,"579,16,460,0,5,49233,6311"
		+CENG:2,"568,14,460,0,26,0,6311"
		+CENG:3,"584,13,460,0,10,0,6213"
		+CENG:4,"582,13,460,0,51,50146,6213"
		+CENG:5,"11,26,460,0,3,52049,6311"
		+CENG:6,"29,26,460,0,32,0,6311"
返回值：无
]]
local function ceng(data)
	--只处理有效的CENG信息
	if string.find(data,"%+CENG:%d+,.+") then
		local id,rssi,lac,ci,ta,mcc,mnc
		id = string.match(data,"%+CENG:(%d)")
		id = tonumber(id)
		mcc,mnc,lac,ci,rssi=string.match(data, "%+CENG:%d,(%w+),(%d+),(%d+),(%d+),%d+,(%d+)")
		
		--解析正确
		if rssi and ci and lac and mcc and mnc then
			--如果是第一条，清除信息表
			if id == 0 then
				resetcellinfo()
			end
			--保存mcc、mnc、lac、ci、rssi、ta
			cellinfo[id+1].mcc = tostring(tonumber(mcc,16))
			cellinfo[id+1].mnc = mnc
			cellinfo[id+1].lac = tonumber(lac)
			cellinfo[id+1].ci = tonumber(ci)
			cellinfo[id+1].rssi = ((tonumber(rssi) == 99) and 0 or tonumber(rssi))/2
			cellinfo[id+1].ta = tonumber(ta or "0")
			--产生一个内部消息CELL_INFO_IND，表示读取到了新的当前小区和临近小区信息
			if id == 0 then
				dispatch("CELL_INFO_IND",cellinfo)
			end
		end
	end
end

--[[
函数名：neturc
功能  ：本功能模块内“注册的底层core通过虚拟串口主动上报的通知”的处理
参数  ：
		data：通知的完整字符串信息
		prefix：通知的前缀
返回值：无
]]
local function neturc(data,prefix)
	if prefix == "+CREG" then
		req("AT+CSQ",nil,nil,nil,{skip=true}) -- 收到网络状态变化时,更新一下信号值
		creg(data)
	elseif prefix == "+CENG" then
		ceng(data)
	end
end

--[[
函数名：getstate
功能  ：获取GSM网络注册状态
参数  ：无
返回值：GSM网络注册状态(INIT、REGISTERED、UNREGISTER)
]]
function getstate()
	return state
end

--[[
函数名：getmcc
功能  ：获取当前小区的mcc
参数  ：无
返回值：当前小区的mcc，如果还没有注册GSM网络，则返回sim卡的mcc
]]
function getmcc()
	return cellinfo[1].mcc or sim.getmcc()
end

--[[
函数名：getmnc
功能  ：获取当前小区的mnc
参数  ：无
返回值：当前小区的mnc，如果还没有注册GSM网络，则返回sim卡的mnc
]]
function getmnc()
	return cellinfo[1].mnc or sim.getmnc()
end

--[[
函数名：getlac
功能  ：获取当前位置区ID
参数  ：无
返回值：当前位置区ID(16进制字符串，例如"18be")，如果还没有注册GSM网络，则返回""
]]
function getlac()
	return lac
end

--[[
函数名：getci
功能  ：获取当前小区ID
参数  ：无
返回值：当前小区ID(16进制字符串，例如"93e1")，如果还没有注册GSM网络，则返回""
]]
function getci()
	return string.sub(ci,-4)
end

--[[
函数名：getrssi
功能  ：获取信号强度
参数  ：无
返回值：当前信号强度(取值范围0-31)
]]
function getrssi()
	return rssi
end

--[[
函数名：getcell
功能  ：获取当前和临近小区以及信号强度的拼接字符串
参数  ：无
返回值：当前和临近小区以及信号强度的拼接字符串，例如：49234.30.49233.23.49232.18.
]]
function getcell()
	local i,ret = 1,""
	for i=1,cellinfo.cnt do
		if cellinfo[i] and cellinfo[i].lac and cellinfo[i].lac ~= 0 and cellinfo[i].ci and cellinfo[i].ci ~= 0 then
			ret = ret..cellinfo[i].ci.."."..cellinfo[i].rssi.."."
		end
	end
	return ret
end

--[[
函数名：getcellinfo
功能  ：获取当前和临近位置区、小区以及信号强度的拼接字符串
参数  ：无
返回值：当前和临近位置区、小区以及信号强度的拼接字符串，例如：6311.49234.30;6311.49233.23;6322.49232.18;
]]
function getcellinfo()
	local i,ret = 1,""
	for i=1,cellinfo.cnt do
		if cellinfo[i] and cellinfo[i].lac and cellinfo[i].lac ~= 0 and cellinfo[i].ci and cellinfo[i].ci ~= 0 then
			ret = ret..cellinfo[i].lac.."."..cellinfo[i].ci.."."..cellinfo[i].rssi..";"
		end
	end
	return ret
end

--[[
函数名：getcellinfoext
功能  ：获取当前和临近位置区、小区、mcc、mnc、以及信号强度的拼接字符串
参数  ：无
返回值：当前和临近位置区、小区、mcc、mnc、以及信号强度的拼接字符串，例如：460.01.6311.49234.30;460.01.6311.49233.23;460.02.6322.49232.18;
]]
function getcellinfoext()
	local i,ret = 1,""
	for i=1,cellinfo.cnt do
		if cellinfo[i] and cellinfo[i].mcc and cellinfo[i].mnc and cellinfo[i].lac and cellinfo[i].lac ~= 0 and cellinfo[i].ci and cellinfo[i].ci ~= 0 then
			ret = ret..cellinfo[i].mcc.."."..cellinfo[i].mnc.."."..cellinfo[i].lac.."."..cellinfo[i].ci.."."..cellinfo[i].rssi..";"
		end
	end
	return ret
end

--[[
函数名：getta
功能  ：获取TA值
参数  ：无
返回值：TA值
]]
function getta()
	return cellinfo[1].ta
end

--[[
函数名：startquerytimer
功能  ：空函数，无功能，只是为了兼容之前写的应用脚本
参数  ：无
返回值：无
]]
function startquerytimer() end

--[[
函数名：simind
功能  ：内部消息SIM_IND的处理函数
参数  ：
                id: 无意义
		para：参数，表示SIM卡状态
返回值：无
]]
local function SimInd(id,para)
	if para ~= "RDY" then
		state = "UNREGISTER"
		dispatch("NET_STATE_CHANGED",state)
	end
	if para == "NIST" then
		sys.timer_stop(queryfun)
	end

	return true
end

--[[
函数名：startcsqtimer
功能  ：有选择性的启动“信号强度查询”定时器
参数  ：无
返回值：无
]]
function startcsqtimer()
	req("AT+CSQ",nil,nil,nil,{skip=true})
	sys.timer_start(startcsqtimer,csqqrypriod)
end

--[[
函数名：startcengtimer
功能  ：有选择性的启动“当前和临近小区信息查询”定时器
参数  ：无
返回值：无
]]
function startcengtimer()
	req("AT+ECELL")
	sys.timer_start(startcengtimer,cengqrypriod)
end

--[[
函数名：rsp
功能  ：本功能模块内“通过虚拟串口发送到底层core软件的AT命令”的应答处理
参数  ：
		cmd：此应答对应的AT命令
		success：AT命令执行结果，true或者false
		response：AT命令的应答中的执行结果字符串
		intermediate：AT命令的应答中的中间信息
返回值：无
]]
local function rsp(cmd,success,response,intermediate)
	local prefix = string.match(cmd,"AT(%+%u+)")

	if intermediate ~= nil then
		if prefix == "+CSQ" then
			local s = smatch(intermediate,"+CSQ:%s*(%d+)")
			if s ~= nil then
				rssi = tonumber(s)
				rssi = rssi == 99 and 0 or rssi
				--产生一个内部消息GSM_SIGNAL_REPORT_IND，表示读取到了信号强度
				dispatch("GSM_SIGNAL_REPORT_IND",success,rssi)
			end
		elseif prefix == "+CENG" then
		end
	end
end

--[[
函数名：setcsqqueryperiod
功能  ：设置“信号强度”查询间隔
参数  ：
		period：查询间隔，单位毫秒
返回值：无
]]
function setcsqqueryperiod(period)
	csqqrypriod = period
	startcsqtimer()
end

--[[
函数名：setcengqueryperiod
功能  ：设置“当前和临近小区信息”查询间隔
参数  ：
		period：查询间隔，单位毫秒。如果小于等于0，表示停止查询功能
返回值：无
]]
function setcengqueryperiod(period)
	if period ~= cengqrypriod then
		if period <= 0 then
			sys.timer_stop(startcengtimer)
		else
			cengqrypriod = period
			startcengtimer()
		end
	end
end

--[[
函数名：cengquery
功能  ：查询“当前和临近小区信息”
参数  ：无
返回值：无
]]
function cengquery()
	req("AT+ECELL")
end

--[[
函数名：csqquery
功能  ：查询“信号强度”
参数  ：无
返回值：无
]]
function csqquery()
	req("AT+CSQ",nil,nil,nil,{skip=true})
end

--注册消息处理函数表
sys.regapp(SimInd,"SIM_IND")
--注册+CREG和+CENG通知的处理函数
ril.regurc("+CREG",neturc)
ril.regurc("+CENG",neturc)
--注册AT+CCSQ命令的应答处理函数
ril.regrsp("+CSQ",rsp)
req("AT+CREG=2")
req("AT+CREG?")
--req("AT+CENG=1")
-- 8秒后查询第一次csq
sys.timer_start(startcsqtimer,8*1000)
resetcellinfo()
