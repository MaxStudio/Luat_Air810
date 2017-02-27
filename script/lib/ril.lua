
-- 定义模块,导入依赖库
local base = _G
local table = require"table"
local string = require"string"
local uart = require"uart"
local rtos = require"rtos"
local sys = require"sys"
module("ril")

--加载常用的全局函数至本地
local setmetatable = base.setmetatable
local print = base.print
local type = base.type
local smatch = string.match
local sfind = string.find
local vwrite = uart.write
local vread = uart.read

-- 常量
local TIMEOUT,RETRYTIMEOUT,RETRY_MAX = 60000,1000,5 --1分钟无反馈 判定at命令执行失败
-- cmd type: 0:no reuslt 1:number 2:sline 3:mline 4:string
local NORESULT = 0
local NUMBERIC = 1
local SLINE = 2
local MLINE = 3
local STRING = 4
local RILCMD = {
	["+CSQ"] = 2,
	["+CGSN"] = 1,
	["+WISN"] = 2,
	["+AUD"] = 2,
	["+VER"] = 2,
	["+BLVER"] = 2,
	["+CIMI"] = 1,
	["+ICCID"] = 2,
	["+CGATT"] = 2,
	["+CCLK"] = 2,
	["+CPIN"] = 2,
	["+ATWMFT"] = 4,
	["+CMGR"] = 3,
	["+CMGS"] = 2,
	["+CPBF"] = 3,
	["+CPBR"] = 3, 	
}

-- local var
local radioready,delaying = false

-- 命令队列
local cmdqueue = {
	{cmd = "ATE0",retry = {max=25,timeout=2000}},
	"AT+CMEE=0",
	"AT+VER",
	"AT+BLVER"
}
-- 当前正在执行的命令,参数,反馈回调,延迟执行,命令头,类型,反馈格式
local currcmd,currarg,currsp,curdelay,curetry,cmdhead,cmdtype,rspformt
-- 反馈结果,中间信息,结果信息
local result,interdata,respdata

-- ril会出现三种情况: 命令回复\主动上报\命令超时
-- 超时
local function atimeout()
	sys.restart("ril.atimeout_"..(currcmd or "")) -- 命令响应超时自动重启系统
end

local function retrytimeout()
	print("retrytimeout",currcmd,curetry)
	if curetry and currcmd then
		if not curetry.cnt then curetry.cnt=0 end
		if curetry.cnt<=(curetry.max or RETRY_MAX) then
			sys.timer_start(retrytimeout,curetry.timeout or RETRYTIMEOUT)
			print("sendat retry:",currcmd)
			vwrite(uart.ATC,currcmd .. "\r")
			curetry.cnt = curetry.cnt+1
		else
			if curetry.skip then rsp() end
		end
	end
end

-- 命令回复
local function defrsp(cmd,success,response,intermediate)
	print("default response:",cmd,success,response,intermediate)
end

local rsptable = {}
setmetatable(rsptable,{__index = function() return defrsp end})
local formtab = {}
function regrsp(head,fnc,typ,formt)
	if typ == nil then
		rsptable[head] = fnc
		return true
	end
	if typ == 0 or typ == 1 or typ == 2 or typ == 3 or typ == 4 then
		if RILCMD[head] and RILCMD[head] ~= typ then
			return false
		end
		RILCMD[head] = typ
		rsptable[head] = fnc
		formtab[head] = formt
		return true
	else
		return false
	end
end

function rsp()
	sys.timer_stop(atimeout)
	sys.timer_stop(retrytimeout)

	if currsp then
		currsp(currcmd,result,respdata,interdata)
	else
		rsptable[cmdhead](currcmd,result,respdata,interdata)
	end

	currcmd,currarg,currsp,curdelay,curetry,cmdhead,cmdtype,rspformt = nil
	result,interdata,respdata = nil
end

-- 主动上报提示
local function defurc(data)
	print("defurc:",data)
end

local urctable = {}
setmetatable(urctable,{__index = function() return defurc end})
function regurc(prefix,handler)
	urctable[prefix] = handler
end

function deregurc(prefix)
	urctable[prefix] = nil
end

local urcfilter

local function kickoff()
	radioready = true
end

local function urc(data)
	if data == "RDY" then
		radioready = true
	else
		local prefix = smatch(data,"(%+*[%u%d ]+)")

		urcfilter = urctable[prefix](data,prefix)
	end
end

local function procatc(data)
	print("atc:",data)
	
	if interdata and cmdtype == MLINE then -- 继续接收多行反馈直至出现OK为止
		-- 多行反馈的命令如果接收到中间数据说明执行成功了,判定之后的数据结束就是OK
		if data ~= "OK\r\n" then
			if sfind(data,"\r\n",-2) then -- 去掉最后的换行符
				data = string.sub(data,1,-3)
			end
			interdata = interdata .. "\r\n" .. data
			return
		end
	end

	if urcfilter then
		data,urcfilter = urcfilter(data)
	end

	if sfind(data,"\r\n",-2) then -- 若最后两个字节是\r\n则删掉
		data = string.sub(data,1,-3)
	end

	if data == "" then
		return
	end

	if currcmd == nil then -- 当前无命令在执行则判定为urc
		urc(data)
		return
	end

	local isurc = false

	if sfind(data,"^%+CMS ERROR:") or sfind(data,"^%+CME ERROR:") then
		data = "ERROR"
	end

	if data == "OK" then
		result = true
		respdata = data
	elseif data == "ERROR" or data == "NO ANSWER" or data == "NO DIALTONE" then
		result = false
		respdata = data
	elseif data == "NO CARRIER" and currcmd=="ATA" then
    result = false
    respdata = data
	elseif data == "> " then
		if cmdhead == "+CMGS" then -- 根据提示符发送短信或者数据
			print("send:",currarg)
			vwrite(uart.ATC,currarg,"\026")		
		else
			print("error promot cmd:",currcmd)
		end
	else
		--根据命令类型来判断收到的数据是urc或者反馈数据
		if cmdtype == NORESULT then -- 无结果命令 此时收到的数据只有URC
			isurc = true
		elseif cmdtype == NUMBERIC then -- 全数字
			local numstr = smatch(data,"(%x+)")
			if numstr == data then
				interdata = data
			else
				isurc = true
			end
		elseif cmdtype == STRING then -- 字符串
			if smatch(data,rspformt or "^%w+$") then
				interdata = data
			else
				isurc = true
			end
		elseif cmdtype == SLINE or cmdtype == MLINE then
			if interdata == nil and sfind(data, cmdhead) == 1 then
				interdata = data
			else
				isurc = true
			end		
		else
			isurc = true
		end
	end

	if isurc then
		urc(data)
	elseif result ~= nil then
		rsp()
	end
end

local readat = false

local function getcmd(item)
	local cmd,arg,rsp,delay,retry

	if type(item) == "string" then
		cmd = item
	elseif type(item) == "table" then
		cmd = item.cmd
		arg = item.arg
		rsp = item.rsp
		delay = item.delay
		retry = item.retry
	else
		print("getpack unknown item")
		return
	end

	head = smatch(cmd,"AT([%+%*]*%u+)")

	if head == nil then
		print("request error cmd:",cmd)
		return
	end

	if head == "+CMGS" then -- 必须有参数
		if arg == nil or arg == "" then
			print("request error no arg",head)
			return
		end
	end

	currcmd = cmd
	currarg = arg
	currsp = rsp
	curdelay = delay
	curetry = retry
	cmdhead = head
	cmdtype = RILCMD[head] or NORESULT
	rspformt = formtab[head]

	return currcmd
end

local function sendat()
	if not radioready or readat or currcmd ~= nil or delaying then
		-- 未初始化/正在读取atc数据、有命令在执行、队列无命令 直接退出
		return
	end

	local item

	while true do
		if #cmdqueue == 0 then
			return
		end

		item = table.remove(cmdqueue,1)

		getcmd(item)

		if curdelay then
			sys.timer_start(delayfunc,curdelay)
			currcmd,currarg,currsp,curdelay,cmdhead,cmdtype,rspformt = nil
			item.delay = nil
			delaying = true
			table.insert(cmdqueue,1,item)
			return
		end

		if currcmd ~= nil then
			break
		end
	end

	sys.timer_start(atimeout,TIMEOUT)
	if curetry then sys.timer_start(retrytimeout,curetry.timeout or RETRYTIMEOUT) end

	print("sendat:",currcmd)

	vwrite(uart.ATC,currcmd .. "\r")
end

function delayfunc()
	delaying = nil
	sendat()
end

local function atcreader()
	local s

	readat = true
	while true do
		s = vread(uart.ATC,"*l",0)

		if string.len(s) ~= 0 then
			procatc(s)
		else
			break
		end
	end
	readat = false
	sendat() -- atc上报数据处理完以后才执行发送AT命令
end

sys.regmsg("atc",atcreader)

function request(cmd,arg,onrsp,delay,retry)
	--插入缓冲队列
	if arg or onrsp or delay or retry then
		table.insert(cmdqueue,{cmd = cmd,arg = arg,rsp = onrsp,delay = delay,retry = retry})
	else
		table.insert(cmdqueue,cmd)
	end

	sendat()
end
sys.timer_start(kickoff,3000)
