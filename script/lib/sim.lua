
local string = require"string"
local ril = require"ril"
local sys = require"sys"
local base = _G
local os = require"os"
module(...)

local tonumber = base.tonumber
local tostring = base.tostring
local req = ril.request
local imsi
local iccid,cpinsta
local smatch = string.match

function geticcid()
	return iccid or ""
end

function getimsi()
	return imsi or ""
end

function getmcc()
	return (imsi ~= nil and imsi ~= "") and string.sub(imsi,1,3) or ""
end

function getmnc()
	return (imsi ~= nil and imsi ~= "") and string.sub(imsi,4,5) or ""
end

local function rsp(cmd,success,response,intermediate)
	if cmd == "AT+ICCID" then
		iccid = smatch(intermediate,"+ICCID:%s*(%w+)") or ""
	elseif cmd == "AT+CIMI" then
		imsi = intermediate
		sys.dispatch("IMSI_READY")
	elseif cmd=="AT+CPIN?" then
		base.print("sim.rsp",cmd,success,response,intermediate)
		if not success or intermediate==nil then
			urc("+CPIN:NOT INSERTED","+CPIN")
		else
			urc(intermediate,smatch(intermediate,"((%+%w+))"))
		end
		ril.regurc("+CPIN",urc)
	end
end

function urc(data,prefix)
	base.print('simurc',data,prefix)
	
	if prefix == "+CPIN" then
		if smatch(data,"+CPIN:%s*READY") then
			if cpinsta~="RDY" then
				req("AT+ICCID")
				req("AT+CIMI")				
				cpinsta = "RDY"
			end
			sys.dispatch("SIM_IND","RDY")
		elseif smatch(data,"+CPIN:%s*NOT INSERTED") then
			if cpinsta~="NIST" then				
				cpinsta = "NIST"
			end
			sys.dispatch("SIM_IND","NIST")
		else
			if cpinsta~="NORDY" then				
				cpinsta = "NORDY"
			end
			if data == "+CPIN: SIM PIN" then
				sys.dispatch("SIM_IND_SIM_PIN")	
			end
			sys.dispatch("SIM_IND","NORDY")
		end
	elseif prefix == '+ESIMS' then	
		base.print('testetst',data)
		if data == '+ESIMS: 1' then
			if cpinsta~="RDY" then				
				cpinsta = "RDY"
			end
			sys.dispatch("SIM_IND","RDY")
		else
			if cpinsta~="NIST" then 				
				cpinsta = "NIST"
			end
			sys.dispatch("SIM_IND","NIST")
		end	
	end
end

local function cpinqry()
	ril.regrsp("+CPIN",rsp)
	ril.deregurc("+CPIN")
	req("AT+CPIN?",nil,nil,nil,{skip=true})
end

ril.regrsp("+ICCID",rsp)
ril.regrsp("+CIMI",rsp)
ril.regurc("+CPIN",urc)
sys.timer_loop_start(cpinqry,60000)
