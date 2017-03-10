module(...,package.seeall)

--[[
����ʱ���Լ��ķ������������޸������PROT��ADDR��PORT 
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
--reconning:�Ƿ��ڳ�������
local reconncnt,reconncyclecnt,reconning = 0,0
--KEEP_ALIVE_TIME��mqtt����ʱ��
--rcvs���Ӻ�̨�յ�������
local KEEP_ALIVE_TIME,rcvs = 600,""

--[[
Ŀǰֻ֧��QoS=0��QoS=1����֧��QoS=2
topic��client identifier��user��passwordֻ֧��ascii�ַ���

�������£�
1���ն˶�����"/v1/device/"..misc.getimei().."/devparareq/+"��"/v1/device/"..misc.getimei().."/deveventreq/+"�������⣬�ο�����mqttsubdata
2�������Ϻ�̨���ն�ÿ��1���ӷֱ�ᷢ��һ��qosΪ0��1��PUBLISH���ģ��ο�loc0snd��loc1snd
]]

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
��������enpwd
����  ��MQTT CONNECT������password�ֶ��õ��ļ����㷨
����  ��
		s��ascii�ַ���
����ֵ�����ܺ��ascii�ַ���
]]
local function enpwd(s)
	local tmp,ret,i = 0,""
	for i=1,string.len(s) do
		tmp = bit.bxor(tmp,string.byte(s,i))
		if i % 3 == 0 then
			ret = ret..schar(tmp)
			tmp = 0
		end
	end
	return common.binstohexs(ret)
end

--[[
��������mqttconncb
����  ������MQTT CONNECT���ĺ���첽�ص�����
����  ��		
		result�� bool���ͣ����ͽ����trueΪ�ɹ�������Ϊʧ��
		data��MQTT CONNECT��������
����ֵ����
]]
function mqttconncb(result,data)
	--��MQTT CONNECT�������ݱ��������������ʱDUP_TIME����û���յ�CONNACK����CONNACK����ʧ�ܣ�����Զ��ط�CONNECT����
	--�ط��Ĵ���������mqttdup.lua��
	mqttdup.ins(tmqttpack["MQTTCONN"].mqttduptyp,data)
end

--[[
��������mqttconndata
����  �����MQTT CONNECT��������
����  ����		
����ֵ��CONNECT�������ݺͱ��Ĳ���
]]
function mqttconndata()
	return mqtt.pack(mqtt.CONNECT,KEEP_ALIVE_TIME,misc.getimei(),misc.getimei(),enpwd(misc.getimei()))
end

--[[
��������mqttsubcb
����  ������MQTT SUBSCRIBE���ĺ���첽�ص�����
����  ��		
		result�� bool���ͣ����ͽ����trueΪ�ɹ�������Ϊʧ��
		v��SUBSCRIBE���ĵĲ�����table����{dup=true,topic=mqttsubdata�����ʱ��topic,seq=mqttsubdata�����ʱ���ɵ����к�}
����ֵ����
]]
function mqttsubcb(result,v)
	--���·�װMQTT SUBSCRIBE���ģ��ظ���־��Ϊtrue�����кź�topic������ԭʼֵ�����ݱ��������������ʱDUP_TIME����û���յ�SUBACK������Զ��ط�SUBSCRIBE����
	--�ط��Ĵ���������mqttdup.lua��
	mqttdup.ins(tmqttpack["MQTTSUB"].mqttduptyp,mqtt.pack(mqtt.SUBSCRIBE,v),v.seq)
end

--[[
��������mqttsubdata
����  �����MQTT SUBSCRIBE��������
����  ����		
����ֵ��SUBSCRIBE�������ݺͱ��Ĳ���
]]
function mqttsubdata()
	return mqtt.pack(mqtt.SUBSCRIBE,{topic={"/v1/device/"..misc.getimei().."/devparareq/+", "/v1/device/"..misc.getimei().."/deveventreq/+"}})
end

--[[
��������mqttdiscb
����  ������MQTT DICONNECT���ĺ���첽�ص�����
����  ��		
		result�� bool���ͣ����ͽ����trueΪ�ɹ�������Ϊʧ��
		v��DICONNECT���ĵĲ�����Ŀǰ�̶�Ϊ"MQTTDISC"��������
����ֵ����
]]
function mqttdiscb(result,v)
	--�ر�socket����
	linkapp.sckdisc(SCK_IDX)
end

--[[
��������mqttdiscdata
����  �����MQTT DISCONNECT��������
����  ����		
����ֵ��DISCONNECT�������ݺͱ��Ĳ���
]]
function mqttdiscdata()
	return mqtt.pack(mqtt.DISCONNECT)
end

--[[
��������disconnect
����  ������MQTT DISCONNECT����
����  ����		
����ֵ����
]]
local function disconnect()
	mqttsnd("MQTTDISC")
end

--[[
��������mqttpingreqdata
����  �����MQTT PINGREQ��������
����  ����		
����ֵ��PINGREQ�������ݺͱ��Ĳ���
]]
function mqttpingreqdata()
	return mqtt.pack(mqtt.PINGREQ)
end

--[[
��������pingreq
����  ������MQTT PINGREQ����
����  ����		
����ֵ����
]]
local function pingreq()
	mqttsnd("MQTTPINGREQ")
	if not sys.timer_is_active(disconnect) then
		--������ʱ�����������ʱ��+30���ڣ�û���յ�pingrsp������MQTT DISCONNECT����
		sys.timer_start(disconnect,(KEEP_ALIVE_TIME+30)*1000)
	end
end

--[[
��������mqttpubloc0cb
����  ������qosΪ0��MQTT PUBLISH���ĺ���첽�ص�����
����  ��		
		result�� bool���ͣ����ͽ����trueΪ�ɹ�������Ϊʧ��
		v��PUBLISH���ĵĲ�����Ŀǰ�̶�Ϊ"MQTTPUBLOC0"��������
����ֵ����
]]
function mqttpubloc0cb(result,v)
	--������ʱ����60����ٴη���qosΪ0��PULISH����
	sys.timer_start(loc0snd,60000)
end

--[[
��������mqttpubloc0data
����  �����qosΪ0��MQTT PUBLISH��������
����  ����		
����ֵ��PUBLISH�������ݺͱ��Ĳ���
]]
function mqttpubloc0data()
	return mqtt.pack(mqtt.PUBLISH,{qos=0,topic="/v1/device/"..misc.getimei().."/devdata",payload="loc data0"})
end

--[[
��������loc0snd
����  ������qosΪ0��MQTT PUBLISH����
����  ����		
����ֵ����
]]
function loc0snd()
	mqttsnd("MQTTPUBLOC0")
end


--[[
��������mqttpubloc1cb
����  ������qosΪ1��MQTT PUBLISH���ĺ���첽�ص�����
����  ��		
		result�� bool���ͣ����ͽ����trueΪ�ɹ�������Ϊʧ��
		v��PUBLISH���ĵĲ�����table����{dup=true,topic=mqttpubloc1data�����ʱ��topic,seq=mqttpubloc1data�����ʱ���ɵ����к�,payload=mqttpubloc1data�����ʱ��payload}
����ֵ����
]]
function mqttpubloc1cb(result,v)
	--������ʱ����60����ٴη���qosΪ1��PULISH����
	sys.timer_start(loc1snd,60000)
	--���·�װMQTT PUBLISH���ģ��ظ���־��Ϊtrue�����кš�topic��payload������ԭʼֵ�����ݱ��������������ʱDUP_TIME����û���յ�PUBACK������Զ��ط�PUBLISH����
	--�ط��Ĵ���������mqttdup.lua��
	mqttdup.ins(tmqttpack["MQTTPUBLOC1"].mqttduptyp,mqtt.pack(mqtt.PUBLISH,v),v.seq)
end

--[[
��������mqttpubloc1data
����  �����qosΪ1��MQTT PUBLISH��������
����  ����		
����ֵ��PUBLISH�������ݺͱ��Ĳ���
]]
function mqttpubloc1data()
	return mqtt.pack(mqtt.PUBLISH,{qos=1,topic="/v1/device/"..misc.getimei().."/devdata",payload="loc data1"})
end

--[[
��������loc1snd
����  ������qosΪ1��MQTT PUBLISH����
����  ����		
����ֵ����
]]
function loc1snd()
	mqttsnd("MQTTPUBLOC1")
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

--mqttӦ�ñ��ı�
tmqttpack =
{
	MQTTCONN = {sndpara="MQTTCONN",mqttyp=mqtt.CONNECT,mqttduptyp="CONN",mqttdatafnc=mqttconndata,sndcb=mqttconncb},
	MQTTSUB = {sndpara="MQTTSUB",mqttyp=mqtt.SUBSCRIBE,mqttduptyp="SUB",mqttdatafnc=mqttsubdata,sndcb=mqttsubcb},
	MQTTPINGREQ = {sndpara="MQTTPINGREQ",mqttyp=mqtt.PINGREQ,mqttdatafnc=mqttpingreqdata},
	MQTTDISC = {sndpara="MQTTDISC",mqttyp=mqtt.DISCONNECT,mqttdatafnc=mqttdiscdata,sndcb=mqttdiscb},
	MQTTPUBLOC0 = {sndpara="MQTTPUBLOC0",mqttyp=mqtt.PUBLISH,mqttdatafnc=mqttpubloc0data,sndcb=mqttpubloc0cb},
	MQTTPUBLOC1 = {sndpara="MQTTPUBLOC1",mqttyp=mqtt.PUBLISH,mqttdatafnc=mqttpubloc1data,sndcb=mqttpubloc1cb},
}

local function getidbysndpara(para)
	for k,v in pairs(tmqttpack) do
		if v.sndpara==para then return k end
	end
end

--[[
��������mqttsnd
����  ��MQTT���ķ����ܽӿڣ����ݱ������ͣ���mqttӦ�ñ��ı����ҵ����������Ȼ��������
����  ��
        typ����������
����ֵ����
]]
function mqttsnd(typ)
	if not tmqttpack[typ] then print("mqttsnd typ error",typ) return end
	local mqttyp = tmqttpack[typ].mqttyp
	local dat,para = tmqttpack[typ].mqttdatafnc()
	
	if mqttyp==mqtt.CONNECT then
		if tmqttpack[typ].mqttduptyp then mqttdup.rmv(tmqttpack[typ].mqttduptyp) end
		if not snd(dat,tmqttpack[typ].sndpara) and tmqttpack[typ].sndcb then
			tmqttpack[typ].sndcb(false,dat)
		end
	elseif mqttyp==mqtt.SUBSCRIBE then
		if tmqttpack[typ].mqttduptyp then mqttdup.rmv(tmqttpack[typ].mqttduptyp) end
		if not snd(dat,{typ=tmqttpack[typ].sndpara,val=para}) and tmqttpack[typ].sndcb then
			tmqttpack[typ].sndcb(false,para)
		end
	elseif mqttyp==mqtt.PINGREQ then
		snd(dat,tmqttpack[typ].sndpara)
	elseif mqttyp==mqtt.DISCONNECT then
		if not snd(dat,tmqttpack[typ].sndpara) and tmqttpack[typ].sndcb then
			tmqttpack[typ].sndcb(false,tmqttpack[typ].sndpara)
		end
	elseif mqttyp==mqtt.PUBLISH then
		if typ=="MQTTPUBLOC0" then
			if not snd(dat,tmqttpack[typ].sndpara) and tmqttpack[typ].sndcb then
				tmqttpack[typ].sndcb(false,tmqttpack[typ].sndpara)
			end
		elseif typ=="MQTTPUBLOC1" then
			if not snd(dat,{typ=tmqttpack[typ].sndpara,val=para}) and tmqttpack[typ].sndcb then
				tmqttpack[typ].sndcb(false,para)
			end
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
function ntfy(idx,evt,result,item,rspstr)
	print("ntfy",evt,result,item)
	--���ӽ��
	if evt == "CONNECT" then
		reconning = false
		--���ӳɹ�
		if result then
			reconncnt,reconncyclecnt,linksta,rcvs = 0,0,true,""
			--ֹͣ������ʱ��
			sys.timer_stop(reconn)
			--����mqtt connect����
			mqttsnd("MQTTCONN")			
		--����ʧ��
		else
			--5�������
			sys.timer_start(reconn,RECONN_PERIOD*1000)
		end	
	--���ݷ��ͽ��
	elseif evt == "SEND" then
		if not result and rspstr and smatch(rspstr,"ERROR") then
			link.shut()
		else
			if item.para then
				if item.para=="MQTTDUP" then
					mqttdupcb(result,item.data)
				else
					local id = getidbysndpara(type(item.para) == "table" and item.para.typ or item.para)
					local val = type(item.para) == "table" and item.para.val or item.data
					print("item.para",type(item.para) == "table",type(item.para) == "table" and item.para.typ or item.para,id)
					if id and tmqttpack[id].sndcb then tmqttpack[id].sndcb(result,val) end
				end
			end
		end
	--���ӱ����Ͽ�
	elseif (evt == "STATE" and result == "CLOSED") or evt == "DISCONNECT" then
		sys.timer_stop(pingreq)
		sys.timer_stop(loc0snd)
		sys.timer_stop(loc1snd)
		mqttdup.rmvall()
		rcvs,linksta,mqttconn = ""
		reconn()			
	end
	--�����������Ͽ�������·����������
	if smatch((type(result)=="string") and result or "","ERROR") then
		link.shut()
	end
end

--[[
��������connack
����  ������������·���MQTT CONNACK����
����  ��
        packet��������ı��ĸ�ʽ��table����{suc=�Ƿ����ӳɹ�}
����ֵ����
]]
local function connack(packet)
	print("connack",packet.suc)
	if packet.suc then
		mqttconn = true
		mqttdup.rmv(tmqttpack["MQTTCONN"].mqttduptyp)
		
		--��������
		mqttsnd("MQTTSUB")
	end
end

--[[
��������suback
����  ������������·���MQTT SUBACK����
����  ��
        packet��������ı��ĸ�ʽ��table����{seq=��Ӧ��SUBSCRIBE�������к�}
����ֵ����
]]
local function suback(packet)
	print("suback",common.binstohexs(packet.seq))
	mqttdup.rmv(tmqttpack["MQTTSUB"].mqttduptyp,nil,packet.seq)
	loc0snd()
	loc1snd()
end

--[[
��������puback
����  ������������·���MQTT PUBACK����
����  ��
        packet��������ı��ĸ�ʽ��table����{seq=��Ӧ��PUBLISH�������к�}
����ֵ����
]]
local function puback(packet)	
	local typ = mqttdup.getyp(packet.seq) or ""
	print("puback",common.binstohexs(packet.seq),typ)
	mqttdup.rmv(nil,nil,packet.seq)
end

--[[
��������svrpublish
����  ������������·���MQTT PUBLISH����
����  ��
        mqttpacket��������ı��ĸ�ʽ��table����{qos=,topic,seq,payload}
����ֵ����
]]
local function svrpublish(mqttpacket)
	print("svrpublish",mqttpacket.topic,mqttpacket.seq,mqttpacket.payload)	
	if mqttpacket.qos == 1 then snd(mqtt.pack(mqtt.PUBACK,mqttpacket.seq)) end	
end

--[[
��������pingrsp
����  ������������·���MQTT PINGRSP����
����  ����
����ֵ����
]]
local function pingrsp()
	sys.timer_stop(disconnect)
end

--�������·����Ĵ����
mqttcmds = {
	[mqtt.CONNACK] = connack,
	[mqtt.SUBACK] = suback,
	[mqtt.PUBACK] = puback,
	[mqtt.PUBLISH] = svrpublish,
	[mqtt.PINGRSP] = pingrsp,
}

--[[
��������datinactive
����  ������ͨ���쳣����
����  ����
����ֵ����
]]
local function datinactive()
    dbg.restart("SVRNODATA")
end

--[[
��������checkdatactive
����  �����¿�ʼ��⡰����ͨ���Ƿ��쳣��
����  ����
����ֵ����
]]
local function checkdatactive()
	sys.timer_start(datinactive,KEEP_ALIVE_TIME*1000*3+30000) --3������ʱ��+�����
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
	print("rcv",slen(data)>200 and slen(data) or common.binstohexs(data))
	sys.timer_start(pingreq,KEEP_ALIVE_TIME*1000/2)
	rcvs = rcvs..data

	local f,h,t = mqtt.iscomplete(rcvs)

	while f do
		data = ssub(rcvs,h,t)
		rcvs = ssub(rcvs,t+1,-1)
		local packet = mqtt.unpack(data)
		if packet and packet.typ and mqttcmds[packet.typ] then
			mqttcmds[packet.typ](packet)
			if packet.typ ~= mqtt.CONNACK and packet.typ ~= mqtt.SUBACK then
				checkdatactive()
			end
		end
		f,h,t = mqtt.iscomplete(rcvs)
	end
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

--[[
��������connect
����  ��mqttdup�д������ط����ķ��ͺ���첽�ص�
����  ��
		result�� bool���ͣ����ͽ����trueΪ�ɹ�������Ϊʧ��
		v����������
����ֵ����
]]
function mqttdupcb(result,v)
	mqttdup.rsm(v)
end

--[[
��������mqttdupind
����  ��mqttdup�д������ط����Ĵ���
����  ��
		s����������
����ֵ����
]]
local function mqttdupind(s)
	if not snd(s,"MQTTDUP") then mqttdupcb(false,s) end
end

--[[
��������mqttdupfail
����  ��mqttdup�д������ط����ģ�������ط������ڣ�������ʧ�ܵ�֪ͨ��Ϣ����
����  ��
		t�����ĵ��û��Զ�������
		s����������
����ֵ����
]]
local function mqttdupfail(t,s)
    
end

--mqttdup�ط���Ϣ��������
local procer =
{
	MQTT_DUP_IND = mqttdupind,
	MQTT_DUP_FAIL = mqttdupfail,
}
--ע����Ϣ�Ĵ�����
sys.regapp(procer)

connect()
checkdatactive()
