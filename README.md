# URL监控脚本

#### 介绍
使用shell脚本实时监控域名是否可正常访问，支持微信消息推送，每日监控报告等功能。

#### 微信推送pushplus

自行前往http://www.pushplus.plus/ 注册，并在config文件中填写token值

#### 运行软件

Aidlux：https://www.aidlux.com/product<br />
termax：https://github.com/termux/termux-app/releases<br />
electerm：https://github.com/electerm/electerm/releases

#### Aidlux同步系统时间命令

cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

#### termax需安装功能支持

pkg install git && pkg install vim -y

#### 首次下载最新脚本

git clone --depth 1 https://iamruirui:qweasd123@gitee.com/iamruirui/watchdog.git watchdog && cp ./watchdog/run.sh run.sh && cp ./watchdog/config config

#### 运行程序

bash run.sh

#### 配置程序

config为配置文件，可修改./config文件来调整配置<br />
url.list内为需监控的域名，程序会更新线上url.list文件，修改域名时直接修改线上url.list后，重新运行程序或等待程序自动更新即可

#### config配置说明

|        Name       | 说明                                                         |
| :---------------: | ------------------------------------------------------------ |
| `hub` | 脚本更新地址 |
| `urlhub` | 检测域名所在地址(不填则使用库中的url.list内地址) |
| `pushplustoken` | PUSHPLUS推送token，多个时用空格分割 |
| `rtit` | 网页正常时源码内包含的内容 |
| `err` | 首次错误推送容错次数 |
| `msgtimes` | 连续出错多少次进行推送消息 |
| `cwmax` | 连续错误多少次后自动更新域名 |
| `tjnum` | 每隔多少条输出一次统计信息(同时将检测域名是否有更新) |
| `maxurl` | 连续多少次更新域名失败后恢复旧域名检测 |
| `daypost` | 每日几点推送日报，每天2次（1点-12点） |
| `interval` | 正常时检测间隔时间（分） |
