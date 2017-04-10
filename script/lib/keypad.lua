module(...,package.seeall)

local curkey
local PWROFF_KEY_LONG_PRESS_TIME = 3000
local keymap = {["255255"] = "K_RED"}
local sta,keyname = "IDLE"

local function print(...)
	_G.print("keypad",...)
end

local function pwoff()
	print("pwoff")
	sys.poweroff()
end

local function repwron()
  print("repwron")
  sys.setPwrFlag(true)
  sys.repwron()
  sys.dispatch("PWRKEY_IND",sys.getPwrFlag())
end

local function keylongpresstimerfun()
	print("keylongpresstimerfun curkey",curkey,keyname,sys.isPwronCharger())
  if keyname == "K_RED" then
		if sys.isPwronCharger() then
		  repwron()
		else
      sys.timer_start(pwoff,1000)
		end
	end
	sta = "LONG"
end

local function stopkeylongpress()
	curkey = nil
	sys.timer_stop(keylongpresstimerfun)
end

local function startkeylongpress(key)
	print("startkeylongpress",curkey,key,keyname)
	stopkeylongpress()
	curkey = key
	
	sys.timer_start(keylongpresstimerfun,PWROFF_KEY_LONG_PRESS_TIME)
end

local function keymsg(msg)
	print("keypad.keymsg",msg.key_matrix_row,msg.key_matrix_col)
	local key = keymap[msg.key_matrix_row..msg.key_matrix_col]
	print("keymsg key",key,msg.pressed,keyname)
	if key then
		if msg.pressed then
			sta = "PRESSED"
			if not keyname then
				keyname = key
			end
			startkeylongpress(key)			
		else
			stopkeylongpress()
			sta = "IDLE"
			keyname = nil
		end
	end
end

sys.regmsg(rtos.MSG_KEYPAD,keymsg)
rtos.init_module(rtos.MOD_KEYPAD,0,0,0)
