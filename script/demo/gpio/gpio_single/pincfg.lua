require"pins"
module(...,package.seeall)

--���������˿�Դģ�������п�����GPIO�����ţ�ÿ������ֻ����ʾ��Ҫ
--�û�����������Լ������������޸�

--pinֵ�������£�
--pio.P0_XX����ʾGPIOXX������pio.P0_15����ʾGPIO15
--pio.P1_XX����ʾGPIO(XX+32)������pio.P1_8����ʾGPIO40

--dirֵ�������£�Ĭ��ֵΪpio.OUTPUT����
--pio.OUTPUT����ʾ�������ʼ��������͵�ƽ
--pio.OUTPUT1����ʾ�������ʼ��������ߵ�ƽ
--pio.INPUT����ʾ���룬��Ҫ��ѯ����ĵ�ƽ״̬
--pio.INT����ʾ�жϣ���ƽ״̬�����仯ʱ���ϱ���Ϣ�����뱾ģ���intmsg����

--validֵ�������£�Ĭ��ֵΪ1����
--valid��ֵ��pins.lua�е�set��get�ӿ����ʹ��
--dirΪ���ʱ�����pins.set�ӿ�ʹ�ã�pins.set�ĵ�һ���������Ϊtrue��������validֵ��ʾ�ĵ�ƽ��0��ʾ�͵�ƽ��1��ʾ�ߵ�ƽ
--dirΪ������ж�ʱ�����get�ӿ�ʹ�ã�������ŵĵ�ƽ��valid��ֵһ�£�get�ӿڷ���true�����򷵻�false
--dirΪ�ж�ʱ��cbΪ�ж����ŵĻص����������жϲ���ʱ�����������cb�������cb����������жϵĵ�ƽ��valid��ֵ��ͬ����cb(true)������cb(false)

--�ȼ���PIN31 = {pin=pio.P0_10,dir=pio.OUTPUT,valid=1}
--��31�����ţ�GPIO54������Ϊ�������ʼ������͵�ƽ��valid=1������pins.set(true,PIN31),������ߵ�ƽ������pins.set(false,PIN31),������͵�ƽ
PIN31 = {pin=pio.P1_22}

--��32�����ţ�GPIO55������Ϊ�������ʼ������ߵ�ƽ��valid=0������pins.set(true,PIN32),������͵�ƽ������pins.set(false,PIN32),������ߵ�ƽ
PIN32 = {pin=pio.P1_23,dir=pio.OUTPUT1,valid=0}

--�����������ú����PIN31����
PIN28 = {pin=pio.P0_16}
PIN27 = {pin=pio.P0_31}
PIN26 = {pin=pio.P1_1}


local function pin25cb(v)
	print("pin25cb",v)
end
--��25�����ţ�GPIO36������Ϊ�жϣ�valid=1
--intcb��ʾ�жϹܽŵ��жϴ������������ж�ʱ�����Ϊ�ߵ�ƽ����ص�intcb(true)�����Ϊ�͵�ƽ����ص�intcb(false)
--����get(PIN25)ʱ�����Ϊ�ߵ�ƽ���򷵻�true�����Ϊ�͵�ƽ���򷵻�false
PIN25 = {name="PIN25",pin=pio.P1_4,dir=pio.INT,valid=1,intcb=pin25cb}

--��38�����ţ�GPIO21������Ϊ���룻valid=0
--����get(PIN38)ʱ�����Ϊ�ߵ�ƽ���򷵻�false�����Ϊ�͵�ƽ���򷵻�true
PIN38 = {pin=pio.P0_21,dir=pio.INPUT,valid=0}

--�����������ú����PIN31����
PIN39 = {pin=pio.P0_4}
PIN40 = {pin=pio.P0_2}
PIN46 = {pin=pio.P0_14}
PIN47 = {pin=pio.P0_15}

pins.reg(PIN31,PIN32,PIN28,PIN27,PIN26,PIN25,PIN38,PIN39,PIN40,PIN46,PIN47)

