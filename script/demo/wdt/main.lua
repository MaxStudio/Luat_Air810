PROJECT = "wdt demo"
VERSION = "1.0.0"
require"sys"
--加载硬件看门狗功能模块
require"wdt"

sys.init(0,0)
--UART1 as trace's port.
sys.opntrace(1,1)
sys.run()
