--[[
ģ�����ƣ�publish�����ط�����
ģ�鹦�ܣ�QoSΪ1��publish�����ط�����
          ����publish���ĺ����DUP_TIME����û�յ�puback������Զ��ط�������ط�DUP_CNT�Σ������û�յ�puback�������ط����׳�MQTT_DUP_FAIL��Ϣ��Ȼ�����ñ���
ģ������޸�ʱ�䣺2017.02.24
]]

module(...,package.seeall)

--DUP_TIME������publish���ĺ�DUP_TIME�����ж���û���յ�puback
--DUP_CNT��û���յ�puback���ĵ�publish�����ط���������
--tlist��publish���Ĵ洢��
local DUP_TIME,DUP_CNT,tlist = 10,3,{}
local slen = string.len

--[[
��������print
����  ����ӡ�ӿڣ����ļ��е����д�ӡ�������mqttdupǰ׺
����  ����
����ֵ����
]]
local function print(...)
	_G.print("mqttdup",...)
end

--[[
��������timerfnc
����  ��1��Ķ�ʱ������������ѯtlist�е�publish�����Ƿ�ʱ����Ҫ�ط�
����  ����
����ֵ����
]]
local function timerfnc()
	print("timerfnc")
	for i=1,#tlist do
		print(i,tlist[i].tm)
		if tlist[i].tm > 0 then
			tlist[i].tm = tlist[i].tm-1
			if tlist[i].tm == 0 then
				sys.dispatch("MQTT_DUP_IND",tlist[i].dat)
			end
		end
	end
end

--[[
��������timer
����  ���������߹ر�1��Ķ�ʱ��
����  ��
		start���������߹رգ�true������false����nil�ر�
����ֵ����
]]
local function timer(start)
	print("timer",start,#tlist)
	if start then
		if not sys.timer_is_active(timerfnc) then
			sys.timer_loop_start(timerfnc,1000)
		end
	else
		if #tlist == 0 then sys.timer_stop(timerfnc) end
	end
end

--[[
��������ins
����  ������һ��publish���ĵ��洢��
����  ��
		typ�������Զ�������
		dat��publish��������
		seq��publish�������к�
����ֵ����
]]
function ins(typ,dat,seq)
	print("ins",typ,(slen(dat or "") > 200) and "" or common.binstohexs(dat),seq or "nil" or common.binstohex(seq))
	table.insert(tlist,{typ=typ,dat=dat,seq=seq,cnt=DUP_CNT,tm=DUP_TIME})
	timer(true)
end

--[[
��������rmv
����  ���Ӵ洢��ɾ��һ��publish����
����  ��
		typ�������Զ�������
		dat��publish��������
		seq��publish�������к�
����ֵ����
]]
function rmv(typ,dat,seq)
	print("rmv",typ or getyp(seq),(slen(dat or "") > 200) and "" or common.binstohexs(dat),seq or "nil" or common.binstohex(seq))
	for i=1,#tlist do
		if (not typ or typ == tlist[i].typ) and (not dat or dat == tlist[i].dat) and (not seq or seq == tlist[i].seq) then
			table.remove(tlist,i)
			break
		end
	end
	timer()
end

--[[
��������rmvall
����  ���Ӵ洢��ɾ������publish����
����  ����
����ֵ����
]]
function rmvall()
	tlist = {}
	timer()
end

--[[
��������rsm
����  ���ط�һ��publish���ĺ�Ļص�����
����  ��
		s��publish��������
����ֵ����
]]
function rsm(s)
	for i=1,#tlist do
		if tlist[i].dat == s then
			tlist[i].cnt = tlist[i].cnt - 1
			if tlist[i].cnt == 0 then
				sys.dispatch("MQTT_DUP_FAIL",tlist[i].typ,tlist[i].seq)
				rmv(nil,s) 
				return 
			end
			tlist[i].tm = DUP_TIME			
			break
		end
	end
end

--[[
��������getyp
����  ���������кŲ���publish�����û��Զ�������
����  ��
		seq��publish�������к�
����ֵ����
]]
function getyp(seq)
	for i=1,#tlist do
		if seq and seq == tlist[i].seq then
			return tlist[i].typ
		end
	end
end
