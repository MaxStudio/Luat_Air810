PROJECT = "uart_at_transparent_wdt demo"
VERSION = "1.0.0"

require"sys"
require"ril"
require"net"
--����������ָʾ��һֱ��˸����100���룬��2900����
net.setled(true,nil,nil,nil,nil,100,2900)
require"uartat"
require"wdt"

--��������ATC���ڹ���ģʽΪ͸��ģʽ
--����ATC�����յ����ݣ���ֱ�ӵ���uartat.write�ӿ�
--uartat.write�ӿڣ��������ATC�����յ�������ͨ������uartת��������
ril.setransparentmode(uartat.write)
sys.init(0,0)
sys.run()
