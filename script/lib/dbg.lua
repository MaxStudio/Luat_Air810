--[[
模块名称：错误管理
模块功能：上报运行时语法错误、脚本控制的重启原因
模块最后修改时间：2017.02.20
]]

--定义模块,导入依赖库
local link = require"link"
module(...,package.seeall)


--prot,server,port：传输层协议(TCP或者UDP)，服务器地址和端口
--FREQ：上报间隔，单位毫秒，如果错误信息上报后，没有收到OK回复，则每过此间隔都会上报一次
--lid：socket id
local prot,server,port,FREQ,lid = "UDP","ota.airm2m.com",9072,1800000
--DBG_FILE：错误文件路径
--resinf,inf：DBG_FILE中的错误信息和sys.lua中LIB_ERR_FILE中的错误信息
--luaerr："/luaerrinfo.txt"中的错误信息
local DBG_FILE,resinf,inf,luaerr,d1,d2 = "/dbg.txt",""
--LIB_ERR_FILE：存储脚本错误的文件路径
--liberr: "/lib_err.txt"中的错误信息
local LIB_ERR_FILE,liberr = "/lib_err.txt",""

--[[
函数名：writetxt
功能  ：读取文本文件中的全部内容
参数  ：
		f：文件路径
返回值：文本文件中的全部内容，读取失败为空字符串或者nil
]]
local function readtxt(f)
	local file,rt = io.open(f,"r")
	if file == nil then
		print("dbg can not open file",f)
		return ""
	end
	rt = file:read("*a")
	file:close()
	return rt
end

--[[
函数名：writetxt
功能  ：写文本文件
参数  ：
		f：文件路径
		v：要写入的文本内容
返回值：无
]]
local function writetxt(f,v)
	local file = io.open(f,"w")
	if file == nil then
		print("dbg open file to write err",f)
		return
	end
	local rt = file:write(v)
	if not rt then
		sys.removegpsdat()
		file:write(v)		
	end
	file:close()
end

local function writepara()
	if resinf then
		print("dbg_w",resinf)
		writetxt(DBG_FILE,resinf)
	end
end

local function initpara()
	inf = readtxt(DBG_FILE) or ""
	print("dbg inf",inf)
	liberr = readtxt(LIB_ERR_FILE) or ""
	--liberr = liberr..";poweron:"..rtos.poweron_reason()
end

--[[
函数名：getlasterr
功能  ：获取lua运行时的语法错误
参数  ：无
返回值：无
]]
local function getlasterr()
	luaerr = readtxt("/luaerrinfo.txt") or ""
end

--[[
函数名：valid
功能  ：是否有错误的信息需要上报
参数  ：无
返回值：true需要上报，false不需要上报
]]
local function valid()
	return ((string.len(luaerr) > 0) or (string.len(inf) > 0) or (string.len(liberr) > 0)) and _G.PROJECT
end

--[[
函数名：snd
功能  ：发送错误信息到后台
参数  ：无
返回值：无
]]
local function snd()
	local data = (luaerr or "") .. (inf or "")..(liberr or "")
	if string.len(data) > 0 then
		link.send(lid,_G.PROJECT .. "," .. (_G.VERSION and (_G.VERSION .. ",") or "") .. misc.getimei() .. "," .. data)
		sys.timer_start(snd,FREQ)
	end
end

local rests = ""

--连接后台失败后的重连次数
local reconntimes = 0
--[[
函数名：reconn
功能  ：连接后台失败后，重连处理
参数  ：无
返回值：无
]]
local function reconn()
	if reconntimes < 3 then
		reconntimes = reconntimes+1
		link.connect(lid,prot,server,port)
	end
end

--[[
函数名：nofity
功能  ：socket状态的处理函数
参数  ：
        id：socket id，程序可以忽略不处理
        evt：消息事件类型
		val： 消息事件参数
返回值：无
]]
local function notify(id,evt,val)
	print("dbg notify",id,evt,val)
	if id ~= lid then return end
	if evt == "CONNECT" then
		if val == "CONNECT OK" then
			sys.timer_stop(reconn)
			reconntimes = 0
			rests = ""
			snd()
		else
			sys.timer_start(reconn,5000)
		end
	elseif evt == "STATE" and val == "CLOSED" then
		link.close(lid)
	end
end

--[[
函数名：recv
功能  ：socket接收数据的处理函数
参数  ：
        id ：socket id，程序可以忽略不处理
        data：接收到的数据
返回值：无
]]
local function recv(id,data)
	if data == "OK" then
		sys.timer_stop(snd)
		link.close(lid)
		resinf = ""
		inf = ""
		writepara()
		luaerr = ""
		liberr = ""
		os.remove("/luaerrinfo.txt")
		os.remove(LIB_ERR_FILE)
	end
end

--[[
函数名：init
功能  ：初始化
参数  ：
        id ：socket id，程序可以忽略不处理
        data：接收到的数据
返回值：无
]]
local function init()
	--读取错误文件中的错误
	initpara()
	--获取lua运行时语法错误
	getlasterr()
	if valid() then
		lid = link.open(notify,recv)
		link.connect(lid,prot,server,port)
	end
end

--[[
函数名：restart
功能  ：重启
参数  ：
        r：重启原因
返回值：无
]]
function restart(r)
	print("dbg restart:",r)
	resinf = "RST:" .. r .. ";"
	writepara()
	rtos.restart()	
end

local trcfile,trcflg,fd,res1,res2,res3 = "/dbg_trace.txt"

function rwriete(dat)
	local rt = fd:write(dat)
	if not rt then
		sys.removegpsdat()
		fd:write(dat)
	end
end

function savetrc(...)
	if not fd and trcflg then opntrc() end
	if fd then
		res1,res2,res3 = fd:seek("end")
		if res1 == nil then
			clstrc()
			opntrc()
			fd:seek("end")
		end
		rwriete(string.sub(misc.getclockstr(),5,12)..":")
		for i=1,arg.n do
			local o = arg[i]
			if type(o) == "number" then
				rwriete(o)
			elseif type(o) == "string" then
				rwriete(o)
			elseif type(o) == "boolean" then
				rwriete(tostring(o))
			elseif type(o) == "table" then
				rwriete("table")
			elseif type(o) == "nil" then
				rwriete("nil")
			end
			rwriete(",")
		end
		
		rwriete("\n")
	end	
end

function opntrc()
	if not fd then fd = io.open(trcfile,"a+") end
	if fd then
		trcflg = true
	end
	
	return fd
end

function clstrc()
	if fd then fd:close() end
	fd = nil
	trcflg = false
end

function deltrc()
	if fd then fd:close() end
	fd = nil
	os.remove(trcfile)
end

init()
