# URL监控脚本

#### 介绍
使用shell脚本实时监控域名是否可正常访问，支持微信消息推送，每日监控报告等功能。

#### 运行软件termax

https://termux.com/

#### 首次执行

pkg install git && git clone --depth 1 https://gitee.com/iamruirui/watchurl.git watchdog && cp ./watchdog/run.sh run.sh && cp ./watchdog/hub.list hub.list 

#### 运行程序

bash run.sh