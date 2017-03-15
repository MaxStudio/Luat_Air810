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

uart_at_transparent：物理串口UART1透传AT命令，网络指示灯一直闪烁，亮100毫秒，灭2900毫秒（可通过开发板上的物理串口uart1，透传AT命令，波特率为115200，数据位8，停止位1，校验位和流控无；PC上的串口调试工具通过串口线和Air200开发板上的uart1相连，配置好串口参数，开发板上电开机，就可以支持AT命令的透传了）

uart_at_transparent_wdt：物理串口UART1透传AT命令（软件上支持硬件看门狗），网络指示灯一直闪烁，亮100毫秒，灭2900毫秒（可通过开发板上的物理串口uart1，透传AT命令，波特率为115200，数据位8，停止位1，校验位和流控无；PC上的串口调试工具通过串口线和Air200开发板上的uart1相连，配置好串口参数，开发板上电开机，就可以支持AT命令的透传了）

wdt：测试开发板上的硬件看门狗

