module(...,package.seeall)
--[[
ģ�����ƣ�ͨ������
ģ�鹦�ܣ����Ժ������
ģ������޸�ʱ�䣺2017.02.23
]]

require"audio"
require"cc"

--Ĭ�Ϻ��еĵ绰����
local phone_number = "10086"

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
��������connected
����  ����ͨ���ѽ�������Ϣ������
����  ����
����ֵ����
]]
local function connected()
	print("connected")
	--����mic����
	audio.setmicrophonegain(7)
	--10����֮����������ͨ��
	sys.timer_start(cc.hangup,10000,"AUTO_DISCONNECT")
end

--[[
��������disconnected
����  ����ͨ���ѽ�������Ϣ������
����  ��
		para��ͨ������ԭ��ֵ
			  "LOCAL_HANG_UP"���û���������cc.hangup�ӿڹҶ�ͨ��
			  "CALL_FAILED"���û�����cc.dial�ӿں�����at����ִ��ʧ��
			  "NO CARRIER"��������Ӧ��
			  "BUSY"��ռ��
			  "NO ANSWER"��������Ӧ��
����ֵ����
]]
local function disconnected(para)
	print("disconnected:"..(para or "nil"))
	sys.timer_stop(cc.hangup,"AUTO_DISCONNECT")
end

--[[
��������incoming
����  �������硱��Ϣ������
����  ��
		num��string���ͣ��������
����ֵ����
]]
local function incoming(num)
	print("incoming:"..num)
	--��������
	cc.accept()
end

--[[
��������ready
����  ����ͨ������ģ��׼����������Ϣ������
����  ����
����ֵ����
]]
local function ready()
	print("ready")
	--����phone_number
	cc.dial(phone_number)
end

--ע����Ϣ���û��ص�����
cc.regcb("READY",ready,"INCOMING",incoming,"CONNECTED",connected,"DISCONNECTED",disconnected)
