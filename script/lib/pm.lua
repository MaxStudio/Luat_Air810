--[[
ģ�����ƣ����߹������Ƿ���ģʽ��
ģ�鹦�ܣ�lua�ű�Ӧ�õ����߿���
ʹ�÷�ʽ��ο���script/demo/pm
ģ������޸�ʱ�䣺2017.02.13
]]

--[[
����������һ���ֵ�˵����
Ŀǰ�����ߴ��������ַ�ʽ��
һ���ǵײ�core�ڲ����Զ���������tcp���ͻ��߽�������ʱ�����Զ����ѣ����ͽ��ս����󣬻��Զ����ߣ��ⲿ�ֲ���lua�ű�����
��һ����lua�ű�ʹ��pm.sleep��pm.wake���п��ƣ����磬uart������Χ�豸��uart��������ǰ��Ҫ����ȥpm.wake���������ܱ�֤ǰ����յ����ݲ�����������Ҫͨ��ʱ������pm.sleep�������lcd����Ŀ��Ҳ��ͬ������
������ʱ��������30mA����
������ǹ�����ƵĲ����ߣ�һ��Ҫ��֤pm.wake("A")�ˣ��еط�ȥ����pm.sleep("A")
]]

--����ģ��,����������
local base = _G

local rtos = require"rtos"
local sys = require"sys"
local pmd = require"pmd"
local pairs = base.pairs
module("pm")

--[[
tags: ���ѱ�Ǳ�
]]
local tags = {}
--luaӦ���Ƿ����ߣ�true���ߣ�����û����
local flag = true

--[[
��������print
����  ����ӡ�ӿڣ����ļ��е����д�ӡ�������pmǰ׺
����  ����
����ֵ����
]]
local function print(...)
  base.print("pm",...)
end

--[[
��������isleep
����  ����ȡluaӦ�õ�����״̬
����  ����
����ֵ��true���ߣ�����û����
]]
function isleep()
	return flag
end

--[[
��������wake
����  ��luaӦ�û���ϵͳ
����  ��
		tag�����ѱ�ǣ��û��Զ���
����ֵ����
]]
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

--[[
��������sleep
����  ��luaӦ������ϵͳ
����  ��
		tag�����߱�ǣ��û��Զ��壬��wake�еı�Ǳ���һ��
����ֵ����
]]
function sleep(tag)

	id = tag or "default"

        --���ѱ��д����߱��λ����0
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
	--���õײ�����ӿڣ���������ϵͳ
	pmd.sleep(1)
end

local function init()
  vbatvolt = 3800
  
  local param = {}
  param.ccLevel = 4050  --�������� ������4.15�������������ѹ
  param.cvLevel = 4200-- ������ѹ��
  param.ovLevel = 4250-- ������Ƶ�ѹ
  param.pvLevel = 4100---�س��
  param.poweroffLevel = 3400--%0��ѹ��
  param.ccCurrent = 300--���� �׶ε���
  param.fullCurrent = 50--����ֹͣ����
  pmd.init(param)
end

init()
