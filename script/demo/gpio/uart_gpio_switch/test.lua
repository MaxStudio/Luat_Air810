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

--uartuse�����ŵ�ǰ�Ƿ���Ϊuart����ʹ�ã�true��ʾ�ǣ�����ı�ʾ����
local uartid,uartuse = 3,true
local UART_RXD,UART_TXD = pio.P0_0,pio.P0_1
--[[
��������uartopn
����  ����uart
����  ����
����ֵ����
]]
local function uartopn()
	uart.setup(uartid,115200,8,uart.PAR_NONE,uart.STOP_1,2)	
end

--[[
��������uartclose
����  ���ر�uart
����  ����
����ֵ����
]]
local function uartclose()
	uart.close(uartid)
end

--[[
��������switchtouart
����  ���л���uart����ʹ��
����  ����
����ֵ����
]]
local function switchtouart()
	print("switchtouart",uartuse)
	if not uartuse then
		--�ر�gpio����
		pio.pin.close(UART_RXD)
		pio.pin.close(UART_TXD)
		--��uart����
		uartopn()
		uartuse = true
	end
end

--[[
��������switchtogpio
����  ���л���gpio����ʹ��
����  ����
����ֵ����
]]
local function switchtogpio()
	print("switchtogpio",uartuse)
	if uartuse then
		--�ر�uart����
		uartclose()
		--����gpio����
		pio.pin.setdir(pio.OUTPUT,UART_RXD)
		pio.pin.setdir(pio.OUTPUT,UART_TXD)
		--���gpio��ƽ
		pio.pin.setval(1,UART_RXD)
		pio.pin.setval(0,UART_TXD)
		uartuse = false
	end	
end

--[[
��������switch
����  ���л�uart��gpio����
����  ����
����ֵ����
]]
local function switch()
	if uartuse then
		switchtogpio()
	else
		switchtouart()
	end
end

uartopn()
--ѭ����ʱ����5���л�һ�ι���
sys.timer_loop_start(switch,5000)
