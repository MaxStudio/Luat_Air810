module(...,package.seeall)

--���������˿�Դģ�������п�����GPIO�����ţ�ÿ������ֻ����ʾ��Ҫ
--�û�����������Լ������������޸�

--pinֵ�������£�
--pio.P0_XX����ʾGPIOXX������pio.P0_15����ʾGPIO15
--pio.P1_XX����ʾGPOXX������pio.P1_8����ʾGPO8

--dirֵ�������£�Ĭ��ֵΪpio.OUTPUT����
--pio.OUTPUT����ʾ�������ʼ��������͵�ƽ
--pio.OUTPUT1����ʾ�������ʼ��������ߵ�ƽ
--pio.INPUT����ʾ���룬��Ҫ��ѯ����ĵ�ƽ״̬
--pio.INT����ʾ�жϣ���ƽ״̬�����仯ʱ���ϱ���Ϣ�����뱾ģ���intmsg����

--validֵ�������£�Ĭ��ֵΪ1����
--valid��ֵ����ģ���е�set��get�ӿ����ʹ��
--dirΪ���ʱ�����set�ӿ�ʹ�ã�set�ĵ�һ���������Ϊtrue��������validֵ��ʾ�ĵ�ƽ��0��ʾ�͵�ƽ��1��ʾ�ߵ�ƽ
--dirΪ������ж�ʱ�����get�ӿ�ʹ�ã�������ŵĵ�ƽ��valid��ֵһ�£�get�ӿڷ���true�����򷵻�false
--dirΪ�ж�ʱ����ϱ�ģ��intmsg�����е�sys.dispatch(string.format("PIN_%s_IND",v.name),v.val)ʹ�ã�������ŵĵ�ƽ��valid��ֵһ�£�v.valΪtrue������v.valΪfalse
--0
--1

--�ȼ���PIN31 = {pin=pio.P0_10,dir=pio.OUTPUT,valid=1}
--��31�����ţ�GPIO10������Ϊ�������ʼ������͵�ƽ��valid=1������set(true,PIN31),������ߵ�ƽ������set(false,PIN31),������͵�ƽ
PIN31 = {pin=pio.P0_10}

--��32�����ţ�GPIO11������Ϊ�������ʼ������ߵ�ƽ��valid=0������set(true,PIN32),������͵�ƽ������set(false,PIN32),������ߵ�ƽ
PIN32 = {pin=pio.P0_11,dir=pio.OUTPUT1,valid=0}

--�����������ú����PIN31����
--GPIO16
PIN28 = {pin=pio.P0_16}
--GPIO31
PIN27 = {pin=pio.P0_31}
--GPIO33
PIN26 = {pin=pio.P1_1}

--��25�����ţ�GPIO36������Ϊ�жϣ�valid=1
--�����ж�ʱ�����Ϊ�ߵ�ƽ����intmsg��sys.dispatch("PIN_PIN25_IND",true)�����Ϊ�͵�ƽ����intmsg��sys.dispatch("PIN_PIN25_IND",false)
--����get(PIN25)ʱ�����Ϊ�ߵ�ƽ���򷵻�true�����Ϊ�͵�ƽ���򷵻�false
PIN25 = {name="PIN25",pin=pio.P1_4,dir=pio.INT,valid=1}

--��PIN31����
--GPIO35
PIN7 = {pin=pio.P1_3}

--��38�����ţ�GPIO21������Ϊ���룻valid=0
--����get(PIN38)ʱ�����Ϊ�ߵ�ƽ���򷵻�false�����Ϊ�͵�ƽ���򷵻�true
PIN38 = {pin=pio.P1_4,dir=pio.INPUT,valid=0}

--�����������ú����PIN31����
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
��������get
����  ����ȡ������ж������ŵĵ�ƽ״̬
����  ��  
        p�� ���ŵ�����
����ֵ��������ŵĵ�ƽ���������õ�valid��ֵһ�£�����true�����򷵻�false
]]
function get(p)
	if p.get then return p.get(p) end
	return pio.pin.getval(p.pin) == p.valid
end

--[[
��������set
����  ��������������ŵĵ�ƽ״̬
����  ��  
        bval��true��ʾ�����õ�validֵһ���ĵ�ƽ״̬��false��ʾ�෴״̬
		p�� ���ŵ�����
����ֵ����
]]
function set(bval,p)
	p.val = bval

	if not p.inited and (p.ptype == nil or p.ptype == "GPIO") then
		p.inited = true
		pio.pin.setdir(p.dir or pio.OUTPUT,p.pin)
	end

	if p.set then p.set(bval,p) return end

	if p.ptype ~= nil and p.ptype ~= "GPIO" then print("unknwon pin type:",p.ptype) return end

	local valid = p.valid == 0 and 0 or 1 -- Ĭ�ϸ���Ч
	local notvalid = p.valid == 0 and 1 or 0
	local val = bval == true and valid or notvalid

	if p.pin then pio.pin.setval(val,p.pin) end
end

--[[
��������setdir
����  ���������ŵķ���
����  ��  
        dir��pio.OUTPUT��pio.OUTPUT1��pio.INPUT����pio.INT����ϸ����ο����ļ�����ġ�dirֵ���塱
		p�� ���ŵ�����
����ֵ����
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
��������init
����  ����ʼ��allpin���е���������
����  ����  
����ֵ����
]]
function init()
	for _,v in ipairs(allpin) do
		if v.init == false then
			-- ������ʼ��
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
��������intmsg
����  ���ж������ŵ��жϴ�����򣬻��׳�һ���߼��ж���Ϣ������ģ��ʹ��
����  ��  
        msg��table���ͣ�msg.int_id���жϵ�ƽ���ͣ�cpu.INT_GPIO_POSEDGE��ʾ�ߵ�ƽ�жϣ�msg.int_resnum���жϵ�����id
����ֵ����
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
--ע�������жϵĴ�����
sys.regmsg(rtos.MSG_INT,intmsg)
--��ʼ����ģ�����õ���������
init()
