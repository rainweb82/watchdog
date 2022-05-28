#Watchdog 直接复制到shell内运行
#v1 实现基本监控
#v2 增加可配置参数
#v3 增加错误推送功能
#v4 增加每日数据推送
#v5 优化输出样式
 
#读取需监控的域名
url=`cat ./watchdog/url.list`
#PUSHPLUS推送token
pushplustoken=54896b0e291c4d32be5e3b961c00fdfe
#出错时推送间隔时间（分）
msgtimes=10
#每日几点推送日报，每天2次（1点-12点）
daypost=9
#首次错误推送容错次数
err=3
#正常时检测间隔时间（分）
interval=5
#异常时强制为1分钟


zcnum=0
cwnum=0
issend=0
tstart=`date '+%s'`
#生成简化url
url_s=$((${#url}/3))
surl=${url:0:url_s}***${url:$((${#url}-${#url}/3))}
#推送容错时间计算
times=$(($msgtimes-$err+1))
#生成推送地址
msg=http://www.pushplus.plus/send?token=$pushplustoken\&title=${surl}%E7%BD%91%E7%AB%99%E6%8C%82%E4%BA%86\&content=${surl}+%E5%9F%9F%E5%90%8D%E6%8C%82%E4%BA%86%EF%BC%8C%E5%BF%AB%E5%8E%BB%E7%9C%8B%E7%9C%8B%E5%90%A7%EF%BC%81+`date +"%m-%d_%H:%M:%S"`\&template=html
#开始循环
while [[ $tries -lt 5 ]]
do
if [ $(($zcnum+$cwnum)) -eq 0 ]
then
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
if [ $(( $(($zcnum+$cwnum)) % 20 )) = 0 ]
then
#首次不输出统计
if [ $(($zcnum+$cwnum)) -ne 0 ]
then
echo -e "\033[35m"已检测:$(($zcnum+$cwnum))次 正常:$zcnum次 错误:$cwnum次 运行:${day}天${hour}小时${min}分${sec}秒
fi
fi
#判断是否发送每日推送
if [ $nowtime -eq $daypost ] && [ $issend -eq 1 ]
then
nowmsg=http://www.pushplus.plus/send?token=$pushplustoken\&title=${surl}%E7%9B%91%E6%8E%A7%E6%97%A5%E6%8A%A5\&content=%E7%9B%91%E6%8E%A7%E5%9F%9F%E5%90%8D%EF%BC%9A${surl}%3Cbr+%2F%3E%E7%9B%91%E6%8E%A7%E6%AC%A1%E6%95%B0%EF%BC%9A$(($zcnum+$cwnum))++%E6%AD%A3%E5%B8%B8%E6%AC%A1%E6%95%B0%EF%BC%9A$zcnum++%E9%94%99%E8%AF%AF%E6%AC%A1%E6%95%B0%EF%BC%9A$cwnum%3Cbr+%2F%3E%E8%BF%90%E8%A1%8C%E6%97%B6%E9%97%B4%EF%BC%9A${day}%E5%A4%A9${hour}%E5%B0%8F%E6%97%B6${min}%E5%88%86${sec}%E7%A7%92%3Cbr+%2F%3E`date +"%m-%d_%H:%M:%S"`\&template=html
aa=`curl -o /dev/null --retry 3 --retry-max-time 30 -s -w %{http_code} $nowmsg`
echo -e "\033[34m"PUSHPLUS 每日推送完成！code：$aa
issend=0
fi
#监控域名返回code
code=`curl -o /dev/null --retry 3 --retry-max-time 30 -s -w %{http_code} $url`
date=`date +"%m-%d %H:%M:%S"`
#判断域名code
if [ $code -ne 200 ] && [ $code -ne 301 ]
then
#打印错误文字
echo -e "\033[31m"网站挂了~快去看看~ 代码:$code 时间：$date
#判断是否需要推送
if [ $(( $times % $msgtimes )) = 0 ] ; then 
#推送消息
a=`curl -o /dev/null --retry 3 --retry-max-time 30 -s -w %{http_code} $msg`
echo -e "\033[34m"PUSHPLUS 推送消息完成！code：$a
#重置报错计数
times=0
fi
#更新报错计数
times=$(($times+1))
#发现异常待命1分钟后重试
sleep 60
cwnum=$(($cwnum+1))
else
#打印正常文字
echo -e "\033[32m"域名可正常访问 代码:$code 时间：$date
#待命x分钟后重试
sleep $(($interval*60))
zcnum=$(($zcnum+1))
fi
done
#代码结束