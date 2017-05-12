PROJECT = "XIAOMAN_WHOLE_TEST"
VERSION = "1.0.0"

require"sys"
require"chg"
require"pinscfg"
require"gsensor"
require"light"
require"gpsapp"
require"wdt"
wdt.open(pinscfg.RST_SCMWD,pinscfg.WATCHDOG)
require"keypad"
keypad.init_keypad(keypad.DEV_TRACKER)
require"sck"

sys.init(1,0)
sys.run()
