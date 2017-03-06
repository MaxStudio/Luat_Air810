module(...,package.seeall)

--如下配置了开源模块中所有可用作GPIO的引脚，每个配置只是演示需要
--用户最终需根据自己的需求自行修改

--pin值定义如下：
--pio.P0_XX：表示GPIOXX，例如pio.P0_15，表示GPIO15
--pio.P1_XX：表示GPOXX，例如pio.P1_8，表示GPO8

--dir值定义如下（默认值为pio.OUTPUT）：
--pio.OUTPUT：表示输出，初始化是输出低电平
--pio.OUTPUT1：表示输出，初始化是输出高电平
--pio.INPUT：表示输入，需要轮询输入的电平状态
--pio.INT：表示中断，电平状态发生变化时会上报消息，进入本模块的intmsg函数

--valid值定义如下（默认值为1）：
--valid的值跟本模块中的set、get接口配合使用
--dir为输出时，配合set接口使用，set的第一个参数如果为true，则会输出valid值表示的电平，0表示低电平，1表示高电平
--dir为输入或中断时，配合get接口使用，如果引脚的电平和valid的值一致，get接口返回true；否则返回false
--dir为中断时，配合本模块intmsg函数中的sys.dispatch(string.format("PIN_%s_IND",v.name),v.val)使用，如果引脚的电平和valid的值一致，v.val为true；否则v.val为false
--0
--1

--等价于PIN31 = {pin=pio.P0_10,dir=pio.OUTPUT,valid=1}
--第31个引脚：GPIO10，配置为输出，初始化输出低电平；valid=1，调用set(true,PIN31),则输出高电平，调用set(false,PIN31),则输出低电平
PIN31 = {pin=pio.P0_10}

--第32个引脚：GPIO11；配置为输出，初始化输出高电平；valid=0，调用set(true,PIN32),则输出低电平，调用set(false,PIN32),则输出高电平
PIN32 = {pin=pio.P0_11,dir=pio.OUTPUT1,valid=0}

--如下三个配置含义和PIN31相似
--GPIO16
PIN28 = {pin=pio.P0_16}
--GPIO31
PIN27 = {pin=pio.P0_31}
--GPIO33
PIN26 = {pin=pio.P1_1}

--第25个引脚：GPIO36；配置为中断；valid=1
--产生中断时，如果为高电平，则intmsg中sys.dispatch("PIN_PIN25_IND",true)；如果为低电平，则intmsg中sys.dispatch("PIN_PIN25_IND",false)
--调用get(PIN25)时，如果为高电平，则返回true；如果为低电平，则返回false
PIN25 = {name="PIN25",pin=pio.P1_4,dir=pio.INT,valid=1}

--和PIN31相似
--GPIO35
PIN7 = {pin=pio.P1_3}

--第38个引脚：GPIO21；配置为输入；valid=0
--调用get(PIN38)时，如果为高电平，则返回false；如果为低电平，则返回true
PIN38 = {pin=pio.P1_4,dir=pio.INPUT,valid=0}

--如下三个配置含义和PIN31相似
--GPIO4
PIN39 = {pin=pio.P0_4}
--GPIO2
PIN40 = {pin=pio.P0_2}
--GPIO14
PIN46 = {pin=pio.P0_14}
--GPIO15
PIN47 = {pin=pio.P0_15}

local allpin = {PIN31,PIN32,PIN28,PIN27,PIN26,PIN25,PIN7,PIN38,PIN39,PIN40,PIN46,PIN47}

--[[
函数名：get
功能  ：读取输入或中断型引脚的电平状态
参数  ：  
        p： 引脚的名字
返回值：如果引脚的电平和引脚配置的valid的值一致，返回true；否则返回false
]]
function get(p)
	if p.get then return p.get(p) end
	return pio.pin.getval(p.pin) == p.valid
end

--[[
函数名：set
功能  ：设置输出型引脚的电平状态
参数  ：  
        bval：true表示和配置的valid值一样的电平状态，false表示相反状态
		p： 引脚的名字
返回值：无
]]
function set(bval,p)
	p.val = bval

	if not p.inited and (p.ptype == nil or p.ptype == "GPIO") then
		p.inited = true
		pio.pin.setdir(p.dir or pio.OUTPUT,p.pin)
	end

	if p.set then p.set(bval,p) return end

	if p.ptype ~= nil and p.ptype ~= "GPIO" then print("unknwon pin type:",p.ptype) return end

	local valid = p.valid == 0 and 0 or 1 -- 默认高有效
	local notvalid = p.valid == 0 and 1 or 0
	local val = bval == true and valid or notvalid

	if p.pin then pio.pin.setval(val,p.pin) end
end

--[[
函数名：setdir
功能  ：设置引脚的方向
参数  ：  
        dir：pio.OUTPUT、pio.OUTPUT1、pio.INPUT或者pio.INT，详细意义参考本文件上面的“dir值定义”
		p： 引脚的名字
返回值：无
]]
function setdir(dir,p)
	if p and p.ptype == nil or p.ptype == "GPIO" then
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

--[[
函数名：init
功能  ：初始化allpin表中的所有引脚
参数  ：无  
返回值：无
]]
function init()
	for _,v in ipairs(allpin) do
		if v.init == false then
			-- 不做初始化
		elseif v.ptype == nil or v.ptype == "GPIO" then
			v.inited = true
			pio.pin.setdir(v.dir or pio.OUTPUT,v.pin)
			if v.dir == nil or v.dir == pio.OUTPUT then
				set(v.defval or false,v)
			elseif v.dir == pio.INPUT or v.dir == pio.INT then
				v.val = pio.pin.getval(v.pin) == v.valid
			end
		elseif v.set then
			set(v.defval or false,v)
		end
	end
end

--[[
函数名：intmsg
功能  ：中断型引脚的中断处理程序，会抛出一个逻辑中断消息给其他模块使用
参数  ：  
        msg：table类型；msg.int_id：中断电平类型，cpu.INT_GPIO_POSEDGE表示高电平中断；msg.int_resnum：中断的引脚id
返回值：无
]]
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
--注册引脚中断的处理函数
sys.regmsg(rtos.MSG_INT,intmsg)
--初始化本模块配置的所有引脚
init()
