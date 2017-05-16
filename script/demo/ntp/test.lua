module(...,package.seeall)
require"misc"

local function printime()
	print("printime clock:",misc.getclockstr())
end

sys.timer_loop_start(printime,1000)
