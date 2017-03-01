--[[
ģ�����ƣ�ͨ�ÿ⺯��
ģ�鹦�ܣ������ʽת����ʱ��ʱ��ת��
ģ������޸�ʱ�䣺2017.02.20
]]

--����ģ��,����������
module(...,package.seeall)

--���س��õ�ȫ�ֺ���������
local tonumber = tonumber
local tinsert = table.insert
local ssub = string.sub
local sbyte = string.byte
local schar = string.char
local sformat = string.format
local slen = string.len

--[[
��������ucs2toascii
����  ��ascii�ַ�����unicode�����16�����ַ��� ת��Ϊ ascii�ַ���������"0031003200330034" -> "1234"
����  ��
		inum����ת���ַ���
����ֵ��ת������ַ���
]]
function ucs2toascii(inum)
	local tonum = {}
	for i=1,string.len(inum),4 do
		table.insert(tonum,tonumber(string.sub(inum,i,i+3),16)%256)
	end

	return string.char(unpack(tonum))
end

--[[
��������ucs2toascii
����  ��ascii�ַ��� ת��Ϊ ascii�ַ�����unicode�����16�����ַ�������֧�����ֺ�+������"+1234" -> "002B0031003200330034"
����  ��
		inum����ת���ַ���
����ֵ��ת������ַ���
]]
function nstrToUcs2Hex(inum)
	local hexs = ""
	local elem = ""

	for i=1,string.len(inum) do
		elem = string.sub(inum,i,i)
		if elem == "+" then
			hexs = hexs .. "002B"
		else
			hexs = hexs .. "003" .. elem
		end
	end

	return hexs
end

--[[
��������numtobcdnum
����  ������ASCII�ַ��� ת��Ϊ BCD�����ʽ�ַ�������֧�����ֺ�+������"+8618126324567" -> 91688121364265f7 ����ʾ��1���ֽ���0x91����2���ֽ�Ϊ0x68��......��
����  ��
		num����ת���ַ���
����ֵ��ת������ַ���
]]
function numtobcdnum(num)
  local len, numfix,convnum = slen(num),"81",""
  
  if ssub(num, 1,1) == "+" then
    numfix = "91"
    len = len-1
    num = ssub(num, 2,-1)
  end

  if len%2 ~= 0 then --����λ
    for i=1, len/2  do
      convnum = convnum .. ssub(num, i*2,i*2) .. ssub(num, i*2-1,i*2-1)
    end
    convnum = convnum .. "F" .. ssub(num,len, len)
  else--ż��λ
    for i=1, len/2  do
      convnum = convnum .. ssub(num, i*2,i*2) .. ssub(num, i*2-1,i*2-1)
    end
  end
  
  return numfix .. convnum
end

--[[
��������bcdnumtonum
����  ��BCD�����ʽ�ַ��� ת��Ϊ ����ASCII�ַ�������֧�����ֺ�+������91688121364265f7 ����ʾ��1���ֽ���0x91����2���ֽ�Ϊ0x68��......�� -> "+8618126324567"
����  ��
		num����ת���ַ���
����ֵ��ת������ַ���
]]
function bcdnumtonum(num)
  local len, numfix,convnum = slen(num),"",""
  
  if len%2 ~= 0 then
    print("your bcdnum is err " .. num)
    return
  end
  
  if ssub(num, 1,2) == "91" then
    numfix = "+"
  end
  
  len,num = len-2,ssub(num, 3,-1)
  
  for i=1, len/2  do
    convnum = convnum .. ssub(num, i*2,i*2) .. ssub(num, i*2-1,i*2-1)
  end
    
  if ssub(convnum,len,len) == "f"  or ssub(convnum,len,len) == "F" then
    convnum = ssub(convnum, 1,-2)
  end
  
  return numfix .. convnum
end

--[[
��������binstohexs
����  ������������ ת��Ϊ 16�����ַ�����ʽ������91688121364265f7 ����ʾ��1���ֽ���0x91����2���ֽ�Ϊ0x68��......�� -> "91688121364265f7"
����  ��
		bins������������
����ֵ��ת������ַ���
]]
function binstohexs(bins)
	local hexs = ""

	if bins == nil or type(bins) ~= "string" then return nil,"nil input string" end

	for i=1,string.len(bins) do
		hexs = hexs .. sformat("%02X",sbyte(bins,i))
	end
	hexs = string.upper(hexs)
	return hexs
end

--[[
��������hexstobins
����  ��16�����ַ��� ת��Ϊ ���������ݸ�ʽ������"91688121364265f7" -> 91688121364265f7 ����ʾ��1���ֽ���0x91����2���ֽ�Ϊ0x68��......��
����  ��
		hexs��16�����ַ���
����ֵ��ת���������
]]
function hexstobins(hexs)
	local tbins = {}
	local num

	if hexs == nil or type(hexs) ~= "string" then return nil,"nil input string" end

	for i=1,string.len(hexs),2 do
		num = tonumber(ssub(hexs,i,i+1),16)
		if num == nil then
			return nil,"error num index:" .. i .. ssub(hexs,i,i+1)
		end
		tinsert(tbins,num)
	end

	return schar(unpack(tbins))
end

--[[
��������ucs2togb2312
����  ��unicodeС�˱��� ת��Ϊ gb2312����
����  ��
		ucs2s��unicodeС�˱�������
����ֵ��gb2312��������
]]
function ucs2togb2312(ucs2s)
	local cd = iconv.open("gb2312","ucs2")
	return cd:iconv(ucs2s)
end

--[[
��������gb2312toucs2
����  ��gb2312���� ת��Ϊ unicodeС�˱���
����  ��
		ucs2s��gb2312��������
����ֵ��unicodeС�˱�������
]]
function gb2312toucs2(gb2312s)
	local cd = iconv.open("ucs2","gb2312")
	return cd:iconv(gb2312s)
end

--[[
��������ucs2betogb2312
����  ��unicode��˱��� ת��Ϊ gb2312����
����  ��
		ucs2s��unicode��˱�������
����ֵ��gb2312��������
]]
function ucs2betogb2312(ucs2s)
	local cd = iconv.open("gb2312","ucs2be")
	return cd:iconv(ucs2s)
end

--[[
��������gb2312toucs2be
����  ��gb2312���� ת��Ϊ unicode��˱���
����  ��
		ucs2s��gb2312��������
����ֵ��unicode��˱�������
]]
function gb2312toucs2be(gb2312s)
	local cd = iconv.open("ucs2be","gb2312")
	return cd:iconv(gb2312s)
end

local function addzone(y,m,d,hh,mm,ss,zone)

	if not y or not m or not d or not hh or not mm or not ss then
		return
	end

	hh = hh + zone
	if hh >= 24 then
		hh = hh - 24
		d = d + 1
		if m == 4 or m == 6 or m == 9 or m == 11 then
			if d > 30 then
				d = 1
				m = m + 1
			end
			elseif m == 1 or m == 3 or m == 5 or m == 7 or m == 8 or m == 10 then
			if d > 31 then
				d = 1
				m = m + 1
			end
			elseif m == 12 then
			if d > 31 then
				d = 1
				m = 1
				y = y + 1
			end
		elseif m == 2 then
			if (((y+2000)%400) == 0) or (((y+2000)%4 == 0) and ((y+2000)%100 ~=0)) then
				if d > 29 then
					d = 1
					m = 3
				end
			else
				if d > 28 then
					d = 1
					m = 3
				end
			end
		end
	end
	local t = {}
	t.year,t.month,t.day,t.hour,t.min,t.sec = y,m,d,hh,mm,ss
	return t
end
local function subzone(y,m,d,hh,mm,ss,zone)
	if not y or not m or not d or not hh or not mm or not ss then
		return
	end
	hh = hh + zone
	if hh < 0 then
		hh = hh + 24
		d = d - 1
		if m == 2 or m == 4 or m == 6 or m == 8 or m == 9 or m == 11 then
			if d < 1 then
				d = 31
				m = m -1
			end
		elseif m == 5 or m == 7  or m == 10 or m == 12 then
			if d < 1 then
				d = 30
				m = m -1
			end
		elseif m == 1 then
			if d < 1 then
				d = 31
				m = 12
				y = y -1
			end
		elseif m == 3 then
			if (((y+2000)%400) == 0) or (((y+2000)%4 == 0) and ((y+2000)%100 ~=0)) then
				if d < 1 then
					d = 29
					m = 2
				end
			else
				if d < 1 then
					d = 28
					m = 2
				end
			end
		end
	end
	local t = {}
	t.year,t.month,t.day,t.hour,t.min,t.sec = y,m,d,hh,mm,ss
	return t
end

--[[
��������transftimezone
����  ����ǰʱ����ʱ��ת��Ϊ��ʱ����ʱ��
����  ��
		y����ǰʱ�����
		m����ǰʱ���·�
		d����ǰʱ����
		hh����ǰʱ��Сʱ
		mm����ǰʱ����
		ss����ǰʱ����
		pretimezone����ǰʱ��
		nowtimezone����ʱ��
����ֵ��������ʱ����Ӧ��ʱ�䣬table��ʽ{year,month.day,hour,min,sec}
]]
function transftimezone(y,m,d,hh,mm,ss,pretimezone,nowtimezone)
	local t,zone = {},nowtimezone-pretimezone

	if zone >= 0 and zone < 23 then
		t = addzone(y,m,d,hh,mm,ss,zone)
	elseif zone < 0 and zone >= -24 then
		t = subzone(y,m,d,hh,mm,ss,zone)
	end
	return t
end

