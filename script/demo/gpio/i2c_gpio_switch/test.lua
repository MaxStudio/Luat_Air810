module(...,package.seeall)

--[[
函数名：print
功能  ：打印接口，此文件中的所有打印都会加上test前缀
参数  ：无
返回值：无
]]
local function print(...)
	_G.print("test",...)
end

--[[
i2cid: 第几组i2c
i2cuse: 引脚当前是否做为i2c功能使用，true表示是，其余的表示不是
sAddr: 实际使用时由外围设备决定，0x15只是一个例子
]]
local i2cid,i2cuse,sAddr = 1,true,0x15
local I2C_SCL,I2C_SDA = pio.P1_11,pio.P1_12
--[[
函数名：i2copn
功能  ：打开i2c
参数  ：无
返回值：无
]]
local function i2copn()
	if i2c.setup(i2cid,i2c.SLOW,sAddr) ~= i2c.SLOW then
		print("i2c opn fail")
	end
end

--[[
函数名：i2close
功能  ：关闭i2c
参数  ：无
返回值：无
]]
local function i2close()
	i2c.close(i2cid)
end

--[[
函数名：switchtoi2c
功能  ：切换到i2c功能使用
参数  ：无
返回值：无
]]
local function switchtoi2c()
	print("switchtoi2c",i2cuse)
	if not i2cuse then
		--关闭gpio功能
		pio.pin.close(I2C_SCL)
		pio.pin.close(I2C_SDA)
		--打开i2c功能
		i2copn()
		i2cuse = true
	end
end

--[[
函数名：switchtogpio
功能  ：切换到gpio功能使用
参数  ：无
返回值：无
]]
local function switchtogpio()
	print("switchtogpio",i2cuse)
	if i2cuse then
		--关闭i2c功能
		i2close()
		--配置gpio方向
		pio.pin.setdir(pio.OUTPUT,I2C_SCL)
		pio.pin.setdir(pio.OUTPUT,I2C_SDA)
		--输出gpio电平
		pio.pin.setval(1,I2C_SCL)
		pio.pin.setval(0,I2C_SDA)
		i2cuse = false
	end	
end

--[[
函数名：switch
功能  ：切换i2c和gpio功能
参数  ：无
返回值：无
]]
local function switch()
	if i2cuse then
		switchtogpio()
	else
		switchtoi2c()
	end
end

i2copn()
--循环定时器，5秒切换一次功能
sys.timer_loop_start(switch,5000)
