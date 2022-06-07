Watchdog 直接复制到shell内运行

#v1 实现基本监控
#v2 增加可配置参数
#v3 增加错误推送功能
#v4 增加每日数据推送
#v5 优化输出样式
#v6 增加第2个推送地址支持
#v7 增加等待中的倒计时进度条

#读取需监控的域名
url=`cat ./watchdog/url.list`
#PUSHPLUS推送tokena(A)
pushplustokena=54896b0e291c4d32be5e3b961c00fdfe
#PUSHPLUS推送tokena(B)
pushplustokenb=
#出错时推送间隔时间（分）
msgtimes=10
#每日几点推送日报，每天2次（1点-12点）
daypost=9
#首次错误推送容错次数
err=3
#错误多少次后自动更新脚本
cwmax=30
#正常时检测间隔时间（分）
interval=5
#异常时强制为1分钟

#检测代码开始
zcnum=0
cwnum=0
issend=0
tstart=`date '+%s'`
ch=('|' '\' '-' '/')
clear
#生成简化url
url_s=$((${#url}/3))
surl=${url:0:url_s}***${url:$((${#url}-${#url}/3))}
#推送容错时间计算
times=$(($msgtimes-$err+1))
#开始循环
while [[ $tries -lt 5 ]]
do
if [ $(($zcnum+$cwnum)) -eq 0 ]
then
printf " 网络检测中，请稍后... \r"
baidu=`curl -o /dev/null --retry 3 --retry-max-time 30 -s -w %{http_code} baidu.com`
if [ $baidu -ne 200 ] && [ $baidu -ne 301 ]
then
baidu=31m失败
else
baidu=32m正常
fi
printf "当前网络访问百度：\033[${baidu} \n"
echo -e "\033[35m"当前监控域名：$url
fi
#每日推送
nowtime=$(($(date +%-H)%12))
if [ $(( $nowtime )) -eq $(($daypost-1)) ]
then
issend=1
fi
#运行时间计算
tend=`date '+%s'`
second=$(( $tend-$tstart ))
day=$(( $second/86400 ))
hour=$(( ($second-${day}*86400)/3600 ))
min=$(( ($second-${day}*86400-${hour}*3600)/60 ))
sec=$(( $second-${day}*86400-${hour}*3600-${min}*60 ))
#每20次检测输出1次监控运行统计
if [ $(( $(($zcnum+$cwnum)) % 20 )) = 0 ] && [ $(($zcnum+$cwnum)) -ne 0 ]
then
echo -e "\033[35m"已检测:$(($zcnum+$cwnum))次 正常:$zcnum次 错误:$cwnum次 运行:${day}天${hour}小时${min}分${sec}秒
fi
#判断是否发送每日推送
if [ $nowtime -eq $daypost ] && [ $issend -eq 1 ] 
then
if [ ! $pushplustokena ]
then
echo 未设置PUSHPLUS-A，跳过本次每日推送任务
else
nowmsga=http://www.pushplus.plus/send?token=$pushplustokena\&title=${surl}%E7%9B%91%E6%8E%A7%E6%97%A5%E6%8A%A5\&content=%E7%9B%91%E6%8E%A7%E5%9F%9F%E5%90%8D%EF%BC%9A${surl}%3Cbr+%2F%3E%E7%B4%AF%E8%AE%A1%E7%9B%91%E6%8E%A7%EF%BC%9A$(($zcnum+$cwnum))%E6%AC%A1+%E3%80%90%E6%AD%A3%E5%B8%B8%EF%BC%9A$zcnum%E6%AC%A1%EF%BC%8C%E9%94%99%E8%AF%AF%EF%BC%9A$cwnum%E6%AC%A1%E3%80%91%3Cbr+%2F%3E%E8%BF%90%E8%A1%8C%E6%97%B6%E9%97%B4%EF%BC%9A${day}%E5%A4%A9${hour}%E5%B0%8F%E6%97%B6${min}%E5%88%86${sec}%E7%A7%92%3Cbr+%2F%3E`date +"%m-%d_%H:%M:%S"`\&template=html
aa=`curl -o /dev/null --retry 3 --retry-max-time 30 -s -w %{http_code} $nowmsga`
echo -e "\033[34m"PUSHPLUS-A 本次每日推送已完成！代码：$aa      
fi
if [ ! $pushplustokenb ]
then
echo 未设置PUSHPLUS-B，跳过本次每日推送任务
else
nowmsgb=http://www.pushplus.plus/send?token=$pushplustokenb\&title=${surl}%E7%9B%91%E6%8E%A7%E6%97%A5%E6%8A%A5\&content=%E7%9B%91%E6%8E%A7%E5%9F%9F%E5%90%8D%EF%BC%9A${surl}%3Cbr+%2F%3E%E7%B4%AF%E8%AE%A1%E7%9B%91%E6%8E%A7%EF%BC%9A$(($zcnum+$cwnum))%E6%AC%A1+%E3%80%90%E6%AD%A3%E5%B8%B8%EF%BC%9A$zcnum%E6%AC%A1%EF%BC%8C%E9%94%99%E8%AF%AF%EF%BC%9A$cwnum%E6%AC%A1%E3%80%91%3Cbr+%2F%3E%E8%BF%90%E8%A1%8C%E6%97%B6%E9%97%B4%EF%BC%9A${day}%E5%A4%A9${hour}%E5%B0%8F%E6%97%B6${min}%E5%88%86${sec}%E7%A7%92%3Cbr+%2F%3E`date +"%m-%d_%H:%M:%S"`\&template=html
bb=`curl -o /dev/null --retry 3 --retry-max-time 30 -s -w %{http_code} $nowmsgb`
echo -e "\033[34m"PUSHPLUS-B 本次每日推送已完成！代码：$bb      
fi
issend=0
fi
#监控域名返回code
code=`curl -o /dev/null --retry 3 --retry-max-time 30 -s -w %{http_code} $url`
date=`date +"%m-%d %H:%M:%S"`
#判断域名code
if [ $code -ne 200 ] && [ $code -ne 301 ]
then
#打印错误文字
echo -e "\033[31m"域名无法正常访问，代码:$code 时间：$date
#判断是否需要推送
if [ $(( $times % $msgtimes )) = 0 ] ; then
#推送消息
if [ ! $pushplustokena ]
then
echo 未设置PUSHPLUS-A，跳过本次错误推送任务
else
#生成推送地址a
msga=http://www.pushplus.plus/send?token=$pushplustokena\&title=${surl}%E7%BD%91%E7%AB%99%E6%8C%82%E4%BA%86\&content=${surl}+%E5%9F%9F%E5%90%8D%E6%8C%82%E4%BA%86%EF%BC%8C%E5%BF%AB%E5%8E%BB%E7%9C%8B%E7%9C%8B%E5%90%A7%EF%BC%81+`date +"%m-%d_%H:%M:%S"`\&template=html
a=`curl -o /dev/null --retry 3 --retry-max-time 30 -s -w %{http_code} $msga`
echo -e "\033[34m"PUSHPLUS-A 本次推送消息已完成！代码：$a      
fi
if [ ! $pushplustokenb ]
then
echo 未设置PUSHPLUS-B，跳过本次错误推送任务
else
#生成推送地址b
msgb=http://www.pushplus.plus/send?token=$pushplustokenb\&title=${surl}%E7%BD%91%E7%AB%99%E6%8C%82%E4%BA%86\&content=${surl}+%E5%9F%9F%E5%90%8D%E6%8C%82%E4%BA%86%EF%BC%8C%E5%BF%AB%E5%8E%BB%E7%9C%8B%E7%9C%8B%E5%90%A7%EF%BC%81+`date +"%m-%d_%H:%M:%S"`\&template=html
b=`curl -o /dev/null --retry 3 --retry-max-time 30 -s -w %{http_code} $msgb`
echo -e "\033[34m"PUSHPLUS-B 本次推送消息已完成！代码：$b      
fi
#重置报错计数
times=0
fi
#更新报错通知计数
times=$(($times+1))
#更新错误计数
cwnum=$(($cwnum+1))
#发现异常待命1分钟后重试
mark=''
markl=''
for ((ratio=240;${ratio}>=0;ratio+=-1))
do
if [ $ratio -ne 240 ]
then
#减少0.1秒以修正程序延迟
sleep 0.24
fi
ratio_s=$(($ratio/4))
printf " \033[37m等待:[%-30s]%d秒[%c]   \r" "${markl}" "${ratio_s}" "${ch[$(($ratio%4))]}"
markl=${mark:0:$((${#mark}/8+1))}
mark="#${mark}"
done
else
#打印正常文字
echo -e "\033[32m"域名可以正常访问，代码:$code 时间：$date     
#更新正常计数
zcnum=$(($zcnum+1))
#访问正常，待命x分钟后重试
mark=''
markl=''
for ((ratio=$(($interval*60*4));${ratio}>=0;ratio+=-1))
do
if [ $ratio -ne $(($interval*60*4)) ]
then
#减少0.1秒以修正程序延迟
sleep 0.24
fi
ratio_s=$(($ratio/4))
printf " \033[37m等待:[%-30s]%d秒[%c]   \r" "${markl}" "${ratio_s}" "${ch[$(($ratio%4))]}"
markl=${mark:0:$((${#mark}/$(($interval*8))+1))}
mark="#${mark}"
done
fi
#错误次数超过30次，自动退出并更新脚本
if [ $cwnum -eq $cwmax ]
then
break
fi
done
#循环结束
echo 域名连接错误过多，将更新脚本后重试-
mark=''
for ((ratio=0;${ratio}<=100;ratio+=5))
do
sleep 0.2
printf " \033[37m等待:[%-40s]%d%%\r" "${mark}" "${ratio}"
mark="##${mark}"
done
bash run.sh
#代码结束
