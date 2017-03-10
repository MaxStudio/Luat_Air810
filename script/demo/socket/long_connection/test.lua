module(...,package.seeall)

--[[
��������
1����������׼�����������Ӻ�̨
2�����ӳɹ���ÿ��10���ӷ���һ��������"heart data\r\n"����̨��ÿ��20���ӷ���һ��λ�ð�"loc data\r\n"����̨
3�����̨���ֳ����ӣ��Ͽ���������ȥ���������ӳɹ���Ȼ���յ�2����������
4���յ���̨������ʱ����rcv�����д�ӡ����
����ʱ���Լ��ķ������������޸������PROT��ADDR��PORT 

������Ϊ�����ӣ�ֻҪ��������ܹ���⵽�������쳣�������Զ�ȥ�������ӣ�
��ʱ����ּ�ⲻ�����쳣�������������������һ�㰴�����·�ʽ��������һ����������ÿ��Aʱ�䷢��һ�ε���̨����̨�ظ�Ӧ���������n����Aʱ�䶼û���յ���̨���κ����ݣ�����Ϊ������δ֪�������쳣����ʱ����link.shut�����Ͽ���Ȼ���Զ�����
]]

local ssub,schar,smatch,sbyte = string.sub,string.char,string.match,string.byte
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
--reconning:�Ƿ��ڳ�������
local reconncnt,reconncyclecnt,reconning = 0,0

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
��������locrpt
����  ������λ�ð����ݵ���̨
����  ����
����ֵ����
]]
function locrpt()
	print("locrpt",linksta)
	if linksta then
		snd("loc data\r\n","LOCRPT")		
	end
end


--[[
��������locrptcb
����  ��λ�ð����ͻص���������ʱ����20���Ӻ��ٴη���λ�ð�
����  ��		
		item��table���ͣ�{data=,para=}����Ϣ�ش��Ĳ��������ݣ��������linkapp.scksndʱ����ĵ�2���͵�3�������ֱ�Ϊdat��par����item={data=dat,para=par}
		result�� bool���ͣ����ͽ����trueΪ�ɹ�������Ϊʧ��
����ֵ����
]]
function locrptcb(item,result)
	print("locrptcb",linksta)
	if linksta then
		sys.timer_start(locrpt,20000)
	end
end


--[[
��������heartrpt
����  ���������������ݵ���̨
����  ����
����ֵ����
]]
function heartrpt()
	print("heartrpt",linksta)
	if linksta then
		snd("heart data\r\n","HEARTRPT")		
	end
end

--[[
��������locrptcb
����  �����������ͻص���������ʱ����10���Ӻ��ٴη���������
����  ��		
		item��table���ͣ�{data=,para=}����Ϣ�ش��Ĳ��������ݣ��������linkapp.scksndʱ����ĵ�2���͵�3�������ֱ�Ϊdat��par����item={data=dat,para=par}
		result�� bool���ͣ����ͽ����trueΪ�ɹ�������Ϊʧ��
����ֵ����
]]
function heartrptcb(item,result)
	print("heartrptcb",linksta)
	if linksta then
		sys.timer_start(heartrpt,10000)
	end
end


--[[
��������sndcb
����  �����ݷ��ͽ������
����  ��          
		item��table���ͣ�{data=,para=}����Ϣ�ش��Ĳ��������ݣ��������linkapp.scksndʱ����ĵ�2���͵�3�������ֱ�Ϊdat��par����item={data=dat,para=par}
		result�� bool���ͣ����ͽ����trueΪ�ɹ�������Ϊʧ��
����ֵ����
]]
local function sndcb(item,result)
	print("sndcb",item.para,result)
	if not item.para then return end
	if item.para=="LOCRPT" then
		locrptcb(item,result)
	elseif item.para=="HEARTRPT" then
		heartrptcb(item,result)
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
local function reconn()
	print("reconn",reconncnt,reconning,reconncyclecnt)
	--conning��ʾ���ڳ������Ӻ�̨��һ��Ҫ�жϴ˱����������п��ܷ��𲻱�Ҫ������������reconncnt���ӣ�ʵ�ʵ�������������
	if reconning then return end
	--һ�����������ڵ�����
	if reconncnt < RECONN_MAX_CNT then		
		reconncnt = reconncnt+1
		link.shut()
		connect(linkapp.NORMAL)
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
		reconning = false
		--���ӳɹ�
		if result then
			reconncnt,reconncyclecnt,linksta = 0,0,true
			--ֹͣ������ʱ��
			sys.timer_stop(reconn)
			--��������������̨
			heartrpt()
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
	--���ӱ����Ͽ�
	elseif evt == "STATE" and result == "CLOSED" then
		linksta = false
		sys.timer_stop(heartrpt)
		sys.timer_stop(locrpt)
		reconn()
	--���������Ͽ�
	elseif evt == "DISCONNECT" then
		linksta = false
		sys.timer_stop(heartrpt)
		sys.timer_stop(locrpt)
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
        id ��linkapp��ά����socket idx��������linkapp.sckconnʱ����ĵ�һ��������ͬ��������Ժ��Բ�����
        data�����յ�������
����ֵ����
]]
function rcv(id,data)
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
	linkapp.sckconn(SCK_IDX,linkapp.NORMAL,PROT,ADDR,PORT,ntfy,rcv)
	reconning = true
end

connect()
