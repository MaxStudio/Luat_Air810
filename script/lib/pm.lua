-- ��Դ���� power manage
local base = _G
local pmd = require"pmd"
local pairs = base.pairs
module("pm")

local tags = {}
local flag = true

function isleep()
	return flag
end

function wake(tag)
	base.print("pm wake tag=",tag)
	id = tag or "default"

	tags[id] = 1

	if flag == true then
		flag = false
		base.print("pmd.sleep 0")
		pmd.sleep(0)
	end
end

function sleep(tag)
	
	id = tag or "default"

	tags[id] = 0

	if tags[id] < 0 then
		base.print("pm.sleep:error",tag)
		tags[id] = 0
	end
	
	base.print("pm sleep tag=",tag)
	for k,v in pairs(tags) do
		base.print("pm sleep pairs(tags)",k,v)
	end
	
	-- ֻҪ�����κ�һ��ģ�黽��,��˯��
	for k,v in pairs(tags) do
		if v > 0 then
			return
		end
	end

	flag = true
	base.print("pmd.sleep 1")
	pmd.sleep(1)
end

pmd.sleep(1)
