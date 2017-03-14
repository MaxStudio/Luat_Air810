module(...,package.seeall)

--[[
��������print
����  ����ӡ�ӿڣ����ļ��е����д�ӡ�������testǰ׺
����  ����
����ֵ����
]]
local function print(...)
	_G.print("test",...)
end

--[[
i2cid: �ڼ���i2c
i2cuse: ���ŵ�ǰ�Ƿ���Ϊi2c����ʹ�ã�true��ʾ�ǣ�����ı�ʾ����
sAddr: ʵ��ʹ��ʱ����Χ�豸������0x15ֻ��һ������
]]
local i2cid,i2cuse,sAddr = 1,true,0x15
local I2C_SCL,I2C_SDA = pio.P1_11,pio.P1_12
--[[
��������i2copn
����  ����i2c
����  ����
����ֵ����
]]
local function i2copn()
	if i2c.setup(i2cid,i2c.SLOW,sAddr) ~= i2c.SLOW then
		print("i2c opn fail")
	end
end

--[[
��������i2close
����  ���ر�i2c
����  ����
����ֵ����
]]
local function i2close()
	i2c.close(i2cid)
end

--[[
��������switchtoi2c
����  ���л���i2c����ʹ��
����  ����
����ֵ����
]]
local function switchtoi2c()
	print("switchtoi2c",i2cuse)
	if not i2cuse then
		--�ر�gpio����
		pio.pin.close(I2C_SCL)
		pio.pin.close(I2C_SDA)
		--��i2c����
		i2copn()
		i2cuse = true
	end
end

--[[
��������switchtogpio
����  ���л���gpio����ʹ��
����  ����
����ֵ����
]]
local function switchtogpio()
	print("switchtogpio",i2cuse)
	if i2cuse then
		--�ر�i2c����
		i2close()
		--����gpio����
		pio.pin.setdir(pio.OUTPUT,I2C_SCL)
		pio.pin.setdir(pio.OUTPUT,I2C_SDA)
		--���gpio��ƽ
		pio.pin.setval(1,I2C_SCL)
		pio.pin.setval(0,I2C_SDA)
		i2cuse = false
	end	
end

--[[
��������switch
����  ���л�i2c��gpio����
����  ����
����ֵ����
]]
local function switch()
	if i2cuse then
		switchtogpio()
	else
		switchtoi2c()
	end
end

i2copn()
--ѭ����ʱ����5���л�һ�ι���
sys.timer_loop_start(switch,5000)
