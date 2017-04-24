PROJECT = "default demo"
VERSION = "1.0.0"

require"sys"
--UART1 as trace's port, it must follow 'sys'.
sys.opntrace(1,1)
--加载硬件看门狗功能模块
require"wdt"
require"linkair"

sys.init(0,0)
sys.run()
