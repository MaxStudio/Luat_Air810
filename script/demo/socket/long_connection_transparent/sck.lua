module(...,package.seeall)

--[[
��������
1����������׼�����������Ӻ�̨
2�����ӳɹ���ѭ������ȡmcuͨ�����ڷ��͹��������ݣ�ÿ����෢��1K�ֽڡ�
3�����̨���ֳ����ӣ��Ͽ���������ȥ���������ӳɹ���Ȼ���յ�2����������
4���յ���̨������ʱ����rcv�����д�ӡ����������ͨ������͸����mcu
����ʱ���Լ��ĺ�̨�������������޸������PROT��ADDR��PORT 

������Ϊ�����ӣ�ֻҪ��������ܹ���⵽�������쳣�������Զ�ȥ��������
]]

local ssub,schar,smatch,sbyte,slen = string.sub,string.char,string.match,string.byte,string.len
--����ʱ���Լ��ķ�����
local SCK_IDX,PROT,ADDR,PORT = 1,"TCP","www.your-server.com",8000
--linksta:���̨��socket����״̬
local linksta
--һ�����������ڵĶ�����������Ӻ�̨ʧ�ܣ��᳢���������������ΪRECONN_PERIOD�룬�������RECONN_MAX_CNT��
--���һ�����������ڶ�û�����ӳɹ�����ȴ�RECONN_CYCLE_PERIOD������·���һ����������
--�������RECONN_CYCLE_MAX_CNT�ε��������ڶ�û�����ӳɹ������������
local RECONN_MAX_CNT,RECONN_PERIOD,RECONN_CYCLE_MAX_CNT,RECONN_CYCLE_PERIOD = 3,5,3,20
--reconncnt:��ǰ���������ڣ��Ѿ������Ĵ���
--reconncyclecnt:�������ٸ��������ڣ���û�����ӳɹ�
--һ�����ӳɹ������Ḵλ���������
--conning:�Ƿ��ڳ�������
local reconncnt,reconncyclecnt,conning = 0,0
--���ڷ��͵�����
local sndingdata = ""

--[[
��������print
����  ����ӡ�ӿڣ����ļ��е����д�ӡ�������sckǰ׺
����  ����
����ֵ����
]]
local function print(...)
	_G.print("sck",...)
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
��������sndmcuartdata
����  ��������еȴ����͵�mcuͨ�����ڴ����������ݣ����������
����  ����
����ֵ����
]]
local function sndmcuartdata()
	if sndingdata=="" then
		sndingdata = mcuart.resumesndtosvr()
	end
	if linksta and sndingdata~="" then snd(sndingdata,"TRANSPARENT") end
end

--[[
��������sndcb
����  �����ݷ��ͽ������
����  ��  
        result�� bool���ͣ����ͽ����trueΪ�ɹ�������Ϊʧ��
		item��table���ͣ�{data=,para=}����Ϣ�ش��Ĳ��������ݣ��������linkapp.scksndʱ����ĵ�2���͵�3�������ֱ�Ϊdat��par����item={data=dat,para=par}
����ֵ����
]]
local function sndcb(item,result)
	print("sndcb",item.para,result)
	if not item.para then return end
	if item.para=="TRANSPARENT" then
		--���ͳɹ������������°�����
		if result then
			sndingdata = ""
			--sys.dispatch("SND_TO_SVR_CNF",true)
			sndmcuartdata()
		--����ʧ�ܣ�RECONN_PERIOD���������̨
		else
			sys.timer_start(reconn,RECONN_PERIOD*1000)
		end
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
			reconncnt,reconncyclecnt,linksta = 0,0,true
			--ֹͣ������ʱ��
			sys.timer_stop(reconn)
			--����mcuͨ�����ڴ����������ݵ���̨
			sndmcuartdata()
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
	--���ӱ����Ͽ�
	elseif evt == "STATE" and result == "CLOSED" then
		linksta = false
		reconn()
	--���������Ͽ�
	elseif evt == "DISCONNECT" then
		linksta = false
		reconn()		
	end
	--�����������Ͽ�������·����������
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
	print("rcv",slen(data)>200 and slen(data) or data)
	--�׳�SVR_TRANSPARENT_TO_MCU��Ϣ��Я��socket�յ�������
	sys.dispatch("SVR_TRANSPARENT_TO_MCU",data)
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
	linkapp.sckconn(SCK_IDX,linkapp.NORMAL,PROT,ADDR,PORT,ntfy,rcv)
	conning = true
end

--��Ϣ�������б�
local procer =
{
	SND_TO_SVR_REQ = sndmcuartdata,
}

--ע����Ϣ�������б�
sys.regapp(procer)
connect()
