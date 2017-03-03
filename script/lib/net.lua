--[[
ģ�����ƣ��������
ģ�鹦�ܣ��źŲ�ѯ��GSM����״̬��ѯ������ָʾ�ƿ��ơ��ٽ�С����Ϣ��ѯ
ģ������޸�ʱ�䣺2017.02.17
]]

--����ģ��,����������
local base = _G
local string = require"string"
local sys = require "sys"
local ril = require "ril"
local sim = require"sim"
module("net")

--���س��õ�ȫ�ֺ���������
local dispatch = sys.dispatch
local req = ril.request
local smatch = string.match
local tonumber,tostring = base.tonumber,base.tostring

--GSM����״̬��
--INIT��������ʼ���е�״̬
--REGISTERED��ע����GSM����
--UNREGISTER��δע����GSM����
local state,cengset = "INIT"

--lac��λ����ID
--ci��С��ID
--rssi���ź�ǿ��
local lac,ci,rssi = "","",0

--csqqrypriod���ź�ǿ�ȶ�ʱ��ѯ���
--cengqrypriod����ǰ���ٽ�С����Ϣ��ʱ��ѯ���
local csqqrypriod,cengqrypriod = 60*1000
--��ǰС�����ٽ�С����Ϣ��
local cellinfo = {}

--[[
��������creg
����  ������CREG��Ϣ
����  ��
		data��CREG��Ϣ�ַ���������+CREG: 2��+CREG: 1,"18be","93e1"��+CREG: 5,"18a7","cb51"
����ֵ����
]]
local function creg(data)
	local p1,s
	--��ȡע��״̬
	_,_,p1 = string.find(data,"%d,%s*(%d)")
	if p1 == nil then
		_,_,p1 = string.find(data,"(%d)")
		if p1 == nil then
			return
		end
	end
	--��ע��
	if p1 == "1" or p1 == "5" then
		s = "REGISTERED"
	--δע��
	else
		s = "UNREGISTER"
		-- req("AT+ESIMS?")
	end
	--ע��״̬�����˸ı�
	if s ~= state then
		--[[
		if not cengqrypriod and s == "REGISTERED" then
			setcengqueryperiod(60000)
		else
			cengquery()
		end
		--]]
		state = s
		dispatch("NET_STATE_CHANGED",s)
	end
	--��ע�Ტ��lac��ci�����˱仯
	if state == "REGISTERED" then
		local p2,p3 = string.match(data,"\"(%x+)\",%s*\"(%x+)\"")
		if lac ~= p2 or ci ~= p3 then
			lac = p2
			ci = p3
			--����һ���ڲ���ϢNET_CELL_CHANGED����ʾlac��ci�����˱仯
			dispatch("NET_CELL_CHANGED")
		end
		if not cengset then
			cengset = true
			req("AT+CENG=1")
		end
	end
end

--[[
��������resetcellinfo
����  �����õ�ǰС�����ٽ�С����Ϣ��
����  ����
����ֵ����
]]
local function resetcellinfo()
	local i
	cellinfo.cnt = 11 --������
	for i=1,cellinfo.cnt do
		cellinfo[i] = {}
		cellinfo[i].mcc,cellinfo[i].mnc = nil
		cellinfo[i].lac = 0
		cellinfo[i].ci = 0
		cellinfo[i].rssi = 0
		cellinfo[i].ta = 0
	end
end

--[[
��������ceng
����  ��������ǰС�����ٽ�С����Ϣ
����  ��
		data����ǰС�����ٽ�С����Ϣ�ַ��������������е�ÿһ�У�
		+CENG:1,1
		+CENG:0,"573,24,99,460,0,13,49234,10,0,6311,255"
		+CENG:1,"579,16,460,0,5,49233,6311"
		+CENG:2,"568,14,460,0,26,0,6311"
		+CENG:3,"584,13,460,0,10,0,6213"
		+CENG:4,"582,13,460,0,51,50146,6213"
		+CENG:5,"11,26,460,0,3,52049,6311"
		+CENG:6,"29,26,460,0,32,0,6311"
����ֵ����
]]
local function ceng(data)
	--ֻ������Ч��CENG��Ϣ
	if string.find(data,"%+CENG:%d+,.+") then
		local id,rssi,lac,ci,ta,mcc,mnc
		id = string.match(data,"%+CENG:(%d)")
		id = tonumber(id)
		mcc,mnc,lac,ci,rssi=string.match(data, "%+CENG:%d,(%w+),(%d+),(%d+),(%d+),%d+,(%d+)")
		
		--������ȷ
		if rssi and ci and lac and mcc and mnc then
			--����ǵ�һ���������Ϣ��
			if id == 0 then
				resetcellinfo()
			end
			--����mcc��mnc��lac��ci��rssi��ta
			cellinfo[id+1].mcc = tostring(tonumber(mcc,16))
			cellinfo[id+1].mnc = mnc
			cellinfo[id+1].lac = tonumber(lac)
			cellinfo[id+1].ci = tonumber(ci)
			cellinfo[id+1].rssi = ((tonumber(rssi) == 99) and 0 or tonumber(rssi))/2
			cellinfo[id+1].ta = tonumber(ta or "0")
			--����һ���ڲ���ϢCELL_INFO_IND����ʾ��ȡ�����µĵ�ǰС�����ٽ�С����Ϣ
			if id == 0 then
				dispatch("CELL_INFO_IND",cellinfo)
			end
		end
	end
end

--[[
��������neturc
����  ��������ģ���ڡ�ע��ĵײ�coreͨ�����⴮�������ϱ���֪ͨ���Ĵ���
����  ��
		data��֪ͨ�������ַ�����Ϣ
		prefix��֪ͨ��ǰ׺
����ֵ����
]]
local function neturc(data,prefix)
	if prefix == "+CREG" then
		req("AT+CSQ",nil,nil,nil,{skip=true}) -- �յ�����״̬�仯ʱ,����һ���ź�ֵ
		creg(data)
	elseif prefix == "+CENG" then
		ceng(data)
	end
end

--[[
��������getstate
����  ����ȡGSM����ע��״̬
����  ����
����ֵ��GSM����ע��״̬(INIT��REGISTERED��UNREGISTER)
]]
function getstate()
	return state
end

--[[
��������getmcc
����  ����ȡ��ǰС����mcc
����  ����
����ֵ����ǰС����mcc�������û��ע��GSM���磬�򷵻�sim����mcc
]]
function getmcc()
	return cellinfo[1].mcc or sim.getmcc()
end

--[[
��������getmnc
����  ����ȡ��ǰС����mnc
����  ����
����ֵ����ǰС����mnc�������û��ע��GSM���磬�򷵻�sim����mnc
]]
function getmnc()
	return cellinfo[1].mnc or sim.getmnc()
end

--[[
��������getlac
����  ����ȡ��ǰλ����ID
����  ����
����ֵ����ǰλ����ID(16�����ַ���������"18be")�������û��ע��GSM���磬�򷵻�""
]]
function getlac()
	return lac
end

--[[
��������getci
����  ����ȡ��ǰС��ID
����  ����
����ֵ����ǰС��ID(16�����ַ���������"93e1")�������û��ע��GSM���磬�򷵻�""
]]
function getci()
	return string.sub(ci,-4)
end

--[[
��������getrssi
����  ����ȡ�ź�ǿ��
����  ����
����ֵ����ǰ�ź�ǿ��(ȡֵ��Χ0-31)
]]
function getrssi()
	return rssi
end

--[[
��������getcell
����  ����ȡ��ǰ���ٽ�С���Լ��ź�ǿ�ȵ�ƴ���ַ���
����  ����
����ֵ����ǰ���ٽ�С���Լ��ź�ǿ�ȵ�ƴ���ַ��������磺49234.30.49233.23.49232.18.
]]
function getcell()
	local i,ret = 1,""
	for i=1,cellinfo.cnt do
		if cellinfo[i] and cellinfo[i].lac and cellinfo[i].lac ~= 0 and cellinfo[i].ci and cellinfo[i].ci ~= 0 then
			ret = ret..cellinfo[i].ci.."."..cellinfo[i].rssi.."."
		end
	end
	return ret
end

--[[
��������getcellinfo
����  ����ȡ��ǰ���ٽ�λ������С���Լ��ź�ǿ�ȵ�ƴ���ַ���
����  ����
����ֵ����ǰ���ٽ�λ������С���Լ��ź�ǿ�ȵ�ƴ���ַ��������磺6311.49234.30;6311.49233.23;6322.49232.18;
]]
function getcellinfo()
	local i,ret = 1,""
	for i=1,cellinfo.cnt do
		if cellinfo[i] and cellinfo[i].lac and cellinfo[i].lac ~= 0 and cellinfo[i].ci and cellinfo[i].ci ~= 0 then
			ret = ret..cellinfo[i].lac.."."..cellinfo[i].ci.."."..cellinfo[i].rssi..";"
		end
	end
	return ret
end

--[[
��������getcellinfoext
����  ����ȡ��ǰ���ٽ�λ������С����mcc��mnc���Լ��ź�ǿ�ȵ�ƴ���ַ���
����  ����
����ֵ����ǰ���ٽ�λ������С����mcc��mnc���Լ��ź�ǿ�ȵ�ƴ���ַ��������磺460.01.6311.49234.30;460.01.6311.49233.23;460.02.6322.49232.18;
]]
function getcellinfoext()
	local i,ret = 1,""
	for i=1,cellinfo.cnt do
		if cellinfo[i] and cellinfo[i].mcc and cellinfo[i].mnc and cellinfo[i].lac and cellinfo[i].lac ~= 0 and cellinfo[i].ci and cellinfo[i].ci ~= 0 then
			ret = ret..cellinfo[i].mcc.."."..cellinfo[i].mnc.."."..cellinfo[i].lac.."."..cellinfo[i].ci.."."..cellinfo[i].rssi..";"
		end
	end
	return ret
end

--[[
��������getta
����  ����ȡTAֵ
����  ����
����ֵ��TAֵ
]]
function getta()
	return cellinfo[1].ta
end

--[[
��������startquerytimer
����  ���պ������޹��ܣ�ֻ��Ϊ�˼���֮ǰд��Ӧ�ýű�
����  ����
����ֵ����
]]
function startquerytimer() end

--[[
��������simind
����  ���ڲ���ϢSIM_IND�Ĵ�����
����  ��
                id: ������
		para����������ʾSIM��״̬
����ֵ����
]]
local function SimInd(id,para)
	if para ~= "RDY" then
		state = "UNREGISTER"
		dispatch("NET_STATE_CHANGED",state)
	end
	if para == "NIST" then
		sys.timer_stop(queryfun)
	end

	return true
end

--[[
��������startcsqtimer
����  ����ѡ���Ե��������ź�ǿ�Ȳ�ѯ����ʱ��
����  ����
����ֵ����
]]
function startcsqtimer()
	req("AT+CSQ",nil,nil,nil,{skip=true})
	sys.timer_start(startcsqtimer,csqqrypriod)
end

--[[
��������startcengtimer
����  ����ѡ���Ե���������ǰ���ٽ�С����Ϣ��ѯ����ʱ��
����  ����
����ֵ����
]]
function startcengtimer()
	req("AT+ECELL")
	sys.timer_start(startcengtimer,cengqrypriod)
end

--[[
��������rsp
����  ��������ģ���ڡ�ͨ�����⴮�ڷ��͵��ײ�core�����AT�����Ӧ����
����  ��
		cmd����Ӧ���Ӧ��AT����
		success��AT����ִ�н����true����false
		response��AT�����Ӧ���е�ִ�н���ַ���
		intermediate��AT�����Ӧ���е��м���Ϣ
����ֵ����
]]
local function rsp(cmd,success,response,intermediate)
	local prefix = string.match(cmd,"AT(%+%u+)")

	if intermediate ~= nil then
		if prefix == "+CSQ" then
			local s = smatch(intermediate,"+CSQ:%s*(%d+)")
			if s ~= nil then
				rssi = tonumber(s)
				rssi = rssi == 99 and 0 or rssi
				--����һ���ڲ���ϢGSM_SIGNAL_REPORT_IND����ʾ��ȡ�����ź�ǿ��
				dispatch("GSM_SIGNAL_REPORT_IND",success,rssi)
			end
		elseif prefix == "+CENG" then
		end
	end
end

--[[
��������setcsqqueryperiod
����  �����á��ź�ǿ�ȡ���ѯ���
����  ��
		period����ѯ�������λ����
����ֵ����
]]
function setcsqqueryperiod(period)
	csqqrypriod = period
	startcsqtimer()
end

--[[
��������setcengqueryperiod
����  �����á���ǰ���ٽ�С����Ϣ����ѯ���
����  ��
		period����ѯ�������λ���롣���С�ڵ���0����ʾֹͣ��ѯ����
����ֵ����
]]
function setcengqueryperiod(period)
	if period ~= cengqrypriod then
		if period <= 0 then
			sys.timer_stop(startcengtimer)
		else
			cengqrypriod = period
			startcengtimer()
		end
	end
end

--[[
��������cengquery
����  ����ѯ����ǰ���ٽ�С����Ϣ��
����  ����
����ֵ����
]]
function cengquery()
	req("AT+ECELL")
end

--[[
��������csqquery
����  ����ѯ���ź�ǿ�ȡ�
����  ����
����ֵ����
]]
function csqquery()
	req("AT+CSQ",nil,nil,nil,{skip=true})
end

--ע����Ϣ��������
sys.regapp(SimInd,"SIM_IND")
--ע��+CREG��+CENG֪ͨ�Ĵ�����
ril.regurc("+CREG",neturc)
ril.regurc("+CENG",neturc)
--ע��AT+CCSQ�����Ӧ������
ril.regrsp("+CSQ",rsp)
req("AT+CREG=2")
req("AT+CREG?")
--req("AT+CENG=1")
-- 8����ѯ��һ��csq
sys.timer_start(startcsqtimer,8*1000)
resetcellinfo()
