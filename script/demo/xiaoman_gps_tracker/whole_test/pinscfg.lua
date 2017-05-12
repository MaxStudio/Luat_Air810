module(...,package.seeall)

require"pins"

GSENSOR = {name="GSENSOR",pin=pio.P1_4,dir=pio.INT,valid=0}
WATCHDOG = {pin=pio.P0_31,dir=pio.INPUT,valid=1}
RST_SCMWD = {pin=pio.P0_20,defval=true,valid=1}
LIGHTB = {pin=pio.P0_25}

pins.reg(GSENSOR,WATCHDOG,RST_SCMWD,LIGHTB)
