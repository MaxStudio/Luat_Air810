-- ÆäËûÅäÖÃ
local string = require"string"
local ril = require"ril"
local sys = require"sys"
local base = _G
local os = require"os"
local io = require"io"
module(...)

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

local function rsp(cmd,success,response,intermediate)
	local prefix = smatch(cmd,"AT(%+%u+)")
	if cmd == "AT+WISN?" then
		if intermediate then sn = smatch(intermediate,"+WISN:%s*(.+)") end
		if not snrdy then sys.dispatch("SN_READY") snrdy = true end
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

function setclock(t,rspfunc)
	if t.year - 2000 > 38 then
		if rspfunc then rspfunc() end
		return
	end
	cbfunc = rspfunc
	req(string.format("AT+CCLK=\"%02d/%02d/%02d,%02d:%02d:%02d\"",string.sub(t.year,3,4),t.month,t.day,t.hour,t.min,t.sec),nil,rsp)
end

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

function getweek()
	clk = os.date("*t")
	return ((clk.wday == 1) and 7 or (clk.wday - 1))
end
function getclock()
	return os.date("*t")
end

function startclktimer()
	sys.dispatch("CLOCK_IND")
	print('CLOCK_IND',os.date("*t").sec)
	sys.timer_start(startclktimer,(60-os.date("*t").sec)*1000)
end

function chingeclktimer()
	sys.timer_start(startclktimer,(60-os.date("*t").sec)*1000)
end
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

function getcalib()
	return calib
end

function getaudflg()
	return audflg
end

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
