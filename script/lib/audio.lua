module("audio")
--[[
模块名称：音频控制
模块功能：dtmf编解码、音频文件的播放和停止、录音、mic和speaker的控制
模块最后修改时间：2017.02.20
]]

--定义模块,导入依赖库
local base = _G
local string = require"string"
local io = require"io"
local rtos = require"rtos"
local audio = require"audiocore"
local sys = require"sys"
local ril = require"ril"
local os = require"os"

--加载常用的全局函数至本地
local smatch = string.match
local print = base.print
local dispatch = sys.dispatch
local req = ril.request
local tonumber,type = base.tonumber,base.type

--[[
speakervol：speaker音量等级，取值范围为audio.VOL0到audio.VOL7，audio.VOL0为静音
audiochannel：音频通道，跟硬件设计有关，用户程序需要根据硬件配置
microphonevol：mic音量等级，取值范围为audio.MIC_VOL0到audio.MIC_VOL15，audio.MIC_VOL0为静音
]]
local speakervol,audiochannel,microphonevol = audio.VOL4,audio.HANDSET,audio.MIC_VOL15
-- GSM全速率模式
local gsmfr = false 
--音频文件路径
local playname
--录音标志
local regrcd,recording

--[[
函数名：setGSMFR
功能  ：设置GSM全速率（目前功能无效）
参数  ：无		
返回值：无
]]
function setGSMFR()
	gsmfr = true
	req([[AT+SCFG="Call/SpeechVersion1",2]])
end

--[[
函数名：dtmfdetect
功能  ：设置dtmf检测是否使能以及灵敏度
参数  ：
		enable：true使能，false或者nil为不使能
		sens：灵敏度，默认3，最灵敏为1
返回值：无
]]
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

--[[
函数名：senddtmf
功能  ：发送dtmf到对端
参数  ：
		str：dtmf字符串
		playtime：每个dtmf播放时间，单位毫秒，默认100
		intvl：两个dtmf间隔，单位毫秒，默认100
返回值：无
]]
function senddtmf(str,playtime,intvl)
	if string.match(str,"([%dABCD%*#]+)") ~= str then
		print("senddtmf: illegal string "..str)
		return false
	end

	playtime = playtime and playtime or 100
	intvl = intvl and intvl or 100

	req("AT+SENDSOUND="..string.format("\"%s\",%d,%d",str,playtime,intvl))
end

--[[
函数名：transvoice
功能  ：通话中发送声音到对端,必须是12.2K AMR格式
参数  ：
返回值：true为成功，false为失败
]]
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

--[[
函数名：beginrecord
功能  ：开始录音
参数  ：
		id：录音id，会根据这个id存储录音文件，取值范围0-4
		duration：录音时长，单位毫秒
返回值：true
]]
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
		--if duration then sys.timer_start(audio.stoprecord,duration*1000,file) end
	end
	return true
end

--[[
函数名：endrecord
功能  ：结束录音
参数  ：
		id：录音id，会根据这个id存储录音文件，取值范围0-4
		duration：录音时长，单位毫秒
返回值：true
]]
function endrecord(id,duration)
	recording = false
	sys.timer_stop(audio.stoprecord)
	audio.stoprecord(type(id)=="number" and ("/rcd"..id..".amr") or id)
	return true
end

--[[
函数名：delrecord
功能  ：删除录音文件
参数  ：
		id：录音id，会根据这个id存储录音文件，取值范围0-4
		duration：录音时长，单位毫秒
返回值：true
]]
function delrecord(id,duration)
	os.remove((type(id)=="number" and ("/rcd"..id..".amr") or id))
	return true
end

--[[
函数名：playrecord
功能  ：播放录音文件
参数  ：
		dl：模块下行（耳机或手柄或喇叭）是否可以听到录音播放的声音，true可以听到，false或者nil听不到
		loop：是否循环播放，true为循环，false或者nil为不循环
		id：录音id，会根据这个id存储录音文件，取值范围0-4
		duration：录音时长，单位毫秒
返回值：true
]]
function playrecord(dl,loop,id,duration)
	play((type(id)=="number" and ("/rcd"..id..".amr") or id),loop)
	return true
end

--[[
函数名：stoprecord
功能  ：停止播放录音文件
参数  ：
		dl：模块下行（耳机或手柄或喇叭）是否可以听到录音播放的声音，true可以听到，false或者nil听不到
		loop：是否循环播放，true为循环，false或者nil为不循环
		id：录音id，会根据这个id存储录音文件，取值范围0-4
		duration：录音时长，单位毫秒
返回值：true
]]
function stoprecord(dl,loop,id,duration)
	stop()
	return true
end

--[[
function playamfgp(namepath,typ)
	req(string.format("AT+AMFGP=1,\"".. namepath .. "\"," .. (typ and typ or 1)))
	return true
end

function stopamfgp(namepath,typ)
	req(string.format("AT+AMFGP=0,\"".. namepath .. "\"," .. (typ and typ or 1)))
	return true
end
]]

--[[
函数名：_play
功能  ：播放音频文件
参数  ：
		name：音频文件路径
		loop：是否循环播放，true为循环，false或者nil为不循环
返回值：调用播放接口是否成功，true为成功，false为失败
]]
local function _play(name,loop)
	if loop then playname = name end
	return audio.play(name)
end

--[[
函数名：_stop
功能  ：停止播放音频文件
参数  ：无
返回值：调用停止播放接口是否成功，true为成功，false为失败
]]
local function _stop()
	playname = nil
	return audio.stop()
end

local dtmfnum = {[71] = "Hz1000",[69] = "Hz1400",[70] = "Hz2300"}

--[[
函数名：parsedtmfnum
功能  ：dtmf解码，解码后，会产生一个内部消息AUDIO_DTMF_DETECT，携带解码后的DTMF字符
参数  ：
		data：dtmf字符串数据
返回值：无
]]
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

--[[
函数名：audiourc
功能  ：本功能模块内“注册的底层core通过虚拟串口主动上报的通知”的处理
参数  ：
		data：通知的完整字符串信息
		prefix：通知的前缀
返回值：无
]]
local function audiourc(data,prefix)
	--DTMF接收检测
	if prefix == "+DTMFDET" then
		parsedtmfnum(data)	
	end
end

--[[
函数名：audiorsp
功能  ：本功能模块内“通过虚拟串口发送到底层core软件的AT命令”的应答处理
参数  ：
		cmd：此应答对应的AT命令
		success：AT命令执行结果，true或者false
		response：AT命令的应答中的执行结果字符串
		intermediate：AT命令的应答中的中间信息
返回值：无
]]
local function audiorsp(cmd,success,response,intermediate)
	local prefix = smatch(cmd,"AT(%+%u+%?*)")

  print("audiorsp prefix=",prefix)
end

--注册以下通知的处理函数
ril.regurc("+DTMFDET",audiourc)
ril.regurc("+AUDREC",audiourc)
--ril.regurc("+AMFGP",audiourc)
--注册以下AT命令的应答处理函数
ril.regrsp("+AUDREC",audiorsp,0)

--[[
函数名：setspeakervol
功能  ：设置音频通道的输出音量
参数  ：
		vol：音量等级，取值范围为audio.VOL0到audio.VOL7，audio.VOL0为静音
返回值：无
]]
function setspeakervol(vol)
	audio.setvol(vol)
	speakervol = vol
end

--[[
函数名：setcallvol
功能  ：设置通话音量
参数  ：
   vol：音量等级，取值范围为audio.VOL0到audio.VOL7，audio.VOL0为无声
返回值：无
]]
function setcallvol(vol)
  print("setcallvol",vol)
  audio.setsphvol(vol)
end

--[[
函数名：getspeakervol
功能  ：读取音频通道的输出音量
参数  ：无
返回值：音量等级
]]
function getspeakervol()
	return speakervol
end

--[[
函数名：setaudiochannel
功能  ：设置音频通道
参数  ：
		channel：音频通道，跟硬件设计有关，用户程序需要根据硬件配置，Air810模块就固定用audiocore.HANDSET
返回值：无
]]
local function setaudiochannel(channel)
	audio.setchannel(channel)
	audiochannel = channel
end

--[[
函数名：getaudiochannel
功能  ：读取音频通道
参数  ：无
返回值：音频通道
]]
local function getaudiochannel()
	return audiochannel
end

--[[
函数名：setloopback
功能  ：设置回环测试
参数  ：
		flag：是否打开回环测试，true为打开，false为关闭
		typ：测试回环的音频通道，跟硬件设计有关，用户程序需要根据硬件配置
		setvol：是否设置输出的音量，true为设置，false不设置
		vol：输出的音量
返回值：true设置成功，false设置失败
]]
function setloopback(flag,typ,setvol,vol)
	return audio.setloopback(flag,typ,setvol,vol)
end

--[[
函数名：setmicrophonegain
功能  ：设置MIC的音量
参数  ：
		vol：mic音量等级，取值范围为audio.MIC_VOL0到audio.MIC_VOL15，audio.MIC_VOL0为静音
返回值：无
]]
function setmicrophonegain(vol)
	audio.setmicvol(vol)
	microphonevol = vol
end

--[[
函数名：getmicrophonegain
功能  ：读取MIC的音量等级
参数  ：无
返回值：音量等级
]]
function getmicrophonegain()
	return microphonevol
end

--[[
函数名：audiomsg
功能  ：处理底层上报的rtos.MSG_AUDIO外部消息
参数  ：
		msg：play_end_ind，是否正常播放结束
		     play_error_ind，是否播放错误
返回值：无
]]
local function audiomsg(msg)
	if msg.play_end_ind == true then
		if playname then audio.play(playname) return end
		 playend()
	elseif msg.play_error_ind == true then
		if playname then playname = nil end
		playerr()
	end
end

--[[
函数名：recordmsg
功能  ：处理底层上报的rtos.MSG_RECORD外部消息
参数  ：
		msg：record_end_ind，录音是否正常结束
		     record_error_ind，录音是否发生错误
返回值：无
]]
function recordmsg(msg)
	print("recordmsg",msg.record_end_ind,msg.record_error_ind)
	recording = false
	if msg.record_end_ind == true then
		dispatch("AUDIO_RECORD_IND",true)
	elseif msg.record_error_ind == true then
		dispatch("AUDIO_RECORD_IND",false)
	end
end

--注册底层上报的rtos.MSG_AUDIO外部消息的处理函数
sys.regmsg(rtos.MSG_AUDIO,audiomsg)
--默认音频通道设置为RECEIVER，因为Air810模块只支持RECEIVER通道
setaudiochannel(audio.HANDSET)
--默认音量等级设置为4级，4级是中间等级，最低为0级，最高为7级
setspeakervol(audio.VOL4)


--[[
spriority：当前播放的音频优先级
styp：当前播放的音频类型
spath：当前播放的音频文件路径
svol：当前播放音量
scb：当前播放结束或者出错的回调函数
sdup：当前播放的音频是否需要重复播放
sduprd：如果sdup为true，此值表示重复播放的间隔(单位毫秒)，默认无间隔
spending：将要播放的音频是否需要正在播放的音频异步结束后，再播放
]]
local spriority,styp,spath,svol,scb,sdup,sduprd

--[[
函数名：playbegin
功能  ：关闭上次播放后，再播放本次请求
参数  ：
		priority：音频优先级，数值越小，优先级越高
		typ：音频类型，目前仅支持"FILE"、"TTS"、"RECORD"
		path：音频文件路径
		vol：播放音量，取值范围audiocore.VOL0到audiocore.VOL7。此参数可选
		cb：音频播放结束或者出错时的回调函数，回调时包含一个参数：0表示播放成功结束；1表示播放出错；2表示播放优先级不够，没有播放。此参数可选
		dup：是否循环播放，true循环，false或者nil不循环。此参数可选
		duprd：播放间隔(单位毫秒)，dup为true时，此值才有意义。此参数可选
返回值：调用成功返回true，否则返回nil
]]
local function playbegin(priority,typ,path,vol,cb,dup,duprd)
	print("playbegin")
	--重新赋值当前播放参数
	spriority,styp,spath,svol,scb,sdup,sduprd,spending = priority,typ,path,vol,cb,dup,duprd

	--如果存在音量参数，设置音量
	if vol then
		setspeakervol(vol)
    end
	
	--调用播放接口成功
	if _play(path,dup and (not duprd or duprd==0)) then
		return true
	--调用播放接口失败
	else
		spriority,styp,spath,svol,scb,sdup,sduprd,spending = nil
	end
end

--[[
函数名：play
功能  ：播放音频
参数  ：
		priority：number类型，必选参数，音频优先级，数值越大，优先级越高
		typ：string类型，必选参数，音频类型，目前仅支持"FILE"、"TTS"、"RECORD"
		path：必选参数，音频文件路径，跟typ有关：
		      typ为"FILE"时：string类型，表示音频文件路径
			  typ为"TTS"时：string类型，表示要播放数据的UCS2十六进制字符串
			  typ为"RECORD"时：number类型，表示录音ID
		vol：number类型，可选参数，播放音量，取值范围audiocore.VOL0到audiocore.VOL7
		cb：function类型，可选参数，音频播放结束或者出错时的回调函数，回调时包含一个参数：0表示播放成功结束；1表示播放出错；2表示播放优先级不够，没有播放
		dup：bool类型，可选参数，是否循环播放，true循环，false或者nil不循环
		duprd：number类型，可选参数，播放间隔(单位毫秒)，dup为true时，此值才有意义
返回值：调用成功返回true，否则返回nil
]]
function play(priority,typ,path,vol,cb,dup,duprd)
	assert(priority and typ,"play para err")
	print("play",priority,typ,path,vol,cb,dup,duprd,styp)
	--有音频正在播放
	if styp then
		--将要播放的音频优先级 高于 正在播放的音频优先级
		if priority > spriority then
			--如果正在播放的音频有回调函数，则执行回调，传入参数2
			if scb then scb(2) end
			--停止正在播放的音频
			if not stop() then
				spriority,styp,spath,svol,scb,sdup,sduprd,spending = priority,typ,path,vol,cb,dup,duprd,true
				return
			end
		--将要播放的音频优先级 低于 正在播放的音频优先级
		elseif priority < spriority then
			--直接返回nil，不允许播放
			return
		--将要播放的音频优先级 等于 正在播放的音频优先级，有两种情况(1、正在循环播放；2、用户重复调用接口播放同一音频类型)
		else
			--如果是第2种情况，直接返回；第1中情况，直接往下走
			if not sdup then
				return
			end
		end
	end

	playbegin(priority,typ,path,vol,cb,dup,duprd)
end

--[[
函数名：stop
功能  ：停止音频播放
参数  ：无
返回值：如果可以成功同步停止，返回true，否则返回nil
]]
function stop()
	if styp then
		local typ = styp
		spriority,styp,spath,svol,scb,sdup,sduprd,spending = nil
		--停止循环播放定时器
		sys.timer_stop_all(play)
		--停止音频播放
		_stop()
	end
	return true
end

--[[
函数名：playend
功能  ：音频播放成功结束处理函数
参数  ：无
返回值：无
]]
function playend()
	print("playend",sdup,sduprd)
	--需要重复播放
	if sdup then
		--存在重复播放间隔
		if sduprd then
			sys.timer_start(play,sduprd,spriority,styp,spath,svol,scb,sdup,sduprd)
		end
	--不需要重复播放
	else
		--如果正在播放的音频有回调函数，则执行回调，传入参数0
		if scb then scb(0) end
		spriority,styp,spath,svol,scb,sdup,sduprd,spending = nil
	end
end

--[[
函数名：playerr
功能  ：音频播放失败处理函数
参数  ：无
返回值：无
]]
function playerr()
	print("playerr")
	--如果正在播放的音频有回调函数，则执行回调，传入参数1
	if scb then scb(1) end
	spriority,styp,spath,svol,scb,sdup,sduprd,spending = nil
end

local stopreqcb
--[[
函数名：audstopreq
功能  ：lib脚本间发送消息AUDIO_STOP_REQ的处理函数
参数  ：
		cb：音频停止后的回调函数
返回值：无
]]
local function audstopreq(cb)
	if stop() then cb() return end
	stopreqcb = cb
end

local procer =
{
	AUDIO_STOP_REQ = audstopreq,--lib脚本间通过发送消息来实现音频停止，用户脚本不要发送此消息
}
--注册消息处理函数表
sys.regapp(procer)
