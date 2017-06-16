--[[
ģ�����ƣ�ͨ������
ģ�鹦�ܣ����Ժ������
ģ������޸�ʱ�䣺2017.02.23
]]

module(...,package.seeall)
require"cc"
require"audio"

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
	--50��֮����������ͨ��
	sys.timer_start(cc.hangup,50000,"AUTO_DISCONNECT")
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
����  ��
		e������ע��״̬�仯��Ϣ��"NET_STATE_CHANGED" 
		s������ע��״̬��"REGISTERED"Ϊ��ע��
����ֵ����
]]
local function ready(e,s)
	print("ready",e,s)
	if s=="REGISTERED" then
		--����10086
		cc.dial("10086")
	end
	return true
end

--ע����Ϣ���û��ص�����
cc.regcb("INCOMING",incoming,"CONNECTED",connected,"DISCONNECTED",disconnected)
sys.regapp(ready,"NET_STATE_CHANGED")
