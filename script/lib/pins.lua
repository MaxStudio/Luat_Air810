module(...,package.seeall)

WIFI_RST = {pin=pio.P0_31,init=false}
WIFI_PWR = {pin=pio.P1_1}
GSENSOR_INT1 = {name="GSENSOR_INT1",pin=pio.P1_3,dir=pio.INPUT,valid=1}
BT_WDT_BB = {name="BT_WDT_BB",pin=pio.P0_14,dir=pio.INPUT,valid=1}
BB_RESET_BT = {name="BB_RESET_BT",pin=pio.P0_20}
if _G.HWVER>="A13" then
BTWIFI_ATENA = {pin=pio.P1_0}
BT_WAKE = {pin=pio.P0_2}
BB_SLP_STATUS = {pin=pio.P0_3,dir=pio.INPUT,valid=1}
end

local allpin
if _G.HWVER>="A13" then
	allpin = {WIFI_RST,WIFI_PWR,BTWIFI_ATENA,BT_WAKE,GSENSOR_INT1,BB_SLP_STATUS}
else
	allpin = {WIFI_RST,WIFI_PWR,GSENSOR_INT1}
end

function get(p)
	if p.get then return p.get(p) end
	return pio.pin.getval(p.pin) == p.valid
end

function set(bval,p)
	p.val = bval

	if not p.inited and (not p.ptype or p.ptype == "GPIO") then
		p.inited = true
		pio.pin.setdir(p.dir or pio.OUTPUT,p.pin)
	end

	if p.set then p.set(bval,p) return end

	if p.ptype and p.ptype ~= "GPIO" then print("unknwon pin type:",p.ptype) return end

	local valid = p.valid == 0 and 0 or 1
	local notvalid = p.valid == 0 and 1 or 0
	local val = bval == true and valid or notvalid
	print("pins.set",p.pin,val)
	if p.pin then pio.pin.setval(val,p.pin) end
end

function setdir(dir,p)
	if p and not p.ptype or p.ptype == "GPIO" then
		if not p.inited then
			p.inited = true
		end
		if p.pin then
			pio.pin.close(p.pin)
			pio.pin.setdir(dir,p.pin)
			p.dir = dir
		end
	end
end

function init()	
	for _,v in ipairs(allpin) do
		if v.init == false then
			
		elseif not v.ptype or v.ptype == "GPIO" then
			v.inited = true
			pio.pin.setdir(v.dir or pio.OUTPUT,v.pin)
			if not v.dir or v.dir == pio.OUTPUT then
				set(v.defval or false,v)
			elseif v.dir == pio.INTPUT or v.dir == pio.INT then
				v.val = pio.pin.getval(v.pin) == v.valid
			end
		elseif v.set then
			set(v.defval or false,v)
		end
	end
end

local function intmsg(msg)
	local status = 0

	if msg.int_id == cpu.INT_GPIO_POSEDGE then status = 1 end

	for _,v in ipairs(allpin) do
		if v.dir == pio.INT and msg.int_resnum == v.pin then
			v.val = v.valid == status
			sys.dispatch(string.format("PIN_%s_IND",v.name),v.val)
			return
		end
	end
end
sys.regmsg(rtos.MSG_INT,intmsg)
init()
--pio.pin.setdir(pio.INPUT, pio.P1_2)
pmd.ldoset(2,pmd.LDO_VMC)
