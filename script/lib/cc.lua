--[[
模块名称：通话管理
模块功能：呼入、呼出、接听、挂断
模块最后修改时间：2017.02.20
]]

--定义模块,导入依赖库
local base = _G
local string = require"string"
local sys = require"sys"
local ril = require"ril"
local net = require"net"
local pm = require"pm"
local dbg = require"dbg"
local table = require "table"
--local aud = require"audio"

module("cc")

--加载常用的全局函数至本地
local ipairs,pairs = base.ipairs,base.pairs
local dispatch = sys.dispatch
local req = ril.request
local print = base.print
local type = base.type

--底层通话模块是否准备就绪，true就绪，false或者nil未就绪
local ccready = true

--记录来电号码保证同一电话多次振铃只提示一次
local incoming_num = nil
--紧急号码表
local emergency_num = {"112", "911", "000", "08", "110", "119", "118", "999"}
--通话列表
local clcc,clccold,disc,chupflag = {},{},{},0

local function print(...)
	base.print("cc",...)
	dbg.savetrc("cc",...)
end

--[[
函数名：isemergencynum
功能  ：检查号码是否为紧急号码
参数  ：
		num：待检查号码
返回值：true为紧急号码，false不为紧急号码
]]
function isemergencynum(num)
	for k,v in ipairs(emergency_num) do
		if v == num then
			return true
		end
	end
	return false
end

--[[
函数名：clearincomingflag
功能  ：清除来电号码
参数  ：无
返回值：无
]]
local function clearincomingflag()
	print("clearincomingflag")
	incoming_num = nil
end

--[[
函数名：clearchupflag
功能  ：清除来电标志
参数  ：无
返回值：无
]]
local function clearchupflag()
    print("clearchupflag")
    chupflag = 0
end

--[[
函数名：qrylist
功能  ：查询通话列表
参数  ：无
返回值：无
]]
local function qrylist()
	print("qrylist")
    clcc = {}
    req("AT+CLCC")
end

--[[
函数名：FindCcById
功能  ：通过id查询通话
参数  ：
    id: 通话id值
    cctb: 通话列表
返回值：通话
]]
function FindCcById(id,cctb)  
	print("FindCcById")
    for k,v in pairs(cctb) do
		print(v.id,id,cctb[k])
	    if v.id == id then
	        return cctb[k]
	    end
    end
  
    return nil
end

local checkclcc=true
local function proclist()
    print("proclist",#clccold,#clcc)
    local k,v,isactive,cc,res,hasincoming

    if #clccold == 0 then
	    clccold = clcc
	    res = true--return
    end
    for k,v in pairs(clcc) do
		print("clcc",v.dir,v.sta,incoming_num,v.num)
	    if v.dir == "1" and (v.sta == "4" or v.sta == "5") and ((incoming_num and incoming_num ==v.num) or incoming_num==nil) then
            if incoming_num==nil then incoming_num=v.num end
            cc = FindCcById(v.id,clccold)
	        if not res and cc and cc.num ==v.num and (cc.sta == "4" or cc.sta == "5") then
                print("ljdcc proclist invalid CALL_INCOMING:",incoming_num,cc.sta,v.sta)
	        else
		        print("ljdcc proclist CALL_INCOMING:",incoming_num,#clccold,v.id)
		        if res then
                    dispatch("CALL_INCOMING",incoming_num,clccold,v.id)
                else
                    hasincoming={incoming_num,clccold,v.id}
                end
	        end
	    end
    end
    if res then return end
    for k,v in pairs(clccold) do
		print("clccold",v.id)
	    cc = FindCcById(v.id,clcc)
	    if cc == nil then
	        if #clccold>0 then
	            if #clccold>1 and checkclcc then
	                qrylist()
	                checkclcc = false
	                if hasincoming then--????¨2?a¨°?|ì??¨|???êo??o?3?|ì?¨a?¨o?à¨?Do?¨¨??ê?o?3?¨o?ì??¨1?ê?|ì¨2¨°????clcc?Did?a1|ì?¨a?§???¨o?o?3??ê?|ì¨2?t???clcc?Did?a1|ì?¨o?o?¨¨??ê?|ì¨2?t???clcc?¨￠1?1?¨¤??D?¨¨¨°a??|¨¤¨adisc????é?ê?¨°2¨°a??|¨¤¨aincoming????é?ê?¨???¨¨??|¨¤¨adisc????é
                        print("ljdcc real dispatch incom ",hasincoming[1],hasincoming[2],hasincoming[3])
                        dispatch("CALL_INCOMING",hasincoming[1],hasincoming[2],hasincoming[3])
                    end
	                return
	            else
    		        print("ljdcc proclist CALL_DISCONNECTED",disc[1] or "invalid reason")
    		        dispatch("CALL_DISCONNECTED",disc[1] or "invalid reason",clccold,v.id)
    		        chupflag,disc,checkclcc,incoming_num = 1,{},true
    		        sys.timer_start(clearchupflag,2000)
		        end
	        end
	  
	    else
	        if cc.dir == v.dir and cc.num ==v.num and cc.mode ==v.mode then
                print("ljdcc proclist CALL_CONNECTED = ",(cc.sta =="0" and v.sta ~="0"),cc.sta,v.sta)
			    if cc.sta =="0" and v.sta ~="0" then
			        dispatch("CALL_CONNECTED",clccold,v.id)
			    end
	        else
	            dispatch("CALL_DISCONNECTED",disc[1] or "invalid reason",clccold,v.id)
	            chupflag,disc,checkclcc,incoming_num = 1,{},true
                sys.timer_start(clearchupflag,2000)
		        print("ljdcc maybe someting err , cc.dir:",cc.dir,"v.dir:",v.dir,"cc.num:",cc.num,"v.num:",v.num,"cc.mode:",cc.mode,"v.mode:",v.mode) 	    
	        end
	    end
    end
    
    if hasincoming then--????¨2?a¨°?|ì??¨|???êo??o?3?|ì?¨a?¨o?à¨?Do?¨¨??ê?o?3?¨o?ì??¨1?ê?|ì¨2¨°????clcc?Did?a1|ì?¨a?§???¨o?o?3??ê?|ì¨2?t???clcc?Did?a1|ì?¨o?o?¨¨??ê?|ì¨2?t???clcc?¨￠1?1?¨¤??D?¨¨¨°a??|¨¤¨adisc????é?ê?¨°2¨°a??|¨¤¨aincoming????é?ê?¨???¨¨??|¨¤¨adisc????é
        print("ljdcc real dispatch incom ",hasincoming[1],hasincoming[2],hasincoming[3])
        dispatch("CALL_INCOMING",hasincoming[1],hasincoming[2],hasincoming[3])
    end
  
    clccold = clcc
end

local function discevt(reason)
	pm.sleep("cc")
	table.insert(disc,reason)
	print("ljdcc discevt reason:",reason,#clccold,#clcc)
	--dispatch("CALL_DISCONNECTED",reason)
	qrylist()
end

function anycallexist()
	return #clccold>0
end

--[[
函数名：dial
功能  ：呼叫一个号码
参数  ：
		number：号码
		delay：延时delay毫秒后，才发送at命令呼叫，默认不延时
返回值：无
]]
function dial(number,delay)
	if number == "" or number == nil then
		return false
	end

	if (ccready == false or net.getstate() ~= "REGISTERED") and not isemergencynum(number) then
		return false
	end

	pm.wake("cc")
	req(string.format("%s%s;","ATD",number),nil,nil,delay)
	qrylist()

	return true
end

function dropcallbyarg(statb,dir)
    if type(statb) ~= "table" or #statb==0 then
	    print("ljdcc dropcallbyarg err statb ind")
	    return
    end
    print("ljdcc dropcallbyarg ",#statb,dir,#clccold)
    for k,v in pairs(clccold) do
		print(dir,v.dir)
	    if v.dir==dir then
	        for i=1,#statb do
		        print("ljdcc dropcallbyarg ",statb[i],v.sta)
		        if v.sta == statb[i] then
		            req("AT+CHLD=1"..v.id)
		            print("ljdcc hangup:",v.num) 
					return true
		        end
	        end
	    end 
    end
end

--[[
函数名：hangup
功能  ：主动挂断所有通话
参数  ：无
返回值：无
]]
function hangup()
	--aud.stop()
	if #clccold==1 then
	    req("AT+CHUP")
	else
	    for k,v in pairs(clccold) do
	        if v.sta == "0" then 
		        req("AT+CHLD=1"..v.id)
		        print("ljdcc hangup:",v.num) 
		        break 
	        end
	    end
	end
end

--[[
函数名：accept
功能  ：接听来电
参数  ：无
返回值：无
]]
function accept()
	--aud.stop()
	req("ATA")
	pm.wake("cc")
end

--[[
函数名：ccurc
功能  ：本功能模块内“注册的底层core通过虚拟串口主动上报的通知”的处理
参数  ：
		data：通知的完整字符串信息
		prefix：通知的前缀
返回值：无
]]
local function ccurc(data,prefix)
    print("ljdcc ccurc:", prefix,data)
	--底层通话模块准备就绪
	if data == "CALL READY" then
		ccready = true
		dispatch("CALL_READY")
	--通话建立通知
	elseif data == "CONNECT" then
		qrylist()
		--dispatch("CALL_CONNECTED")
	--通话挂断通知
	elseif data == "NO CARRIER" or data == "BUSY" or data == "NO ANSWER" then
	    print("ljdcc ",data,chupflag,#clccold,#clcc)
	    if #clccold==0 and #clcc==0 then
	        return
	    end
		discevt(data)
	--来电振铃
	elseif prefix == "+CLIP" then
	    print("ljdcc CLIP CALL_INCOMING",incoming_num,"chupflag:",chupflag)
		local number = string.match(data,"\"(%+*%d*)\"",string.len(prefix)+1)
		if incoming_num ~= number then
			incoming_num = number
			if chupflag==1 then
			  sys.timer_start(qrylist,1500)
			else
			  qrylist()
			end
			--dispatch("CALL_INCOMING",number)
		end
	--通话列表信息
	elseif prefix == "+CLCC" then
		local id,dir,sta,mode,mpty,num = string.match(data,"%+CLCC:%s*(%d+),(%d),(%d),(%d),(%d),\"(%+*%d*)\"")
		if id then
		    local cc=FindCcById(id,clcc)
		    if cc== nil then
			    table.insert(clcc,{id=id,dir=dir,sta=sta,mode=mode,mpty=mpty,num=num})
			else
			    cc.dir,cc.sta,cc.mode,cc.mpty,cc.num = dir,sta,mode,mpty,num
			end		
		end
	end
end

--[[
函数名：ccrsp
功能  ：本功能模块内“通过虚拟串口发送到底层core软件的AT命令”的应答处理
参数  ：
		cmd：此应答对应的AT命令
		success：AT命令执行结果，true或者false
		response：AT命令的应答中的执行结果字符串
		intermediate：AT命令的应答中的中间信息
返回值：无
]]
local function ccrsp(cmd,success,response,intermediate)
	local prefix = string.match(cmd,"AT(%+*%u+)")
	print("ljdcc ccrsp",prefix,cmd,success,response,intermediate)
	--拨号应答
	if prefix == "D" then
		if not success then
			discevt("CALL_FAILED")
		end
	--挂断所有通话应答
	elseif prefix == "+CHUP" then
		discevt("LOCAL_HANG_UP")
	elseif prefix == "+CLCC" then
	    proclist()
    elseif prefix=='+CHLD' and (response=='ERROR' or response=='NO ANSWER') then
    	qrylist()
	--接听来电应答
	elseif prefix == "A" then
		incoming_num = nil
		qrylist()
		--dispatch("CALL_CONNECTED")
	end
end

--注册以下通知的处理函数
ril.regurc("CALL READY",ccurc)
ril.regurc("CONNECT",ccurc)
ril.regurc("NO CARRIER",ccurc)
ril.regurc("NO ANSWER",ccurc)
ril.regurc("BUSY",ccurc)
ril.regurc("+CLIP",ccurc)
ril.regurc("+CLCC",ccurc)

--注册以下AT命令的应答处理函数
ril.regrsp("D",ccrsp)
ril.regrsp("A",ccrsp)
ril.regrsp("+CHUP",ccrsp)
ril.regrsp("+CLCC",ccrsp)
ril.regrsp("+CHLD",ccrsp)
--开启拨号音,忙音检测
req("ATX4")
--开启来电urc上报
req("AT+CLIP=1")
