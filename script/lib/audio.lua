local base = _G
local string = require"string"
local io = require"io"
local rtos = require"rtos"
local audio = require"audiocore"
local sys = require"sys"
local ril = require"ril"
local os = require"os"
module("audio")

local smatch = string.match
local print = base.print
local dispatch = sys.dispatch
local req = ril.request
local tonumber,type = base.tonumber,base.type

local speakervol,audiochannel,microphonevol = audio.VOL4,audio.HANDSET,audio.MIC_VOL15
local gsmfr = false -- GSM全速率模式
local ttscause
local playname
local regrcd,recording

function setGSMFR()
	gsmfr = true
	req([[AT+SCFG="Call/SpeechVersion1",2]])
end

-- dtmf检测 参数: 使能,[灵敏度 默认2 最灵敏为1]
function dtmfdetect(enable,sens)
	if enable == true then
		if not gsmfr then setGSMFR() end

		if sens then
			req("AT+DTMFDET=2,1," .. sens)
		else
			req("AT+DTMFDET=2,1,3")
		end
	end

	req("AT+DTMFDET="..(enable and 1 or 0))
end

function senddtmf(str,playtime,intvl)
	if string.match(str,"([%dABCD%*#]+)") ~= str then
		print("senddtmf: illegal string "..str)
		return false
	end

	playtime = playtime and playtime or 100
	intvl = intvl and intvl or 100

	req("AT+SENDSOUND="..string.format("\"%s\",%d,%d",str,playtime,intvl))
end

-- text = "123" = 310032003300
-- path = "net" 发给网络  "speaker" 本地播放
function playtts(text,path)
	local action = path == "net" and 4 or 2

	req("AT+QTTS=1")
	req(string.format("AT+QTTS=%d,\"%s\"",action,text))
end

function stoptts()
	req("AT+QTTS=3")
end

function closetts(cause)
	ttscause = cause
	req("AT+QTTS=0")
end

-- 通话中发送声音到对端,必须是12.2K AMR格式
function transvoice(data,loop,loop2)
	local f = io.open("/RecDir/rec000","wb")

	if f == nil then
		print("transvoice:open file error")
		return false
	end

	-- 有文件头并且是12.2K帧
	if string.sub(data,1,7) == "#!AMR\010\060" then
	-- 无文件头且是12.2K帧
	elseif string.byte(data,1) == 0x3C then
		f:write("#!AMR\010")
	else
		print("transvoice:must be 12.2K AMR")
		return false
	end

	f:write(data)
	f:close()

	req(string.format("AT+AUDREC=%d,%d,2,0,50000",loop2 == true and 1 or 0,loop == true and 1 or 0))

	return true
end

function beginrecord(id,duration)
	if not regrcd then
		regrcd = true
		sys.regmsg(rtos.MSG_RECORD,recordmsg)
	end
	print("beginrecord",id,duration,recording)
	if recording then dispatch("AUDIO_RECORD_CNF",false) end
	if not recording then
		local file = (type(id)=="number" and ("/rcd"..id..".amr") or id)
		recording = (audio.record(file,duration) == 1)
		dispatch("AUDIO_RECORD_CNF",recording)
		--if duration then sys.timer_start(audio.stoprecord,duration*1000,file) end
	end
	return true
end

function endrecord(id,duration)
	recording = false
	sys.timer_stop(audio.stoprecord)
	audio.stoprecord(type(id)=="number" and ("/rcd"..id..".amr") or id)
	return true
end

function delrecord(id,duration)
	os.remove((type(id)=="number" and ("/rcd"..id..".amr") or id))
	return true
end

function playrecord(dl,loop,id,duration)
	play((type(id)=="number" and ("/rcd"..id..".amr") or id),loop)
	return true
end

function stoprecord(dl,loop,id,duration)
	stop()
	return true
end

function playamfgp(namepath,typ)
	req(string.format("AT+AMFGP=1,\"".. namepath .. "\"," .. (typ and typ or 1)))
	return true
end

function stopamfgp(namepath,typ)
	req(string.format("AT+AMFGP=0,\"".. namepath .. "\"," .. (typ and typ or 1)))
	return true
end

-- 音频播放接口
function play(name,loop)
	if loop then playname = name end
	return audio.play(name)
end

function stop()
	playname = nil
	return audio.stop()
end

local dtmfnum = {[71] = "Hz1000",[69] = "Hz1400",[70] = "Hz2300"}

local function parsedtmfnum(data)
	local n = base.tonumber(string.match(data,"(%d+)"))
	local dtmf

	if (n >= 48 and n <= 57) or (n >=65 and n <= 68) or n == 42 or n == 35 then
		dtmf = string.char(n)
	else
		dtmf = dtmfnum[n]
	end

	if dtmf then
		dispatch("AUDIO_DTMF_DETECT",dtmf)
	end
end

local function audiourc(data,prefix)
	if prefix == "+DTMFDET" then
		parsedtmfnum(data)	
	elseif prefix == "+QTTS" then
		local flag = string.match(data,": *(%d)",string.len(prefix)+1)
		if flag == "0" then
			dispatch("AUDIO_PLAY_END_IND")
		end
	elseif prefix == "+AMFGP" then
		local action = string.match(data,": *(%d)",string.len(prefix)+1)
		if action then
			if action == "0" then
				dispatch("AUDIO_PLAY_END_IND")
			elseif action == "1" then
				dispatch("AUDIO_PLAY_ERROR_IND")
			end
		end
	end
end

local function audiorsp(cmd,success,response,intermediate)
	local prefix = smatch(cmd,"AT(%+%u+%?*)")

	if prefix == "+QTTS" then
		local action = smatch(cmd,"QTTS=(%d)")
		if not success then
			if action == "1" or action == "2" then
				dispatch("AUDIO_PLAY_ERROR_IND")
			end
		else
			if action == "0" then
				dispatch("TTS_CLOSE_IND",ttscause)
			end
		end
	end
end

ril.regurc("+DTMFDET",audiourc)
ril.regurc("+AUDREC",audiourc)
ril.regurc("+AMFGP",audiourc)
ril.regurc("+QTTS",audiourc)
ril.regrsp("+AUDREC",audiorsp,0)
ril.regrsp("+QTTS",audiorsp,0)

function setspeakervol(vol)
	audio.setvol(vol)
	speakervol = vol
	dispatch("SPEAKER_VOLUME_SET_CNF",true)
end

function setcallvol(vol)
  print("setcallvol",vol)
  audio.setsphvol(vol)
  dispatch("CALL_VOLUME_SET_CNF",true)
end

function getspeakervol()
	return speakervol
end

function setaudiochannel(channel)
	audio.setchannel(channel)
	audiochannel = channel
	dispatch("AUDIO_CHANNEL_SET_CNF",true)
end

function getaudiochannel()
	return audiochannel
end

function setloopback(flag,typ,setvol,vol)
	return audio.setloopback(flag,typ,setvol,vol)
end

function setmicrophonegain(vol)
	audio.setmicvol(vol)
	microphonevol = vol
	dispatch("MICROPHONE_GAIN_SET_CNF",true)
end

function getmicrophonegain()
	return microphonevol
end

local function audiomsg(msg)
	if msg.play_end_ind == true then
		if playname then audio.play(playname) return end -- 循环播放时不派发该消息
		dispatch("AUDIO_PLAY_END_IND")
	elseif msg.play_error_ind == true then
		if playname then playname = nil end
		dispatch("AUDIO_PLAY_ERROR_IND")
	end
end

function recordmsg(msg)
	print("recordmsg",msg.record_end_ind,msg.record_error_ind)
	recording = false
	if msg.record_end_ind == true then
		dispatch("AUDIO_RECORD_IND",true)
	elseif msg.record_error_ind == true then
		dispatch("AUDIO_RECORD_IND",false)
	end
end

sys.regmsg(rtos.MSG_AUDIO,audiomsg)
