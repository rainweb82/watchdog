# URL监控脚本

#### 介绍
使用shell脚本实时监控域名是否可正常访问，支持微信消息推送，每日监控报告等功能。

#### 运行软件termax

安卓：https://github.com/termux/termux-app/releases<br />
MAC：https://github.com/electerm/electerm/releases

#### 微信推送pushplus

自行前往www.pushplus.plus注册，并填写token

#### 首次执行

pkg install git && git clone --depth 1 https://gitee.com/iamruirui/watchurl.git watchdog && cp ./watchdog/run.sh run.sh && cp ./watchdog/config config 

#### 运行程序

bash run.sh