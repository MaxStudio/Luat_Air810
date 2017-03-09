--[[
ģ�����ƣ���Ƶ����
ģ�鹦�ܣ���Ƶ���š�ֹͣ����ͻ����
ģ������޸�ʱ�䣺2017.02.23
]]

module(...,package.seeall)

--��Ƶ���ͣ���ֵԽС�����ȼ�Խ�ߣ��û������Լ��������������ȼ�
--PWRON����������
--CALL����������
--SMS���¶�������
--TTS��TTS����
PWRON,CALL,SMS,TTS = 0,1,2,3

--styp����ǰ���ŵ���Ƶ����
--spath����ǰ���ŵ���Ƶ�ļ�·��
--svol����ǰ��������
--scb����ǰ���Ž������߳���Ļص�����
--sdup����ǰ���ŵ���Ƶ�Ƿ���Ҫ�ظ�����
--sduprd�����sdupΪtrue����ֵ��ʾ�ظ����ŵļ��(��λ����)��Ĭ���޼��
--spending����Ҫ���ŵ���Ƶ�Ƿ���Ҫ���ڲ��ŵ���Ƶ�첽�������ٲ���
local styp,spath,svol,scb,sdup,sduprd

--[[
��������print
����  ����ӡ�ӿڣ����ļ��е����д�ӡ�������audioappǰ׺
����  ����
����ֵ����
]]
local function print(...)
	_G.print("audioapp",...)
end

--[[
��������playbegin
����  ���ر��ϴβ��ź��ٲ��ű�������
����  ��
		typ����Ƶ���ͣ��ο�PWRON,CALL,SMS
		path����Ƶ�ļ�·��
		vol������������ȡֵ��Χaudiocore.VOL0��audiocore.VOL7���˲�����ѡ
		cb����Ƶ���Ž������߳���ʱ�Ļص��������ص�ʱ����һ��������0��ʾ���ųɹ�������1��ʾ���ų���2��ʾ�������ȼ�������û�в��š��˲�����ѡ
		dup���Ƿ�ѭ�����ţ�trueѭ����false����nil��ѭ�����˲�����ѡ
		duprd�����ż��(��λ����)��dupΪtrueʱ����ֵ�������塣�˲�����ѡ
����ֵ�����óɹ�����true�����򷵻�nil
]]
local function playbegin(typ,path,vol,cb,dup,duprd)
	print("playbegin")
	--���¸�ֵ��ǰ���Ų���
	styp,spath,svol,scb,sdup,sduprd,spending = typ,path,vol,cb,dup,duprd

	--�������������������������
	if vol then
		audio.setspeakervol(vol)
    end
	
	--���ò��Žӿڳɹ�
	if (typ==TTS and audio.playtts(path)) or (typ~=TTS and audio.play(path,dup and (not duprd or duprd==0))) then
		return true
	--���ò��Žӿ�ʧ��
	else
		styp,spath,svol,scb,sdup,sduprd,spending = nil
	end
end

--[[
��������play
����  ��������Ƶ
����  ��
		typ����Ƶ���ͣ��ο�PWRON,CALL,SMS
		path����Ƶ�ļ�·��
		vol������������ȡֵ��Χaudiocore.VOL0��audiocore.VOL7���˲�����ѡ
		cb����Ƶ���Ž������߳���ʱ�Ļص��������ص�ʱ����һ��������0��ʾ���ųɹ�������1��ʾ���ų���2��ʾ�������ȼ�������û�в��š��˲�����ѡ
		dup���Ƿ�ѭ�����ţ�trueѭ����false����nil��ѭ�����˲�����ѡ
		duprd�����ż��(��λ����)��dupΪtrueʱ����ֵ�������塣�˲�����ѡ
����ֵ�����óɹ�����true�����򷵻�nil
]]
function play(typ,path,vol,cb,dup,duprd)
	print("play",typ,path,vol,cb,dup,duprd,styp)
	--����Ƶ���ڲ���
	if styp then
		--���ڲ��ŵ���Ƶ���ȼ� ���� ��Ҫ���ŵ���Ƶ���ȼ�
		if typ < styp then
			--������ڲ��ŵ���Ƶ�лص���������ִ�лص����������2
			if scb then scb(2) end
			--ֹͣ���ڲ��ŵ���Ƶ
			if not stop() then
				styp,spath,svol,scb,sdup,sduprd,spending = typ,path,vol,cb,dup,duprd,true
				return
			end
		--���ڲ��ŵ���Ƶ���ȼ� ���� ��Ҫ���ŵ���Ƶ���ȼ�
		elseif typ > styp then
			--ֱ�ӷ���nil����������
			return
		--���ڲ��ŵ���Ƶ���ȼ� ���� ��Ҫ���ŵ���Ƶ���ȼ������������(1������ѭ�����ţ�2���û��ظ����ýӿڲ���ͬһ��Ƶ����)
		else
			--����ǵ�2�������ֱ�ӷ��أ���1�������ֱ��������
			if not sdup then
				return
			end
		end
	end

	playbegin(typ,path,vol,cb,dup,duprd)
end

--[[
��������stop
����  ��ֹͣ��Ƶ����
����  ����
����ֵ��������Գɹ�ͬ��ֹͣ������true�����򷵻�nil
]]
function stop()
	local typ = styp
	styp,spath,svol,scb,sdup,sduprd,spending = nil
	--ֹͣѭ�����Ŷ�ʱ��
	sys.timer_stop_all(play)
	--ֹͣ��Ƶ����
	audio.stop()
	if typ==TTS then audio.stoptts() return end
	return true
end

--[[
��������playend
����  ����Ƶ���ųɹ�����������
����  ����
����ֵ����
]]
local function playend()
	print("playend",sdup,sduprd)
	if styp==TTS and not sdup then audio.stoptts() end
	--��Ҫ�ظ�����
	if sdup then
		--�����ظ����ż��
		if sduprd then
			sys.timer_start(play,sduprd,styp,spath,svol,scb,sdup,sduprd)
		--�������ظ����ż��
		elseif styp==TTS then
			play(styp,spath,svol,scb,sdup,sduprd)
		end
	--����Ҫ�ظ�����
	else
		--������ڲ��ŵ���Ƶ�лص���������ִ�лص����������0
		if scb then scb(0) end
		styp,spath,svol,scb,sdup,sduprd,spending = nil
	end
end

--[[
��������playerr
����  ����Ƶ����ʧ�ܴ�����
����  ����
����ֵ����
]]
local function playerr()
	print("playerr")
	if styp==TTS then audio.stoptts() end
	--������ڲ��ŵ���Ƶ�лص���������ִ�лص����������1
	if scb then scb(1) end
	styp,spath,svol,scb,sdup,sduprd,spending = nil
end

--[[
��������ttstopind
����  ������audio.stoptts()�ӿں�ttsֹͣ���ź����Ϣ������
����  ����
����ֵ����
]]
local function ttstopind()
	print("ttstopind",spending)
	if spending then playbegin(styp,spath,svol,scb,sdup,sduprd) end
end

--��Ƶ������Ϣ��������
local procer =
{
	AUDIO_PLAY_END_IND = playend,
	AUDIO_PLAY_ERROR_IND = playerr,
	TTS_STOP_IND = ttstopind,
}
--ע����Ƶ������Ϣ������
sys.regapp(procer)
