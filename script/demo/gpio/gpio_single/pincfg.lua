module(...,package.seeall)

require"pins"

--���������˿�Դģ�������п�����GPIO�����ţ�ÿ������ֻ����ʾ��Ҫ
--�û�����������Լ������������޸�

--pinֵ�������£�
--pio.P0_XX����ʾGPIOXX������pio.P0_15����ʾGPIO15
--pio.P1_XX����ʾGPIOXX������pio.P1_8����ʾGPIO40

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
--��31�����ţ�GPIO54������Ϊ�������ʼ������͵�ƽ��valid=1������set(true,PIN31),������ߵ�ƽ������set(false,PIN31),������͵�ƽ
PIN31 = {pin=pio.P1_22}

--��32�����ţ�GPIO55������Ϊ�������ʼ������ߵ�ƽ��valid=0������set(true,PIN32),������͵�ƽ������set(false,PIN32),������ߵ�ƽ
PIN32 = {pin=pio.P1_23,dir=pio.OUTPUT1,valid=0}

--�����������ú����PIN31����
--GPIO16
PIN28 = {pin=pio.P0_16}
--GPIO31
PIN27 = {pin=pio.P0_31}
--GPIO33
PIN26 = {pin=pio.P1_1}

local function pin25cb(v)
	print("pin25cb",v)
end
--��25�����ţ�GPIO36������Ϊ�жϣ�valid=1
--intcb��ʾ�жϹܽŵ��жϴ������������ж�ʱ�����Ϊ�ߵ�ƽ����ص�intcb(true)�����Ϊ�͵�ƽ����ص�intcb(false)
--����get(PIN25)ʱ�����Ϊ�ߵ�ƽ���򷵻�true�����Ϊ�͵�ƽ���򷵻�false
PIN25 = {name="PIN25",pin=pio.P1_4,dir=pio.INT,valid=1,intcb=pin25cb}

--��PIN31����
--GPIO35,������Ϊ�ж�
PIN7 = {pin=pio.P1_3}

--��38�����ţ�GPIO21������Ϊ���룻valid=0
--����get(PIN38)ʱ�����Ϊ�ߵ�ƽ���򷵻�false�����Ϊ�͵�ƽ���򷵻�true
PIN38 = {pin=pio.P0_21,dir=pio.INPUT,valid=0}

--�����������ú����PIN31����
--GPIO4,������Ϊ�ж�
PIN39 = {pin=pio.P0_4}
--GPIO2,������Ϊ�ж�
PIN40 = {pin=pio.P0_2}
--GPIO14,������Ϊ�ж�
PIN46 = {pin=pio.P0_14}
--GPIO15
PIN47 = {pin=pio.P0_15}

pins.reg(PIN31,PIN32,PIN28,PIN27,PIN26,PIN25,PIN7)

