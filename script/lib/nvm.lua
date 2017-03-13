module(...,package.seeall)
require"config"

package.path = "/?.lua;"..package.path

configname,paraname = "/lua/config.lua","/para.lua"
local para
local ssub,sgsub = string.sub,string.gsub

local function print(...)
	_G.print("nvm",...)
end

function restore()
	print("restore")
	local verflg = para and get("verflg") or "DEBUG"
	local darkflg
	if para then
		darkflg = get("darkflg")
	else
		darkflg = true
	end
	local fpara,fconfig = io.open(paraname,"wb"),io.open(configname,"rb")
	fpara:write(fconfig:read("*a"))
	fpara:close()
	fconfig:close()
	para = config
	set("verflg",verflg)
	set("darkflg",darkflg)
end

local function serialize(pout,o)
	if type(o) == "number" then
		pout:write(o)
	elseif type(o) == "string" then
		pout:write(string.format("%q", o))
	elseif type(o) == "boolean" then
		pout:write(tostring(o))
	elseif type(o) == "table" then
		pout:write("{\r\n")
		for k,v in pairs(o) do
			if type(k) == "number" then
				pout:write(" [", k, "] = ")
			elseif type(k) == "string" then
				pout:write(" [\"", k,"\"] = ")
			else
				error("cannot serialize table key " .. type(o))
			end
			serialize(pout,v)
			pout:write(",\r\n")
		end
		pout:write("}\r\n")
	else
		error("cannot serialize a " .. type(o))
	end
end

local function upd()
	--local f = io.open(paraname,"ab")
	for k,v in pairs(config) do
		if k ~= "_M" and k ~= "_NAME" and k ~= "_PACKAGE" then
			if para[k] == nil then
				--f:write(k, " = ")
				--serialize(f,v)
				--f:write("\r\n")
				para[k] = v
			end			
		end
	end
	--f:close()
end

local function load()	
	local f = io.open(paraname,"rb")
	print("load",f)
	if not f or f:read("*a") == "" then
		if f then f:close() end
		restore()
		return
	end
	f:close()
	
	f,para = pcall(require,"para")
	if not f then
		restore()
		return
	end
	upd()
end

local function save(s,flu)
	if not s then return end
	local f = io.open(paraname,"wb")

	f:write("module(...)\r\n")

	for k,v in pairs(para) do
		if k ~= "_M" and k ~= "_NAME" and k ~= "_PACKAGE" then
			f:write(k, " = ")
			serialize(f,v)
			f:write("\r\n")
		end
	end

	if flu then f:flush() end
	f:close()	
end

function set(k,v,r,s)
	local bchg = true
	if type(v) ~= "table" then
		bchg = (para[k] ~= v)
	end
	print("set",bchg,k,v,r,s)
	if bchg then		
		para[k] = v
		save(s or s==nil)		
	end
	if r then sys.dispatch("PARA_"..(bchg and "CHANGED" or "SET").."_IND",k,v,r) end
	return true
end

function sett(k,kk,v,r,s)
	print("sett",k)
	--if para[k][kk] ~= v then
		para[k][kk] = v
		save(s or s==nil)
		if r then sys.dispatch("TPARA_CHANGED_IND",k,kk,v,r) end
	--end
	return true
end

function flush(s)
	save(true,s)
end

function get(k)
	if type(para[k]) == "table" then
		local tmp = {}
		for kk,v in pairs(para[k]) do
			tmp[kk] = v
		end
		return tmp
	else
		return para[k]
	end
end

function gett(k,kk)
	return para[k][kk]
end

--tm:18004(星期4的18：00) stm:1111100!18001900(周一到周五的18:00到19:00)
function isilent(t)
	local tm,i,wday,stm = t or (ssub(misc.getclockstr(),7,10)..misc.getweek())
	wday = tonumber(ssub(tm,5,5))
	for i=1,#get("silentime") do
		stm = gett("silentime",i)
		if stm and stm ~= "" and ssub(stm,wday,wday)=="1" then
			local bgn,ed,cur = tonumber(ssub(stm,9,12)),tonumber(ssub(stm,13,16)),tonumber(ssub(tm, 1,4))
			if (cur>=bgn and cur<=ed and bgn<=ed) or ((cur>=bgn or cur<=ed) and bgn>=ed) then
				return true
			end
		end
	end
end

function permissible(typ,id)
	local info,i = get("contacts")
	if typ=="pb" then
		for i=1,#info do
			if get("whitenumswitch")==0 then
				if isilent() then
					if (info[i].typ==0 or info[i].typ==1 or info[i].typ==2 or info[i].typ==4) and pbnumatch(id,info[i]) then
						if info[i].typ==0 then return true end
					end	
				else
					return true
				end							
			else
				if (info[i].typ==0 or info[i].typ==1 or info[i].typ==2 or info[i].typ==4) and pbnumatch(id,info[i]) then
					if info[i].typ==0 then return true end
					return isilent()~=true
				end
			end			
		end
	elseif typ=="chat" then
		for i=1,#info do
			if info[i].typ>=0 and info[i].typ<=3 and string.match(id,info[i].id.."$") then
				if info[i].typ==0 then return true end
				return isilent()~=true
			end		
		end
	end
end

function getsilstr(id)
	local item,i = gett("silentime",id)
	local day,tm,dstr,tstr = ssub(item,1,7),ssub(item,9,16),"星期:","时间段:"
	if not item or item=="" or day=="0000000" then
		return "无效","空"
	end
	for i=1,7 do
		dstr = dstr..(ssub(day,i,i)=="1" and i or "")
	end
	tstr = tstr..ssub(tm,1,4).."-"..ssub(tm,5,8)
	return dstr,tstr
end

function ntclen(str)
	local i,len1,len2,len3 = 1,0,0,0
	while i <= string.len(str) do
		if string.byte(str,i)<=0x7F then
			i = i + 1
		else
			i = i + 2
		end
		if i <= 9 then
			len1 = i - 1
		elseif i <= len1+9 then 
			len2 = i - 1
		elseif i <= len2+9 then
			len3 = i - 1 
		end
	end
	return len1,len2,len3
end

function getntcstr(id)
	local item,i = gett("notice",id)
	local day,tm,dstr,tstr,nstr = ssub(item,2,8),ssub(item,10,13),"星期:","时间:","内容:"..ssub(item,15,-1)
	nstr = sgsub(nstr, "\\n", "");
	local len1,len2,len3 = ntclen(ssub(nstr,6,-1))
	if len3 == 0 and len2 ~= 0 then
		len3 = len2
	elseif len3 == 0 and len2 == 0 then
		len3 = len1
	end
	if not item or item=="" or day=="0000000" then
		return "无效","空",ssub(nstr,1,len3+5)
	end
	for i=1,7 do
		dstr = dstr..(ssub(day,i,i)=="1" and i or "")
	end
	tstr = tstr..tm	
	return tstr,dstr,ssub(nstr,1,len3+5)
end

function getcontactstr(id)
	local item,pbnum = gett("contacts",id)
	print("getcontactstr",item)
	if not item then
		return "无效"
	end
	if type(item.phone)=="table" then
		local i
		for i=1,#item.phone do
			pbnum = (pbnum or "")..item.phone[i]..((i==#item.phone) and "" or ",")
		end
	end
	if item.typ==0 then
		return "管理员,"..((item.nm or "")..",")..(pbnum or (item.id or ""))
	elseif item.typ==1 then
		return "非管理员,"..((item.nm or "")..",")..(pbnum or (item.id or ""))
	elseif item.typ==2 then
		return "手表好友,"..((item.nm or "")..",")..(pbnum or (item.phone or ""))
	elseif item.typ==3 then
		return "群组,"..(item.nm or "")
	elseif item.typ==4 then
		return "白名单,"..((item.nm or "")..",")..(pbnum or (item.id or ""))
	else
		return "类型错误:"..item.typ
	end
end

function getchtunrd(cid)
	local cht,cnt,k,v = nvm.gett("chats",cid) or {},0	
	for k,v in pairs(cht) do		
		cnt = cnt+(v.unrd and 1 or 0)
	end
	return cnt
end

function delcht(id)
	local chts,k,v = get("chats")
	if chts[id] and #chts[id]>0 then		
		for k,v in pairs(chts[id]) do
			if v.pth then
				os.remove(v.pth)
				print("os.remove",v.pth)
			end
		end
		chts[id] = nil
		set("chats",chts)
	end
end

function pbnumatch(num,item)
	if string.match(num,item.id.."$") then return true end
	if type(item.phone)=="table" then
		local j
		for j=1,#item.phone do
			if num==item.phone[j] then return true end
		end
	elseif type(item.phone)=="string" then
		if string.match(num,item.phone.."$") then return true end
	end 
end

function isosnum(num)
	local info = get("contacts")
	for i=1,#info do
		if (info[i].typ==0 or info[i].typ==1) and pbnumatch(num,info[i]) then
			return true
		end
	end
end

function ispbnum(num)
	local info = get("contacts")
	for i=1,#info do
		if (info[i].typ==0 or info[i].typ==1 or info[i].typ==2 or info[i].typ==4) and pbnumatch(num,info[i]) then
			return true
		end
	end
end

load()
