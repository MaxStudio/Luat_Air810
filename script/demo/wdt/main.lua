PROJECT = "wdt demo"
VERSION = "1.0.0"
require"sys"
require"pins"
--加载硬件看门狗功能模块
require"wdt"
wdt.open({pin=pio.P0_16,dir=pio.INPUT,valid=1},{pin=pio.P0_20,defval=true,valid=1})

sys.init(0,0)
sys.run()
