module(...,package.seeall)

local function testcb(r)
	print("testcb",r)
end

--������Ƶ�ļ����Խӿڣ�ÿ�δ�һ�д�����в���
local function testplayfile()
	--���β�������������Ĭ�������ȼ�
	--audioapp.play(audioapp.CALL,"/ldata/call.mp3")
	--���β������������������ȼ�7
	--audioapp.play(audioapp.CALL,"/ldata/call.mp3",audiocore.VOL7)
	--���β������������������ȼ�7�����Ž������߳������testcb�ص�����
	--audioapp.play(audioapp.CALL,"/ldata/call.mp3",audiocore.VOL7,testcb)
	--ѭ���������������������ȼ�7��û��ѭ�����(һ�β��Ž���������������һ��)
	audioapp.play(audioapp.CALL,"/ldata/call.mp3",audiocore.VOL7,nil,true)
	--ѭ���������������������ȼ�7��ѭ�����Ϊ2000����
	--audioapp.play(audioapp.CALL,"/ldata/call.mp3",audiocore.VOL7,nil,true,2000)
end

--���ų�ͻ���Խӿڣ�ÿ�δ�һ��if�����в���
local function testplayconflict()	

	if true then
		--ѭ��������������
		audioapp.play(audioapp.CALL,"/ldata/call.mp3",audiocore.VOL7,nil,true)
		--5���Ӻ�ѭ�����ſ�������
		sys.timer_start(audioapp.play,5000,audioapp.PWRON,"/ldata/pwron.mp3",audiocore.VOL7,nil,true)
		
	end

	
	--[[
	if true then
		--ѭ��������������
		audioapp.play(audioapp.CALL,"/ldata/call.mp3",audiocore.VOL7,nil,true)
		--5���Ӻ󣬳���ѭ�������¶����������������ȼ����������Ქ��
		sys.timer_start(audioapp.play,5000,audioapp.SMS,"/ldata/sms.mp3",audiocore.VOL7,nil,true)
		
	end
	]]
end


--ÿ�δ������һ�д�����в���
sys.timer_start(testplayfile,5000)
--sys.timer_start(testplayconflict,5000)
