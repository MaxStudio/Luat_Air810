module(...,package.seeall)

--[[
ģ�����ƣ���GPSӦ�á�����
ģ�鹦�ܣ�����gps.lua�Ľӿ�
ģ������޸�ʱ�䣺2017.02.16
]]

require"gps"
require"agps"


--[[
��������print
����  ����ӡ�ӿڣ����ļ��е����д�ӡ�������gpsappǰ׺
����  ����
����ֵ����
]]
local function print(...)
	_G.print("testgps",...)
end

--[[
�ж��Ƿ�λ�ɹ�  gps.isfix()
��ȡ��γ����Ϣ      gps.getgpslocation()
]]

local function test1cb(cause)
	print("test1cb",cause,gps.isfix())
	print("test1cb",cause,gps.isfix(),gps.getgpslocation())
end

local function test2cb(cause)
	print("test2cb",cause,gps.isfix())
	print("test2cb",cause,gps.isfix(),gps.getgpslocation())
end

local function test3cb(cause)
	print("test3cb",cause,gps.isfix())
	print("test3cb",cause,gps.isfix(),gps.getgpslocation())
end

--���Դ��뿪�أ�ȡֵ1,2
local testidx = 1

local function gps_open(typ)
  --��1�ֲ��Դ���
  if typ==1 then
  	--ִ�����������д����GPS�ͻ�һֱ��������Զ����ر�
  	--��Ϊgps.open(gps.DEFAULT,{cause="TEST1",cb=test1cb})�����������û�е���gps.close�ر�
  	gps.open(gps.DEFAULT,{cause="TEST1",cb=test1cb})
  	
  	--10���ڣ����gps��λ�ɹ�������������test2cb��Ȼ���Զ��ر������GPSӦ�á�
  	--10��ʱ�䵽��û�ж�λ�ɹ�������������test2cb��Ȼ���Զ��ر������GPSӦ�á�
  	gps.open(gps.TIMERORSUC,{cause="TEST2",val=10,cb=test2cb})
  	
  	--300��ʱ�䵽������������test3cb��Ȼ���Զ��ر������GPSӦ�á�
  	gps.open(gps.TIMER,{cause="TEST3",val=300,cb=test3cb})
  --��2�ֲ��Դ���
  elseif typ==2 then
  	gps.open(gps.DEFAULT,{cause="TEST1",cb=test1cb})
  	sys.timer_start(gps.close,30000,gps.DEFAULT,{cause="TEST1"})
  	gps.open(gps.TIMERORSUC,{cause="TEST2",val=10,cb=test2cb})
  	gps.open(gps.TIMER,{cause="TEST3",val=60,cb=test3cb})	
  end
end

gps.init()
sys.timer_start(gps_open, 10000, testidx)
