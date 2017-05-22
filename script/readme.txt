一个完整的项目脚本包含2部分：
  第1部分、所有项目都必需包含lib目录中的"库脚本"。
  第2部分、用户编写的"应用脚本",demo目录为示例应用。


demo中的应用示例：
aliyun：MQTT_TCP连接阿里云物联网后台

audio：音频播放

call：语音通话

default：Air810的默认出厂软件，可以使用时间线APP查看模块的基站位置

gpio：测试gpio
   gpio_single：纯gpio控制
   i2c_gpio_switch：i2c和gpio功能切换
   uart_gpio_switch：uart和gpio功能切换

gps GPS定位

i2c：i2c通信

json：json编解码测试

lbs_loc：根据多基站获取经纬度

luatyun：MQTT_TCP连接Luat云后台

mqtt：mqtt应用


ntp：模块时间自动更新

nvm：参数存储读写

pm：休眠控制

sms：短信

socket：测试socket通信
  long_connection 基于TCP的socket长连接通信(UDP使用方式和TCP完全相同)
  long_connection_transparent 基于TCP的socket透传通信，uart1透传数据到指定服务器
  short_connection 基于TCP的socket短连接通信(UDP使用方式和TCP完全相同)
  short_connection_flymode 基于TCP的socket短连接通信，会进入飞行模式并且定时退出飞行模式(UDP使用方式和TCP完全相同)

timer：定时器

uart：串口

uart_prot1项目：通过uart解析外围设备输入的一种报文（起始标志，长度，指令，数据，校验码，结束标志）

update\Luat_iot_server：使用Luat物联云平台进行固件升级

update\user_server：使用用户自己的后台进行固件升级

wdt：测试开发板上的硬件看门狗

write_sn：写SN号到设备

write_imei：写imei号到设备

xiaoman_gps_tracker\whole_test：针对小蛮GPS定位器硬件写的一个完整的demo项目，支持硬件的各种功能，只能用于小蛮GPS定位器硬件，不能用于开发板，也不能配合时间线APP使用，注意修改sck.lua中的后台地址

