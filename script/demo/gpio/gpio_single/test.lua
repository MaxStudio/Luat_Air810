require"pincfg"
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

-------------------------PIN31���Կ�ʼ-------------------------
local pin31flg = true
--[[
��������pin31set
����  ������PIN31���ŵ������ƽ��1�뷴תһ��
����  ����
����ֵ����
]]
local function pin31set()
	pins.set(pin31flg,pincfg.PIN31)
	pin31flg = not pin31flg
end
--����1���ѭ����ʱ��������PIN31���ŵ������ƽ
sys.timer_loop_start(pin31set,1000)
-------------------------PIN31���Խ���-------------------------


-------------------------PIN32���Կ�ʼ-------------------------
local pin32flg = true
--[[
��������pin32set
����  ������PIN32���ŵ������ƽ��1�뷴תһ��
����  ����
����ֵ����
]]
local function pin32set()
	pins.set(pin32flg,pincfg.PIN32)
	pin32flg = not pin32flg
end
--����1���ѭ����ʱ��������PIN32���ŵ������ƽ
sys.timer_loop_start(pin32set,1000)
-------------------------PIN32���Խ���-------------------------


-------------------------PIN28���Կ�ʼ-------------------------
--[[
��������pin28get
����  ����ȡPIN28���ŵ������ƽ
����  ����
����ֵ����
]]
local function pin28get()
	local v = pins.get(pincfg.PIN28)
	print("pin28get",v and "low" or "high")
end
--����1���ѭ����ʱ������ȡPIN28���ŵ������ƽ
sys.timer_loop_start(pin28get,1000)
-------------------------PIN28���Խ���-------------------------
