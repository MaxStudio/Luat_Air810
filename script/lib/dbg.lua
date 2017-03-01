--[[
ģ�����ƣ��������
ģ�鹦�ܣ��ϱ�����ʱ�﷨���󡢽ű����Ƶ�����ԭ��
ģ������޸�ʱ�䣺2017.02.20
]]

--����ģ��,����������
local link = require"link"
module(...,package.seeall)


--prot,server,port�������Э��(TCP����UDP)����������ַ�Ͷ˿�
--FREQ���ϱ��������λ���룬���������Ϣ�ϱ���û���յ�OK�ظ�����ÿ���˼�������ϱ�һ��
--lid��socket id
local prot,server,port,FREQ,lid = "UDP","ota.airm2m.com",9072,1800000
--DBG_FILE�������ļ�·��
--resinf,inf��DBG_FILE�еĴ�����Ϣ��sys.lua��LIB_ERR_FILE�еĴ�����Ϣ
--luaerr��"/luaerrinfo.txt"�еĴ�����Ϣ
local DBG_FILE,resinf,inf,luaerr,d1,d2 = "/dbg.txt",""
--LIB_ERR_FILE���洢�ű�������ļ�·��
--liberr: "/lib_err.txt"�еĴ�����Ϣ
local LIB_ERR_FILE,liberr = "/lib_err.txt",""

--[[
��������writetxt
����  ����ȡ�ı��ļ��е�ȫ������
����  ��
		f���ļ�·��
����ֵ���ı��ļ��е�ȫ�����ݣ���ȡʧ��Ϊ���ַ�������nil
]]
local function readtxt(f)
	local file,rt = io.open(f,"r")
	if file == nil then
		print("dbg can not open file",f)
		return ""
	end
	rt = file:read("*a")
	file:close()
	return rt
end

--[[
��������writetxt
����  ��д�ı��ļ�
����  ��
		f���ļ�·��
		v��Ҫд����ı�����
����ֵ����
]]
local function writetxt(f,v)
	local file = io.open(f,"w")
	if file == nil then
		print("dbg open file to write err",f)
		return
	end
	local rt = file:write(v)
	if not rt then
		sys.removegpsdat()
		file:write(v)		
	end
	file:close()
end

local function writepara()
	if resinf then
		print("dbg_w",resinf)
		writetxt(DBG_FILE,resinf)
	end
end

local function initpara()
	inf = readtxt(DBG_FILE) or ""
	print("dbg inf",inf)
	liberr = readtxt(LIB_ERR_FILE) or ""
	--liberr = liberr..";poweron:"..rtos.poweron_reason()
end

--[[
��������getlasterr
����  ����ȡlua����ʱ���﷨����
����  ����
����ֵ����
]]
local function getlasterr()
	luaerr = readtxt("/luaerrinfo.txt") or ""
end

--[[
��������valid
����  ���Ƿ��д������Ϣ��Ҫ�ϱ�
����  ����
����ֵ��true��Ҫ�ϱ���false����Ҫ�ϱ�
]]
local function valid()
	return ((string.len(luaerr) > 0) or (string.len(inf) > 0) or (string.len(liberr) > 0)) and _G.PROJECT
end

--[[
��������snd
����  �����ʹ�����Ϣ����̨
����  ����
����ֵ����
]]
local function snd()
	local data = (luaerr or "") .. (inf or "")..(liberr or "")
	if string.len(data) > 0 then
		link.send(lid,_G.PROJECT .. "," .. (_G.VERSION and (_G.VERSION .. ",") or "") .. misc.getimei() .. "," .. data)
		sys.timer_start(snd,FREQ)
	end
end

local rests = ""

--���Ӻ�̨ʧ�ܺ����������
local reconntimes = 0
--[[
��������reconn
����  �����Ӻ�̨ʧ�ܺ���������
����  ����
����ֵ����
]]
local function reconn()
	if reconntimes < 3 then
		reconntimes = reconntimes+1
		link.connect(lid,prot,server,port)
	end
end

--[[
��������nofity
����  ��socket״̬�Ĵ�����
����  ��
        id��socket id��������Ժ��Բ�����
        evt����Ϣ�¼�����
		val�� ��Ϣ�¼�����
����ֵ����
]]
local function notify(id,evt,val)
	print("dbg notify",id,evt,val)
	if id ~= lid then return end
	if evt == "CONNECT" then
		if val == "CONNECT OK" then
			sys.timer_stop(reconn)
			reconntimes = 0
			rests = ""
			snd()
		else
			sys.timer_start(reconn,5000)
		end
	elseif evt == "STATE" and val == "CLOSED" then
		link.close(lid)
	end
end

--[[
��������recv
����  ��socket�������ݵĴ�����
����  ��
        id ��socket id��������Ժ��Բ�����
        data�����յ�������
����ֵ����
]]
local function recv(id,data)
	if data == "OK" then
		sys.timer_stop(snd)
		link.close(lid)
		resinf = ""
		inf = ""
		writepara()
		luaerr = ""
		liberr = ""
		os.remove("/luaerrinfo.txt")
		os.remove(LIB_ERR_FILE)
	end
end

--[[
��������init
����  ����ʼ��
����  ��
        id ��socket id��������Ժ��Բ�����
        data�����յ�������
����ֵ����
]]
local function init()
	--��ȡ�����ļ��еĴ���
	initpara()
	--��ȡlua����ʱ�﷨����
	getlasterr()
	if valid() then
		lid = link.open(notify,recv)
		link.connect(lid,prot,server,port)
	end
end

--[[
��������restart
����  ������
����  ��
        r������ԭ��
����ֵ����
]]
function restart(r)
	print("dbg restart:",r)
	resinf = "RST:" .. r .. ";"
	writepara()
	rtos.restart()	
end

local trcfile,trcflg,fd,res1,res2,res3 = "/dbg_trace.txt"

function rwriete(dat)
	local rt = fd:write(dat)
	if not rt then
		sys.removegpsdat()
		fd:write(dat)
	end
end

function savetrc(...)
	if not fd and trcflg then opntrc() end
	if fd then
		res1,res2,res3 = fd:seek("end")
		if res1 == nil then
			clstrc()
			opntrc()
			fd:seek("end")
		end
		rwriete(string.sub(misc.getclockstr(),5,12)..":")
		for i=1,arg.n do
			local o = arg[i]
			if type(o) == "number" then
				rwriete(o)
			elseif type(o) == "string" then
				rwriete(o)
			elseif type(o) == "boolean" then
				rwriete(tostring(o))
			elseif type(o) == "table" then
				rwriete("table")
			elseif type(o) == "nil" then
				rwriete("nil")
			end
			rwriete(",")
		end
		
		rwriete("\n")
	end	
end

function opntrc()
	if not fd then fd = io.open(trcfile,"a+") end
	if fd then
		trcflg = true
	end
	
	return fd
end

function clstrc()
	if fd then fd:close() end
	fd = nil
	trcflg = false
end

function deltrc()
	if fd then fd:close() end
	fd = nil
	os.remove(trcfile)
end

init()
