PROJECT = "wdt demo"
VERSION = "1.0.0"
require"sys"
--����Ӳ�����Ź�����ģ��
require"wdt"

sys.init(0,0)
--UART1 as trace's port.
sys.opntrace(1,1)
sys.run()
