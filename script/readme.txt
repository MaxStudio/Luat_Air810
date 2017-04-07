一个完整的项目脚本包含2部分：
  第1部分、所有项目都必需包含lib目录中的"库脚本"。
  第2部分、用户编写的"应用脚本",demo目录为示例应用。


demo中的应用示例：
audio：音频播放

call：语音通话

gpio：测试gpio
   gpio_single：纯gpio控制
   i2c_gpio_switch：i2c和gpio功能切换
   uart_gpio_switch：uart和gpio功能切换

gps GPS定位

i2c：i2c通信

mqtt：mqtt应用

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

wdt：测试开发板上的硬件看门狗

