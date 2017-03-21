module(...,package.seeall)

require"pm"

--[[
ע��: ������ģ��ֻ�����ڼ򵥵���֤AT���ܣ�AT�ֲ����������AT���������ȫ����֧��.

����ID,2��Ӧuart2,���Ҫ�޸�Ϊuart1����UART_ID��ֵΪ1����
]]

local UART_ID = 1

--[[
��������print
����  ����ӡ�ӿڣ����ļ��е����д�ӡ�������mcuartǰ׺
����  ����
����ֵ����
]]
local function print(...)
	_G.print("uartat",...)
end

--[[
��������read
����  ����ȡ���ڽ��յ�������
����  ����
����ֵ����
]]
local function read()
	local data = ""
	--�ײ�core�У������յ�����ʱ��
	--������ջ�����Ϊ�գ�������жϷ�ʽ֪ͨLua�ű��յ��������ݣ�
	--������ջ�������Ϊ�գ��򲻻�֪ͨLua�ű�
	--����Lua�ű����յ��ж϶���������ʱ��ÿ�ζ�Ҫ�ѽ��ջ������е�����ȫ���������������ܱ�֤�ײ�core�е��������ж���������read�����е�while����оͱ�֤����һ��
	while true do
		data = uart.read(UART_ID,"*l",0)
		if not data or string.len(data) == 0 then break end
		--������Ĵ�ӡ���ʱ
		print("read",data)
		ril.sendtransparentdata(data)
	end
end

--[[
��������write
����  ��ͨ�����ڷ�������
����  ��
		s��Ҫ���͵�����
����ֵ����
]]
function write(s)
	uart.write(UART_ID,s)	
end

--����ϵͳ���ڻ���״̬����������
pm.wake("uartat")
--ע�ᴮ�ڵ����ݽ��պ����������յ����ݺ󣬻����жϷ�ʽ������read�ӿڶ�ȡ����
sys.reguart(UART_ID,read)
--���ò��Ҵ򿪴���
uart.setup(UART_ID,115200,8,uart.PAR_NONE,uart.STOP_1,2)


