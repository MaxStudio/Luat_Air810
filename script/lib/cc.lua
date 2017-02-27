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

local ipairs,pairs = base.ipairs,base.pairs
local dispatch = sys.dispatch
local req = ril.request
local print = base.print
local type = base.type

--local
local ccready = true

local incoming_num = nil -- 记录来电号码保证同一电话多次振铃只提示一次
local emergency_num = {"112", "911", "000", "08", "110", "119", "118", "999"}
local clcc,clccold,disc,chupflag = {},{},{},0

local function print(...)
	base.print("cc",...)
	dbg.savetrc("cc",...)
end

function isemergencynum(num)
	for k,v in ipairs(emergency_num) do
		if v == num then
			return true
		end
	end
	return false
end

local function clearincomingflag()
	print("clearincomingflag")
	incoming_num = nil
end

local function clearchupflag()
    print("clearchupflag")
    chupflag = 0
end

local function qrylist()
	print("qrylist")
    clcc = {}
    req("AT+CLCC")
end

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
	                if hasincoming then--存在这一的情况：刚呼出的同时有呼入，呼出失败，第一次clcc中id为1的通话是呼出，第二次clcc中id为1的是呼入，第二次clcc结果锅里中既要处理disc消息，也要处理incoming消息，优先处理disc消息
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
    
    if hasincoming then--存在这一的情况：刚呼出的同时有呼入，呼出失败，第一次clcc中id为1的通话是呼出，第二次clcc中id为1的是呼入，第二次clcc结果锅里中既要处理disc消息，也要处理incoming消息，优先处理disc消息
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

function accept()
	--aud.stop()
	req("ATA")
	pm.wake("cc")
end

local function ccurc(data,prefix)
    print("ljdcc ccurc:", prefix,data)
	if data == "CALL READY" then
		ccready = true
		dispatch("CALL_READY")
	elseif data == "CONNECT" then
		qrylist()
		--dispatch("CALL_CONNECTED")
	elseif data == "NO CARRIER" or data == "BUSY" or data == "NO ANSWER" then
	    print("ljdcc ",data,chupflag,#clccold,#clcc)
	    if #clccold==0 and #clcc==0 then
	        return
	    end
		discevt(data)
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

local function ccrsp(cmd,success,response,intermediate)
	local prefix = string.match(cmd,"AT(%+*%u+)")
	print("ljdcc ccrsp",prefix,cmd,success,response,intermediate)
	if prefix == "D" then
		if not success then
			discevt("CALL_FAILED")
		end
	elseif prefix == "+CHUP" then
		discevt("LOCAL_HANG_UP")
	elseif prefix == "+CLCC" then
	    proclist()
    elseif prefix=='+CHLD' and (response=='ERROR' or response=='NO ANSWER') then
    	qrylist()	
	elseif prefix == "A" then
		incoming_num = nil
		qrylist()--dispatch("CALL_CONNECTED")
	end
end

-- urc
ril.regurc("CALL READY",ccurc)
ril.regurc("CONNECT",ccurc)
ril.regurc("NO CARRIER",ccurc)
ril.regurc("NO ANSWER",ccurc)
ril.regurc("BUSY",ccurc)
ril.regurc("+CLIP",ccurc)
ril.regurc("+CLCC",ccurc)

-- rsp
ril.regrsp("D",ccrsp)
ril.regrsp("A",ccrsp)
ril.regrsp("+CHUP",ccrsp)
ril.regrsp("+CLCC",ccrsp)
ril.regrsp("+CHLD",ccrsp)
--cc config
req("ATX4") --开启拨号音,忙音检测
req("AT+CLIP=1")
