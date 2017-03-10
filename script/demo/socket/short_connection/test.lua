module(...,package.seeall)

--[[
������Ϊ������
��������
1��ÿ��10���ӷ���һ��λ�ð�1"loc data1\r\n"����̨�����۷��ͳɹ�����ʧ�ܶ��Ͽ����ӣ�
   ÿ��20���ӷ���һ��λ�ð�2"loc data2\r\n"����̨�����۷��ͳɹ�����ʧ�ܶ��Ͽ�����
2���յ���̨������ʱ����rcv�����д�ӡ����
����ʱ���Լ��ķ������������޸������PROT��ADDR��PORT 
]]

local ssub,schar,smatch,sbyte = string.sub,string.char,string.match,string.byte
--����ʱ���Լ��ķ�����
local SCK_IDX,PROT,ADDR,PORT = 1,"TCP","www.your-server.com",8000
local linksta 
--�Ƿ�ɹ����ӹ�������
local hasconnected
--���������һ��Ҳû�������Ϻ�̨�����������쳣����
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
��������locrpt2
����  ������λ�ð�����2����̨
����  ���� 
����ֵ����
]]
function locrpt2()
	print("locrpt2",linksta)
	--if linksta then
		if not snd("loc data2\r\n","LOCRPT2")	then locrpt2cb({data="loc data2\r\n",para="LOCRPT2"},false) end
	--end
end

--[[
��������locrpt2cb
����  ��λ�ð�2���ͽ������������ʱ����20���Ӻ��ٴη���λ�ð�2
����  ��  
        result�� bool���ͣ����ͽ�������Ƿ�ʱ��trueΪ�ɹ����߳�ʱ������Ϊʧ��
		item��table���ͣ�{data=,para=}����Ϣ�ش��Ĳ��������ݣ��������linkapp.scksndʱ����ĵ�2���͵�3�������ֱ�Ϊdat��par����item={data=dat,para=par}
����ֵ����
]]
function locrpt2cb(item,result)
	print("locrpt2cb",linksta)
	--if linksta then
		linkapp.sckdisc(SCK_IDX)
		sys.timer_start(locrpt2,20000)
	--end
end


--[[
��������locrpt1
����  ������λ�ð�����1����̨
����  ���� 
����ֵ����
]]
function locrpt1()
	print("locrpt1",linksta)
	--if linksta then
		if not snd("loc data1\r\n","LOCRPT1")	then locrpt1cb({data="loc data1\r\n",para="LOCRPT1"},false) end	
	--end
end

--[[
��������locrpt1cb
����  ��λ�ð�1���ͽ������������ʱ����10���Ӻ��ٴη���λ�ð�2
����  ��  
        result�� bool���ͣ����ͽ�������Ƿ�ʱ��trueΪ�ɹ����߳�ʱ������Ϊʧ��
		item��table���ͣ�{data=,para=}����Ϣ�ش��Ĳ��������ݣ��������linkapp.scksndʱ����ĵ�2���͵�3�������ֱ�Ϊdat��par����item={data=dat,para=par}
����ֵ����
]]
function locrpt1cb(item,result)
	print("locrpt1cb",linksta)
	--if linksta then
		linkapp.sckdisc(SCK_IDX)
		sys.timer_start(locrpt1,10000)
	--end
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
	if item.para=="LOCRPT1" then
		locrpt1cb(item,result)
	elseif item.para=="LOCRPT2" then
		locrpt2cb(item,result)
	end
	if not result then link.shut() end
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
	print("ntfy",evt,result,item,hasconnected)
	--���ӽ��
	if evt == "CONNECT" then
		reconning = false
		--���ӳɹ�
		if result then
			reconncnt,reconncyclecnt,linksta = 0,0,true
			--ֹͣ������ʱ��
			sys.timer_stop(reconn)
			--�������һ�����ӳɹ�
			if not hasconnected then
				hasconnected = true
				--����λ�ð�1����̨
				locrpt1()
				--����λ�ð�2����̨
				locrpt2()
			end
		--����ʧ��
		else
			if not hasconnected then
				--5�������
				sys.timer_start(reconn,RECONN_PERIOD*1000)
			else				
				link.shut()
			end			
		end	
	--���ݷ��ͽ��
	elseif evt == "SEND" then
		if item then
			sndcb(item,result)
		end
	--���ӱ����Ͽ�
	elseif evt == "STATE" and result == "CLOSED" then
		linksta = false
		--�����Զ��幦�ܴ���
	--���������Ͽ�
	elseif evt == "DISCONNECT" then
		linksta = false				
	end
	--����������
	if smatch((type(result)=="string") and result or "","ERROR") then
		--�Ͽ�������·�����¼���
		link.shut()
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
