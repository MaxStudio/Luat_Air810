--[[
模块名称：休眠管理（不是飞行模式）
模块功能：lua脚本应用的休眠控制
使用方式请参考：script/demo/pm
模块最后修改时间：2017.02.13
]]

--[[
关于休眠这一部分的说明：
目前的休眠处理有两种方式，
一种是底层core内部，自动处理，例如tcp发送或者接收数据时，会自动唤醒，发送接收结束后，会自动休眠；这部分不用lua脚本控制
另一种是lua脚本使用pm.sleep和pm.wake自行控制，例如，uart连接外围设备，uart接收数据前，要主动去pm.wake，这样才能保证前面接收的数据不出错，当不需要通信时，调用pm.sleep；如果有lcd的项目，也是同样道理
不休眠时功耗至少30mA左右
如果不是故意控制的不休眠，一定要保证pm.wake("A")了，有地方去调用pm.sleep("A")
]]

--定义模块,导入依赖库
local base = _G

local rtos = require"rtos"
local sys = require"sys"
local pmd = require"pmd"
local pairs = base.pairs
module("pm")

--[[
tags: 唤醒标记表
]]
local tags = {}
--lua应用是否休眠，true休眠，其余没休眠
local flag = true

--[[
函数名：print
功能  ：打印接口，此文件中的所有打印都会加上pm前缀
参数  ：无
返回值：无
]]
local function print(...)
  base.print("pm",...)
end

--[[
函数名：isleep
功能  ：读取lua应用的休眠状态
参数  ：无
返回值：true休眠，其余没休眠
]]
function isleep()
	return flag
end

--[[
函数名：wake
功能  ：lua应用唤醒系统
参数  ：
		tag：唤醒标记，用户自定义
返回值：无
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
函数名：sleep
功能  ：lua应用休眠系统
参数  ：
		tag：休眠标记，用户自定义，跟wake中的标记保持一致
返回值：无
]]
function sleep(tag)

	id = tag or "default"

        --唤醒表中此休眠标记位置置0
	tags[id] = 0

	if tags[id] < 0 then
		base.print("pm.sleep:error",tag)
		tags[id] = 0
	end

	base.print("pm sleep tag=",tag)
	for k,v in pairs(tags) do
		base.print("pm sleep pairs(tags)",k,v)
	end

	-- 只要存在任何一个模块唤醒,则不睡眠
	for k,v in pairs(tags) do
		if v > 0 then
			return
		end
	end

	flag = true
	base.print("pmd.sleep 1")
	--调用底层软件接口，真正休眠系统
	pmd.sleep(1)
end

local function init()
  vbatvolt = 3800
  
  local param = {}
  param.ccLevel = 4050  --恒流充电点 ，低于4.15恒流，高于则恒压
  param.cvLevel = 4200-- 充满电压点
  param.ovLevel = 4250-- 充电限制电压
  param.pvLevel = 4100---回充点
  param.poweroffLevel = 3400--%0电压点
  param.ccCurrent = 300--恒流 阶段电流
  param.fullCurrent = 50--充满停止电流
  pmd.init(param)
end

init()
