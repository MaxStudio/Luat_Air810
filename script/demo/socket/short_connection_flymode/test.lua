module(...,package.seeall)

--[[
������Ϊ�����ӣ��������ݺ󣬽������ģʽ��Ȼ��ʱ�˳�����ģʽ�ٷ������ݣ����ѭ��
��������
1�����Ӻ�̨����λ�ð�"loc data\r\n"����̨����ʱʱ��Ϊ2���ӣ�2���������ʧ�ܣ���һֱ���ԣ����ͳɹ����߳�ʱ�󶼽������ģʽ��
2���������ģʽ5���Ӻ��˳�����ģʽ��Ȼ�������1��
ѭ������2������
2���յ���̨������ʱ����rcv�����д�ӡ����
����ʱ���Լ��ķ������������޸������PROT��ADDR��PORT 
]]

local ssub,schar,smatch,sbyte = string.sub,string.char,string.match,string.byte
--����ʱ���Լ��ķ�����
local SCK_IDX,PROT,ADDR,PORT = 1,"TCP","www.your-server.com",8000
--ÿ�����Ӻ�̨�����������쳣����
--һ�����������ڵĶ�����������Ӻ�̨ʧ�ܣ��᳢���������������ΪRECONN_PERIOD�룬�������RECONN_MAX_CNT��
--���һ�����������ڶ�û�����ӳɹ�����ȴ�RECONN_CYCLE_PERIOD������·���һ����������
--�������RECONN_CYCLE_MAX_CNT�ε��������ڶ�û�����ӳɹ������������
local RECONN_MAX_CNT,RECONN_PERIOD,RECONN_CYCLE_MAX_CNT,RECONN_CYCLE_PERIOD = 3,5,1,20
--reconncnt:��ǰ���������ڣ��Ѿ������Ĵ���
--reconncyclecnt:�������ٸ��������ڣ���û�����ӳɹ�
--һ�����ӳɹ������Ḵλ���������
--reconning:�Ƿ��ڳ���������
local reconncnt,reconncyclecnt,conning = 0,0

--[[
��������print
����  ����ӡ�ӿڣ����ļ��е����д�ӡ�������testǰ׺
����  ����
����ֵ����
]]
local function print(...)
	_G.print("test",...)
end

--[[
��������snd
����  �����÷��ͽӿڷ�������
����  ��
        data�����͵����ݣ��ڷ��ͽ���¼�������ntfy�У��ḳֵ��item.data��
		para�����͵Ĳ������ڷ��ͽ���¼�������ntfy�У��ḳֵ��item.para�� 
����ֵ�����÷��ͽӿڵĽ�������������ݷ����Ƿ�ɹ��Ľ�������ݷ����Ƿ�ɹ��Ľ����ntfy�е�SEND�¼���֪ͨ����trueΪ�ɹ�������Ϊʧ��
]]
function snd(data,para)
	return linkapp.scksnd(SCK_IDX,data,para)
end


--[[
��������locrptimeout
����  ��λ�ð����ݷ��ͳ�ʱ����ֱ�ӽ������ģʽ
����  ����  
����ֵ����
]]
local function locrptimeout()
	print("locrptimeout")
	locrptcb(true)
end

--[[
��������locrpt
����  ������λ�ð����ݵ���̨
����  ���� 
����ֵ����
]]
function locrpt()
	print("locrpt")	
	--���÷��ͽӿڳɹ������������ݷ��ͳɹ������ݷ����Ƿ�ɹ�����ntfy�е�SEND�¼���֪ͨ
	if snd("loc data\r\n","LOCRPT")	then
		--����2���Ӷ�ʱ���������ʱ2�������ݶ�û�з��ͳɹ�����ֱ�ӽ������ģʽ
		sys.timer_start(locrptimeout,120000)
	--���÷��ͽӿ�ʧ�ܣ�����������
	else
		locrptcb()
	end	
end

--[[
��������locrptcb
����  ��λ�ð����ͽ���������ͳɹ����߳�ʱ������������ģʽ������5���ӵġ��˳�����ģʽ�����Ӻ�̨����ʱ��
����  ��  
        result�� bool���ͣ����ͽ�������Ƿ�ʱ��trueΪ�ɹ����߳�ʱ������Ϊʧ��
		item��table���ͣ�{data=,para=}����Ϣ�ش��Ĳ��������ݣ��������linkapp.scksndʱ����ĵ�2���͵�3�������ֱ�Ϊdat��par����item={data=dat,para=par}
����ֵ����
]]
function locrptcb(result,item)
	print("locrptcb",result)
	if result then
		linkapp.sckdisc(SCK_IDX)
		link.shut()
		misc.setflymode(true)
		sys.timer_start(connect,300000)
		sys.timer_stop(locrptimeout)
	else
		sys.timer_start(reconn,RECONN_PERIOD*1000)
	end
end

--[[
��������sndcb
����  ���������ݽ���¼��Ĵ���
����  ��  
        result�� bool���ͣ���Ϣ�¼������trueΪ�ɹ�������Ϊʧ��
		item��table���ͣ�{data=,para=}����Ϣ�ش��Ĳ��������ݣ��������linkapp.scksndʱ����ĵ�2���͵�3�������ֱ�Ϊdat��par����item={data=dat,para=par}
����ֵ����
]]
local function sndcb(item,result)
	print("sndcb",item.para,result)
	if not item.para then return end
	if item.para=="LOCRPT" then
		locrptcb(result,item)
	end	
end

--[[
��������reconn
����  ��������̨����
        һ�����������ڵĶ�����������Ӻ�̨ʧ�ܣ��᳢���������������ΪRECONN_PERIOD�룬�������RECONN_MAX_CNT��
        ���һ�����������ڶ�û�����ӳɹ�����ȴ�RECONN_CYCLE_PERIOD������·���һ����������
        �������RECONN_CYCLE_MAX_CNT�ε��������ڶ�û�����ӳɹ������������
����  ����
����ֵ����
]]
function reconn()
	print("reconn",reconncnt,conning,reconncyclecnt)
	--conning��ʾ���ڳ������Ӻ�̨��һ��Ҫ�жϴ˱����������п��ܷ��𲻱�Ҫ������������reconncnt���ӣ�ʵ�ʵ�������������
	if conning then return end
	--һ�����������ڵ�����
	if reconncnt < RECONN_MAX_CNT then		
		reconncnt = reconncnt+1
		link.shut()
		connect()
	--һ���������ڵ�������ʧ��
	else
		reconncnt,reconncyclecnt = 0,reconncyclecnt+1
		if reconncyclecnt >= RECONN_CYCLE_MAX_CNT then
			dbg.restart("connect fail")
		end
		sys.timer_start(reconn,RECONN_CYCLE_PERIOD*1000)
	end
end

--[[
��������ntfy
����  ��socket״̬�Ĵ�����
����  ��
        idx��number���ͣ�linkapp��ά����socket idx��������linkapp.sckconnʱ����ĵ�һ��������ͬ��������Ժ��Բ�����
        evt��string���ͣ���Ϣ�¼�����
		result�� bool���ͣ���Ϣ�¼������trueΪ�ɹ�������Ϊʧ��
		item��table���ͣ�{data=,para=}����Ϣ�ش��Ĳ��������ݣ�Ŀǰֻ����SEND���͵��¼����õ��˴˲������������linkapp.scksndʱ����ĵ�2���͵�3�������ֱ�Ϊdat��par����item={data=dat,para=par}
����ֵ����
]]
function ntfy(idx,evt,result,item)
	print("ntfy",evt,result,item)
	--���ӽ��
	if evt == "CONNECT" then
		conning = false
		--���ӳɹ�
		if result then
			reconncnt,reconncyclecnt = 0,0
			--ֹͣ������ʱ��
			sys.timer_stop(reconn)			
			--����λ�ð�����̨
			locrpt()
		--����ʧ��
		else
			--RECONN_PERIOD�������
			sys.timer_start(reconn,RECONN_PERIOD*1000)
		end	
	--���ݷ��ͽ��
	elseif evt == "SEND" then
		if item then
			sndcb(item,result)
		end
	--���ӱ����Ͽ����ߵ���link.shut��
	elseif evt == "STATE" and result == "CLOSED" then

	--���������Ͽ�
	elseif evt == "DISCONNECT" then
			
	end
	--����������
	if smatch((type(result)=="string") and result or "","ERROR") then
		--RECONN_PERIOD�������
		sys.timer_start(reconn,RECONN_PERIOD*1000)
	end
end

--[[
��������rcv
����  ��socket�������ݵĴ�����
����  ��
        idx ��linkapp��ά����socket idx��������linkapp.sckconnʱ����ĵ�һ��������ͬ��������Ժ��Բ�����
        data�����յ�������
����ֵ����
]]
function rcv(idx,data)
	print("rcv",data)
end

--[[
��������connect
����  ����������̨�����������ӣ�
        ������������Ѿ�׼���ã���������Ӻ�̨��������������ᱻ���𣬵���������׼���������Զ�ȥ���Ӻ�̨
		ntfy��socket״̬�Ĵ�����
		rcv��socket�������ݵĴ�����
����  ����
����ֵ����
]]
function connect()
	misc.setflymode(false)
	linkapp.sckconn(SCK_IDX,linkapp.NORMAL,PROT,ADDR,PORT,ntfy,rcv)
	conning = true
end

connect()
