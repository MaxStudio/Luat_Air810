module(...,package.seeall)

require"audio"
require"common"

--��Ƶ�������ȼ�����Ӧaudio.play�ӿ��е�priority��������ֵԽ�����ȼ�Խ�ߣ��û������Լ��������������ȼ�
--PWRON����������
--CALL����������
--SMS���¶�������
PWRON,CALL,SMS = 2,1,0

local function testcb(r)
	print("testcb",r)
end

--������Ƶ�ļ����Խӿڣ�ÿ�δ�һ�д�����в���
local function testplayfile()
	--���β�������������Ĭ�������ȼ�
	--audio.play(CALL,"FILE","/ldata/call.mp3")
	--���β������������������ȼ�7
	--audio.play(CALL,"FILE","/ldata/call.mp3",audiocore.VOL7)
	--���β������������������ȼ�7�����Ž������߳������testcb�ص�����
	--audio.play(CALL,"FILE","/ldata/call.mp3",audiocore.VOL7,testcb)
	--ѭ���������������������ȼ�7��û��ѭ�����(һ�β��Ž���������������һ��)
	audio.play(CALL,"FILE","/ldata/call.mp3",audiocore.VOL7,nil,true)
	--ѭ���������������������ȼ�7��ѭ�����Ϊ2000����
	--audio.play(CALL,"FILE","/ldata/call.mp3",audiocore.VOL7,nil,true,2000)
end

--���ų�ͻ���Խӿڣ�ÿ�δ�һ��if�����в���
local function testplayconflict()	

	if true then
		--ѭ��������������
		audio.play(CALL,"FILE","/ldata/call.mp3",audiocore.VOL7,nil,true)
		--5���Ӻ�ѭ�����ſ�������
		sys.timer_start(audio.play,5000,PWRON,"FILE","/ldata/pwron.mp3",audiocore.VOL7,nil,true)		
	end

	
	--[[
	if true then
		--ѭ��������������
		audio.play(CALL,"FILE","/ldata/call.mp3",audiocore.VOL7,nil,true)
		--5���Ӻ󣬳���ѭ�������¶����������������ȼ����������Ქ��
		sys.timer_start(audio.play,5000,SMS,"FILE","/ldata/sms.mp3",audiocore.VOL7,nil,true)
		
	end
	]]	
end


--ÿ�δ������һ�д�����в���
--sys.timer_start(testplayfile,5000)
sys.timer_start(testplayconflict,5000)
