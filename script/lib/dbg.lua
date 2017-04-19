--[[
ģ�����ƣ��������
ģ�鹦�ܣ�������ʱ�﷨��������ԭ���ϴ�������
ģ������޸�ʱ�䣺2017.02.20
]]

--����ģ��,����������
local link = require"link"
local misc = require"misc"
module(...,package.seeall)

--FREQ���ϱ��������λ���룬���������Ϣ�ϱ���û���յ�OK�ظ�����ÿ���˼�������ϱ�һ��
--lid��socket id
--linksta������״̬��trueΪ���ӳɹ���falseΪʧ��
--prot,server,port�������Э��(TCP����UDP)����������ַ�Ͷ˿�
local FREQ,lid,linksta,prot,server,port = 1800000,0,false
--DBG_FILE�������ļ�·��
--resinf,inf��DBG_FILE�еĴ�����Ϣ��sys.lua��LIB_ERR_FILE�еĴ�����Ϣ
--luaerr��"/luaerrinfo.txt"�еĴ�����Ϣ
local DBG_FILE,resinf,inf,luaerr = "/dbg.txt",""
--LIB_ERR_FILE���洢�ű�������ļ�·��
--liberr: "/lib_err.txt"�еĴ�����Ϣ
local LIB_ERR_FILE,liberr = "/lib_err.txt",""

--[[
��������readtxt
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
	return rt or ""
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
��������rcvtimeout
����  �����ʹ�����Ϣ����̨�󣬳�ʱû���յ�OK�Ļظ�����ʱ������
����  ����
����ֵ����
]]
local function rcvtimeout()
	endntfy()
	link.close(lid)
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
		link.send(lid,_G.PROJECT .."_"..sys.getcorever() .. ",".. (_G.VERSION and (_G.VERSION .. ",") or "") .. misc.getimei() .. "," .. data)
		sys.timer_start(snd,FREQ)
		sys.timer_start(rcvtimeout,20000)
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
	else
		endntfy()
	end
end

--[[
��������endntfy
����  ��һ��dbg�������ڽ���
����  ����
����ֵ����
]]
function endntfy()
	sys.dispatch("DBG_END_IND")
	sys.timer_stop(sys.dispatch,"DBG_END_IND")
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
			linksta = true
			sys.timer_stop(reconn)
			reconntimes = 0
			rests = ""
			snd()
		else
			sys.timer_start(reconn,5000)
		end
	elseif evt=="DISCONNECT" or evt=="CLOSE" then
		linksta = false
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
	if string.upper(data) == "OK" then
		sys.timer_stop(snd)
		link.close(lid)
		resinf = ""
		inf = ""
		writepara()
		luaerr = ""
		liberr = ""
		os.remove("/luaerrinfo.txt")
		os.remove(LIB_ERR_FILE)
		endntfy()
		sys.timer_stop(rcvtimeout)
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
    if linksta then
      snd()
    else
      lid = link.open(notify,recv,"dbg")
      link.connect(lid,prot,server,port)
    end
    sys.dispatch("DBG_BEGIN_IND")
    sys.timer_start(sys.dispatch,120000,"DBG_END_IND")
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

--[[
��������setup
����  �����ô���Э�顢��̨��ַ�Ͷ˿�
����  ��
  inProt �������Э�飬��֧��TCP��UDP
  inAddr����̨��ַ
  inPort����̨�˿�
����ֵ����
]]
function setup(inProt,inAddr,inPort)
	if inProt and inAddr and inPort then
		prot,server,port = inProt,inAddr,inPort
		init()
	end
end
