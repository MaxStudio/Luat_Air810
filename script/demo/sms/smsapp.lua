module(...,package.seeall)

--[[
ģ�����ƣ����Ź���
ģ�鹦�ܣ����ŷ��͡����Ž��ա����Ŷ�ȡ������ɾ��
ģ������޸�ʱ�䣺2017.02.20
]]

--���ý��ն��ŵĺ���
local sms_phone = "10086"

--[[
��������print
����  ����ӡ�ӿڣ����ļ��е����д�ӡ�������smsappǰ׺
����  ����
����ֵ����
]]
local function print(...)
	_G.print("smsapp",...)
end

-----------------------------------------���ŷ��͹��ܷ�װ[��ʼ]-----------------------------------------
--���ŷ��ͻ����������
local SMS_SEND_BUF_MAX_CNT = 10
--���ŷ��ͼ������λ����
local SMS_SEND_INTERVAL = 3000
--���ŷ��ͻ����
local tsmsnd = {}

--[[
��������sndnxt
����  �����Ͷ��ŷ��ͻ�����еĵ�һ������
����  ����
����ֵ����
]]
local function sndnxt()
	if #tsmsnd>0 then
		sms.send(tsmsnd[1].num,tsmsnd[1].data)
	end
end

--[[
��������sendcnf
����  ��SMS_SEND_CNF��Ϣ�Ĵ��������첽֪ͨ���ŷ��ͽ��
����  ��
        result�����ŷ��ͽ����trueΪ�ɹ���false����nilΪʧ��
����ֵ����
]]
local function sendcnf(result)
	print("sendcnf",result)
	local num,data,cb = tsmsnd[1].num,tsmsnd[1].data,tsmsnd[1].cb
	--�Ӷ��ŷ��ͻ�������Ƴ���ǰ����
	table.remove(tsmsnd,1)
	--����з��ͻص�������ִ�лص�
	if cb then cb(result,num,data) end
	--������ŷ��ͻ�����л��ж��ţ���SMS_SEND_INTERVAL����󣬼���������������
	if #tsmsnd>0 then sys.timer_start(sndnxt,SMS_SEND_INTERVAL) end
end

--[[
��������send
����  �����Ͷ���
����  ��
        num�����Ž��շ����룬ASCII���ַ�����ʽ
		data���������ݣ�UCS2��˸�ʽ��16�����ַ���
		cb�����ŷ��ͽ���첽����ʱʹ�õĻص���������ѡ
		idx��������ŷ��ͻ�����λ�ã���ѡ��Ĭ���ǲ���ĩβ
����ֵ������true����ʾ���ýӿڳɹ��������Ƕ��ŷ��ͳɹ������ŷ��ͽ����ͨ��sendcnf���أ������cb����֪ͨcb������������false����ʾ���ýӿ�ʧ��
]]
function send(num,data,cb,idx)
	--����������ݷǷ�
	if not num or num=="" or not data or data=="" then return end
	--���ŷ��ͻ��������
	if #tsmsnd>=SMS_SEND_BUF_MAX_CNT then return end
	--���ָ���˲���λ��
	if idx then
		table.insert(tsmsnd,idx,{num=num,data=data,cb=cb})
	--û��ָ������λ�ã����뵽ĩβ
	else
		table.insert(tsmsnd,{num=num,data=data,cb=cb})
	end
	--������ŷ��ͻ������ֻ��һ�����ţ������������ŷ��Ͷ���
	if #tsmsnd==1 then sms.send(num,data) return true end
end
-----------------------------------------���ŷ��͹��ܷ�װ[����]-----------------------------------------



-----------------------------------------���Ž��չ��ܷ�װ[��ʼ]-----------------------------------------
local function handle(num,data,datetime)
	print("handle",num,data,datetime)
	--�ظ���ͬ���ݵĶ��ŵ����ͷ�
	--if num then send(num,common.binstohexs(common.gb2312toucs2be(data))) end
end

--���Ž���λ�ñ�
local tnewsms = {}

--[[
��������readsms
����  ����ȡ���Ž���λ�ñ��еĵ�һ������
����  ����
����ֵ����
]]
local function readsms()
	if #tnewsms ~= 0 then
		sms.read(tnewsms[1])
	end
end

--[[
��������newsms
����  ��SMS_NEW_MSG_IND��δ�����Ż����¶��������ϱ�����Ϣ����Ϣ�Ĵ�����
����  ��
        pos�����Ŵ洢λ��
����ֵ����
]]
local function newsms(pos)
	--�洢λ�ò��뵽���Ž���λ�ñ���
	table.insert(tnewsms,pos)
	--���ֻ��һ�����ţ���������ȡ
	if #tnewsms == 1 then
		readsms()
	end
end

--[[
��������readcnf
����  ��SMS_READ_CNF��Ϣ�Ĵ��������첽���ض�ȡ�Ķ�������
����  ��
        result�����Ŷ�ȡ�����trueΪ�ɹ���false����nilΪʧ��
		num�����ź��룬ASCII���ַ�����ʽ
		data���������ݣ�UCS2��˸�ʽ��16�����ַ���
		pos�����ŵĴ洢λ�ã���ʱû��
		datetime���������ں�ʱ�䣬ASCII���ַ�����ʽ
		name�����ź����Ӧ����ϵ����������ʱû��
����ֵ����
]]
local function readcnf(result,num,data,pos,datetime,name)
	--���˺����е�86��+86
	local d1,d2 = string.find(num,"^([%+]*86)")
	if d1 and d2 then
		num = string.sub(num,d2+1,-1)
	end
	--ɾ������
	sms.delete(tnewsms[1])
	--�Ӷ��Ž���λ�ñ���ɾ���˶��ŵ�λ��
	table.remove(tnewsms,1)
	if data then
		--��������ת��ΪGB2312�ַ�����ʽ
		data = common.ucs2betogb2312(common.hexstobins(data))
		--�û�Ӧ�ó��������
		handle(num,data,datetime)
	end
	--������ȡ��һ������
	readsms()
end
-----------------------------------------���Ž��չ��ܷ�װ[����]-----------------------------------------

--����ģ����ڲ���Ϣ�����
local smsapp =
{
	SMS_NEW_MSG_IND = newsms, --�յ��¶��ţ�sms.lua���׳�SMS_NEW_MSG_IND��Ϣ
	SMS_READ_CNF = readcnf, --����sms.read��ȡ����֮��sms.lua���׳�SMS_READ_CNF��Ϣ
	SMS_SEND_CNF = sendcnf, --����sms.send���Ͷ���֮��sms.lua���׳�SMS_SEND_CNF��Ϣ
	SMS_READY = sndnxt, --�ײ����ģ��׼������
}

--ע����Ϣ������
sys.regapp(smsapp)



-----------------------------------------���ŷ��Ͳ���[��ʼ]-----------------------------------------
local function sendtest1(result,num,data)
	print("sendtest1",result,num,data)
end

local function sendtest2(result,num,data)
	print("sendtest2",result,num,data)
end

local function sendtest3(result,num,data)
	print("sendtest3",result,num,data)
end

local function sendtest4(result,num,data)
	print("sendtest4",result,num,data)
end

send(sms_phone,common.binstohexs(common.gb2312toucs2be("111111")),sendtest1)
send(sms_phone,common.binstohexs(common.gb2312toucs2be("��2������")),sendtest2)
send(sms_phone,common.binstohexs(common.gb2312toucs2be("qeiuqwdsahdkjahdkjahdkja122136489759725923759823hfdskfdkjnbzndkjhfskjdfkjdshfkjdsfks83478648732432qeiuqwdsahdkjahdkjahdkja122136489759725923759823hfdskfdkjnbzndkjhfskjdfkjdshfkjdsfks83478648732432qeiuqwdsahdkjahdkjahdkja122136489759725923759823hfdskfdkjnbzndkjhfskjdfkjdshfkjdsfks83478648732432")),sendtest3)
send(sms_phone,common.binstohexs(common.gb2312toucs2be("�����ǵ���qeiuqwdsahdkjahdkjahdkja122136489759725923759823hfdskfdkjnbzndkjhfskjdfkjdshfkjdsfks83478648732432qeiuqwdsahdkjahdkjahdkja122136489759725923759823hfdskfdkjnbzndkjhfskjdfkjdshfkjdsfks83478648732432qeiuqwdsahdkjahdkjahdkja122136489759725923759823hfdskfdkjnbzndkjhfskjdfkjdshfkjdsfks83478648732432")),sendtest4)
-----------------------------------------���ŷ��Ͳ���[����]-----------------------------------------
