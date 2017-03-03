--[[
模块名称：杂项管理
模块功能：序列号、IMEI、底层软件版本号、时钟、是否校准、飞行模式、查询电池电量等功能
模块最后修改时间：2017.02.14
]]

--定义模块,导入依赖库
local string = require"string"
local ril = require"ril"
local sys = require"sys"
local base = _G
local os = require"os"
local io = require"io"
module(...)

--加载常用的全局函数至本地
local tonumber = base.tonumber
local tostring = base.tostring
local print = base.print
local req = ril.request
local smatch = string.match
local sn,snrdy
local ver,blver
local imei

local CCLK_QUERY_TIMER_PERIOD = 60*1000
local clk,calib,cbfunc,audflg={},false

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
	local prefix = smatch(cmd,"AT(%+%u+)")
	--查询序列号
	if cmd == "AT+WISN?" then
		if intermediate then sn = smatch(intermediate,"+WISN:%s*(.+)") end
		if not snrdy then sys.dispatch("SN_READY") snrdy = true end
	--查询底层软件版本号
	elseif cmd == "AT+VER" then
		if intermediate then
			ver = smatch(intermediate,"+VER:%s*(.+)")
			sys.dispatch("BASE_VER_IND",smatch(ver,"(_V%d+)"))
		end
	elseif cmd == "AT+BLVER" then
		if intermediate then
			blver = smatch(intermediate,"+BLVER:%s*(.+)")
			sys.dispatch("BL_VER_IND",blver)
		end
	elseif cmd == "AT+CGSN" then
		imei = intermediate
		sys.dispatch("IMEI_READY")
	elseif smatch(cmd,"AT%+EGMR=") then
		if smatch(cmd,"AT%+EGMR=%d,(%d)")=="7" then return end
	elseif smatch(cmd,"AT%+CSDS=") then
	elseif smatch(cmd,"AT%+WISN=") then
	elseif prefix == "+CCLK" then
		startclktimer()
	elseif cmd == "AT+ATWMFT=99" then
		print('ATWMFT',intermediate)
		if intermediate == "SUCC" then
			calib = true
		else
			calib = false
		end
	elseif cmd == "AT+AUD?" then
		print('AT+AUD?',intermediate)
		if intermediate then
			audflg = smatch(intermediate,"+AUD=1")
		end
	end
	if cbfunc then
		cbfunc(cmd,success,response,intermediate)
		cbfunc = nil
	end
end

--[[
函数名：setclock
功能  ：设置系统时间
参数  ：
		t：系统时间表，格式参考：{year=2017,month=2,day=14,hour=14,min=2,sec=58}
		rspfunc：设置系统时间后的用户自定义回调函数
返回值：无
]]
function setclock(t,rspfunc)
	if t.year - 2000 > 38 then
		if rspfunc then rspfunc() end
		return
	end
	cbfunc = rspfunc
	req(string.format("AT+CCLK=\"%02d/%02d/%02d,%02d:%02d:%02d\"",string.sub(t.year,3,4),t.month,t.day,t.hour,t.min,t.sec),nil,rsp)
end

--[[
函数名：getclockstr
功能  ：获取系统时间字符串
参数  ：无
返回值：系统时间字符串，格式为YYMMDDhhmmss，例如170214141602，17年2月14日14时16分02秒
]]
function getclockstr()
	clk = os.date("*t")
	clk.year = string.sub(clk.year,3,4)
	return string.format("%02d%02d%02d%02d%02d%02d",clk.year,clk.month,clk.day,clk.hour,clk.min,clk.sec)	
end

local function needupdatetime(newtime,precision)
	if newtime and os.time(newtime) and os.date("*t") and os.time(os.date("*t")) then
		local secdif = os.difftime(os.time(os.date("*t")),os.time(newtime))
		if secdif and secdif >= precision or secdif <= (0-precision) then
			print("needupdatetime",secdif)
			return true
		end
	end
	return false
end


function setclk(t,precision,rspfunc)
	if t.year - 2000 > 38 then
		if rspfunc then rspfunc() end
		return
	end
	if needupdatetime(t,precision) then
		setclock(t,rspfunc)
	else
		if rspfunc then rspfunc(nil,true) end
	end
	
	sys.dispatch("SET_CLK_IND")
end

--[[
函数名：getweek
功能  ：获取星期
参数  ：无
返回值：星期，number类型，1-7分别对应周一到周日
]]
function getweek()
	clk = os.date("*t")
	return ((clk.wday == 1) and 7 or (clk.wday - 1))
end

--[[
函数名：getclock
功能  ：获取系统时间表
参数  ：无
返回值：table类型的时间，例如{year=2017,month=2,day=14,hour=14,min=19,sec=23}
]]
function getclock()
	return os.date("*t")
end

--[[
函数名：startclktimer
功能  ：选择性的启动整分时钟通知定时器
参数  ：无
返回值：无
]]
function startclktimer()
	sys.dispatch("CLOCK_IND")
	print('CLOCK_IND',os.date("*t").sec)
	sys.timer_start(startclktimer,(60-os.date("*t").sec)*1000)
end

function chingeclktimer()
	sys.timer_start(startclktimer,(60-os.date("*t").sec)*1000)
end

--[[
函数名：getsn
功能  ：获取序列号
参数  ：无
返回值：序列号，如果未获取到返回""
]]
function getsn()
	return sn or ""
end

function getbasever()
	if ver and base._INTERNAL_VERSION then
		local d1,d2,bver,bprj,lver
		d1,d2,bver,bprj = string.find(ver,"_V(%d+)_(.+)")
		d1,d2,lver = string.find(base._INTERNAL_VERSION,"_V(%d+)")

		if bver ~= nil and bprj ~= nil and lver ~= nil then
			return "SW_V" .. lver .. "_" .. bprj .. "_B" .. bver
		end
	end
	return ""
end

function getblver()
	return blver or ""
end

function getimei()
	return imei or ""
end

function setflymode(val)
	req("AT+CFUN="..(val and 0 or 1))
end

function set(typ,val,cb)
	cbfunc = cb
	if  typ == "WISN" then
		req("AT+" .. typ .. "=\"" .. val .. "\"")
	elseif typ == "EGMR" then
		req("AT+" .. typ .. "=" .. val)
		if string.sub(val,1,1) == '1' then
			req("AT+CSDS=1")
		end
		if string.sub(val,3,3)=="7" then
			req("AT+CGSN")
		end
	elseif typ == "AMFAC" then
		req("AT+" .. typ .. "=" .. val)
	elseif typ == "CFUN" then
		req("AT+" .. typ .. "=" .. val)
	elseif typ == "CGSN" then
		req("AT+CGSN")
	elseif typ == "UARTSWITCH" then
		req("AT+" .. typ .. "=" .. val)
	end
end

--[[
函数名：getcalib
功能  ：获取是否校准标志
参数  ：无
返回值：true为校准，其余为没校准
]]
function getcalib()
	return calib
end

function getaudflg()
	return audflg
end

--注册以下AT命令的应答处理函数
ril.regrsp("+ATWMFT",rsp)
ril.regrsp("+WISN",rsp)
ril.regrsp("+VER",rsp)
ril.regrsp("+BLVER",rsp)
ril.regrsp("+CGSN",rsp)
ril.regrsp("+EGMR",rsp)
ril.regrsp("+CSDS",rsp)
ril.regrsp("+AMFAC",rsp)
ril.regrsp("+CFUN",rsp)
ril.regrsp("+AUD",rsp)
req("AT+ATWMFT=99")
req("AT+WISN?")
req("AT+CGSN")
req("AT+AUD?")
startclktimer()
