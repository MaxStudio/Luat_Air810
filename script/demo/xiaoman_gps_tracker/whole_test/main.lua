--���������λ�ö���PROJECT��VERSION����
--PROJECT��ascii string���ͣ�������㶨�壬ֻҪ��ʹ��,����
--VERSION��ascii string���ͣ����ʹ��Luat������ƽ̨�̼������Ĺ��ܣ����밴��"X.X.X"���壬X��ʾ1λ���֣��������㶨��
PROJECT = "XIAOMAN_WHOLE_TEST"
VERSION = "1.0.1"

require"sys"
--[[
���ʹ��UART���trace��������ע�͵Ĵ���"--sys.opntrace(true,1)"���ɣ���2������1��ʾUART1���trace�������Լ�����Ҫ�޸��������
�����������������trace�ڵĵط�������д��������Ա�֤UART�ھ����ܵ�����������ͳ��ֵĴ�����Ϣ��
���д�ں��������λ�ã����п����޷����������Ϣ���Ӷ����ӵ����Ѷ�
]]
--sys.opntrace(true,1)
require"chg"
require"pinscfg"
require"gsensor"
require"light"
require"gpsapp"
require"wdt"
wdt.setup(pio.P0_20,pio.P0_31)
require"keypad"
keypad.init_keypad(keypad.DEV_TRACKER)
require"sck"

sys.init(1,0)
sys.run()
