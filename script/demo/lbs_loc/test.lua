module(...,package.seeall)
require"lbsloc"

--�Ƿ��ѯGPSλ���ַ�����Ϣ
local qrylocation

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
��������qrygps
����  ����ѯGPSλ������
����  ����
����ֵ����
]]
local function qrygps()
	qrylocation = not qrylocation
	lbsloc.request(getgps,qrylocation)
end

--[[
��������getgps
����  ����ȡ��γ�Ⱥ�Ļص�����
����  ��
		result��number���ͣ���ȡ�����0��ʾ�ɹ��������ʾʧ�ܡ��˽��Ϊ0ʱ�����3��������������
		lat��string���ͣ�γ�ȣ���������3λ������031.2425864
		lng��string���ͣ����ȣ���������3λ������121.4736522
		location��string���ͣ�GB2312�����λ���ַ���������lbsloc.request��ѯ��γ�ȣ�����ĵڶ�������Ϊtrueʱ���ŷ��ر�����
����ֵ����
]]
function getgps(result,lat,lng,location)
	print("getgps",result,lat,lng,location)
	--��ȡ��γ�ȳɹ�
	if result==0 then
	--ʧ��
	else
	end
	sys.timer_start(qrygps,20000)
end

--20���ȥ��ѯ��γ�ȣ���ѯ���ͨ���ص�����getgps����
sys.timer_start(qrygps,20000)
