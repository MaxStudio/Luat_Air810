module(...,package.seeall)

require"misc"

--��Ҫд���豸����imei��,15-digits
local newimei = "123456789012347"

--5���ʼдimei
sys.timer_start(misc.setimei,5000,newimei)
