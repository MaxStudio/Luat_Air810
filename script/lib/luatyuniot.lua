--����ģ��,����������
local base = _G
local sys  = require"sys"
local mqtt = require"mqtt"
local misc = require"misc"
require"aliyuniotauth"
module(...,package.seeall)

--�������ϴ�����key��secret���û���Ҫ�޸�������ֵ�������޷�������Luat���ƺ�̨
local PRODUCT_KEY,PRODUCT_SECRET = "1000163201","4K8nYcT4Wiannoev"
--mqtt�ͻ��˶���,���ݷ�������ַ,���ݷ������˿ڱ�
local mqttclient,gaddr,gports,gclientid,gusername
--Ŀǰʹ�õ�gport���е�index
local gportidx = 1
local gconnectedcb,gconnecterrcb,grcvmessagecb

--[[
��������print
����  ����ӡ�ӿڣ����ļ��е����д�ӡ�������luatyuniotǰ׺
����  ����
����ֵ����
]]
local function print(...)
	base.print("luatyuniot",...)
end

--[[
��������subackcb
����  ��MQTT SUBSCRIBE֮���յ�SUBACK�Ļص�����
����  ��
		usertag������mqttclient:subscribeʱ�����usertag
		result��true��ʾ���ĳɹ���false����nil��ʾʧ��
����ֵ����
]]
local function subackcb(usertag,result)
	print("subackcb",usertag,result)
end

--[[
��������sckerrcb
����  ��SOCKETʧ�ܻص�����
����  ��
		r��string���ͣ�ʧ��ԭ��ֵ
			CONNECT��mqtt�ڲ���socketһֱ����ʧ�ܣ����ٳ����Զ�����
����ֵ����
]]
local function sckerrcb(r)
	print("sckerrcb",r,gportidx,#gports)
	if r=="CONNECT" then
		if gportidx<#gports then
			gportidx = gportidx+1
			connect(true)
		else
			sys.restart("luatyuniot sck connect err")
		end
	end
end

--[[
��������connectedcb
����  ��MQTT CONNECT�ɹ��ص�����
����  ����		
����ֵ����
]]
local function connectedcb()
	print("connectedcb")
	--��������
	mqttclient:subscribe({{topic="/"..PRODUCT_KEY.."/"..misc.getimei().."/get",qos=0}, {topic="/"..PRODUCT_KEY.."/"..misc.getimei().."/get",qos=1}}, subackcb, "subscribegetopic")
	assert(_G.PRODUCT_KEY and _G.PROJECT and _G.VERSION,"undefine PRODUCT_KEY or PROJECT or VERSION in main.lua")
	local tpayload = {cmd="0",ProductKey=_G.PRODUCT_KEY,IMEI=misc.getimei(),DeviceSecret=misc.getsn(),ICCID=sim.geticcid(),imsi=sim.getimsi(),project=_G.PROJECT,version=_G.VERSION}
	mqttclient:publish("/"..PRODUCT_KEY.."/"..misc.getimei().."/v1/LuatInside",json.encode(tpayload),1)
	--ע���¼��Ļص�������MESSAGE�¼���ʾ�յ���PUBLISH��Ϣ
	mqttclient:regevtcb({MESSAGE=grcvmessagecb})
	if gconnectedcb then gconnectedcb() end
end

--[[
��������connecterrcb
����  ��MQTT CONNECTʧ�ܻص�����
����  ��
		r��ʧ��ԭ��ֵ
			1��Connection Refused: unacceptable protocol version
			2��Connection Refused: identifier rejected
			3��Connection Refused: server unavailable
			4��Connection Refused: bad user name or password
			5��Connection Refused: not authorized
����ֵ����
]]
local function connecterrcb(r)
	print("connecterrcb",r)
	if gconnecterrcb then gconnecterrcb(r) end
end


function connect(change)
	if change then
		mqttclient:change("TCP",gaddr,gports[gportidx])
	else
		--����һ��mqtt client
		mqttclient = mqtt.create("TCP",gaddr,gports[gportidx])
	end
	--������������,�������Ҫ��������һ�д��룬���Ҹ����Լ����������will����
	--mqttclient:configwill(1,0,0,"/willtopic","will payload")
	--����mqtt������
	mqttclient:connect(gclientid,600,gusername,"",connectedcb,connecterrcb,sckerrcb)
end

--[[
��������databgn
����  ����Ȩ��������֤�ɹ��������豸�������ݷ�����
����  ����		
����ֵ����
]]
local function databgn(host,ports,clientid,username)
	gaddr,gports,gclientid,gusername = host or gaddr,ports or gports,clientid,username
	gportidx = 1
	connect()
end

local procer =
{
	ALIYUN_DATA_BGN = databgn,
}

sys.regapp(procer)


--[[
��������config
����  �����ð�������������Ʒ��Ϣ���豸��Ϣ
����  ��
		productkey��string���ͣ���Ʒ��ʶ����ѡ����
		productsecret��string���ͣ���Ʒ��Կ����ѡ����
����ֵ����
]]
local function config(productkey,productsecret)
	sys.dispatch("ALIYUN_AUTH_BGN",productkey,productsecret)
end

function regcb(connectedcb,rcvmessagecb,connecterrcb)
	gconnectedcb,grcvmessagecb,gconnecterrcb = connectedcb,rcvmessagecb,connecterrcb
end

function publish(payload,qos,ackcb,usertag)
	mqttclient:publish("/"..PRODUCT_KEY.."/"..misc.getimei().."/update",payload,qos,ackcb,usertag)
end

config(PRODUCT_KEY,PRODUCT_SECRET)
