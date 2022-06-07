#Watchdog 直接复制到shell内运行

#v1 实现基本监控
#v2 增加可配置参数
#v3 增加错误推送功能
#v4 增加每日数据推送
#v5 优化输出样式
#v6 增加第2个推送地址支持
#v7 增加等待中的倒计时进度条
#v8 增加错误次数过多后，自动获取新域名功能

#脚本更新地址
hub=`cat ./watchdog/hub.list`
#读取需监控的域名
url=`cat ./watchdog/url.list`
#PUSHPLUS推送tokena(A)
pushplustokena=
#PUSHPLUS推送tokena(B)
pushplustokenb=
#首次错误推送容错次数
err=3
#连续出错多少次进行推送消息
msgtimes=10
#连续错误多少次后自动更新域名
cwmax=20
#每隔多少条输出一次统计信息
tjnum=20
#连续多少次更新域名失败后恢复旧域名检测
maxurl=4
#每日几点推送日报，每天2次（1点-12点），同时将检测域名是否有更新
daypost=9
#正常时检测间隔时间（分）
interval=5
#异常时强制为1分钟

clear
#检测代码开始
zcnum=0
cwnum=0
lxcwhj=0
issend=0
tstart=`date '+%s'`
ch=('|' '\' '-' '/')
#推送容错时间计算
times=$(($msgtimes-$err))
temptimes=$times
#生成简化url
url_s=$((${#url}/3))
surl=${url:0:url_s}***${url:$((${#url}-${#url}/3))}
printf " 网络检测中，请稍后... \r"
while [[ $tries -lt 5 ]]
do
baidu=`curl -o /dev/null --retry 3 --retry-max-time 30 -s -w %{http_code} baidu.com`
if [ $baidu -ne 200 ] && [ $baidu -ne 301 ]
then
baidu=31m失败
printf "当前网络异常，访问百度：\033[${baidu}\033[37m，60秒后重试    \n"
mark=''
markl=''
for ((ratio=240;${ratio}>=0;ratio+=-1))
do
if [ $ratio -ne 240 ]
then
sleep 0.25
fi
ratio_s=$(($ratio/4))
printf " \033[37m等待:[%-30s]%d秒[%c]   \r" "${markl}" "${ratio_s}" "${ch[$(($ratio%4))]}"
markl=${mark:0:$((${#mark}/8+1))}
mark="#${mark}"
done
else
baidu=32m正常
printf "当前网络正常，访问百度：\033[${baidu}\033[37m，即将开始域名检测\n"
break
fi
done
echo -e "\033[35m"当前监控域名：$url
#开始循环
while [[ $tries -lt 5 ]]
do
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
#每x次检测输出1次监控运行统计
if [ $(( $(($zcnum+$cwnum)) % $tjnum )) = 0 ] && [ $(($zcnum+$cwnum)) -ne 0 ]
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
#定时检查域名是否有更新
rm -rf watchdog
git clone --depth 1 $hub watchdog
new_url=`cat ./watchdog/url.list`
if [ $url != $new_url ]
then
url=$new_url
#获取到新域名，重置统计数据
cwnum=0
zcnum=0
echo -e "\033[35m"更新域名为：$url
else
echo -e "\033[35m"域名无变化，继续监控：$url
fi
fi
#监控域名返回code
code=`curl -o /dev/null --retry 3 --retry-max-time 30 -s -w %{http_code} $url`
date=`date +"%m-%d %H:%M:%S"`
#判断域名code
if [ $code -ne 200 ] && [ $code -ne 301 ]
then
#更新报错通知计数
times=$(($times+1))
#更新错误计数
cwnum=$(($cwnum+1))
#更新连续错误计数，超过指定次数更新域名时使用
lxcwhj=$(($lxcwhj+1))
#打印错误文字
echo -e "\033[31m"域名无法正常访问，代码:$code 时间：$date
#判断是否需要推送
if [ $(( $times % $msgtimes )) = 0 ]  && [ $times -ne 0 ] ; then
#推送消息
if [ ! $pushplustokena ]
then
echo 未设置PUSHPLUS-A，跳过本次错误推送任务        
else
#生成推送地址a
msga=http://www.pushplus.plus/send?token=$pushplustokena\&title=${surl}%E7%BD%91%E7%AB%99%E6%8C%82%E4%BA%86\&content=${surl}+%E5%9F%9F%E5%90%8D%E6%8C%82%E4%BA%86%EF%BC%8C%E5%BF%AB%E5%8E%BB%E7%9C%8B%E7%9C%8B%E5%90%A7%EF%BC%81+`date +"%m-%d_%H:%M:%S"`\&template=html
a=`curl -o /dev/null --retry 3 --retry-max-time 30 -s -w %{http_code} $msga`
echo -e "\033[34m"PUSHPLUS-A 本次错误推送已完成！代码：$a           
fi
if [ ! $pushplustokenb ]
then
echo 未设置PUSHPLUS-B，跳过本次错误推送任务        
else
#生成推送地址b
msgb=http://www.pushplus.plus/send?token=$pushplustokenb\&title=${surl}%E7%BD%91%E7%AB%99%E6%8C%82%E4%BA%86\&content=${surl}+%E5%9F%9F%E5%90%8D%E6%8C%82%E4%BA%86%EF%BC%8C%E5%BF%AB%E5%8E%BB%E7%9C%8B%E7%9C%8B%E5%90%A7%EF%BC%81+`date +"%m-%d_%H:%M:%S"`\&template=html
b=`curl -o /dev/null --retry 3 --retry-max-time 30 -s -w %{http_code} $msgb`
echo -e "\033[34m"PUSHPLUS-B 本次错误推送已完成！代码：$b           
fi
#重置报错计数
times=0
temptimes=0
fi
#发现异常待命1分钟后重试
mark=''
markl=''
for ((ratio=240;${ratio}>=0;ratio+=-1))
do
if [ $ratio -ne 240 ]
then
sleep 0.25
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
#重置连续错误计数
times=$temptimes
lxcwhj=0
#访问正常，待命x分钟后重试
mark=''
markl=''
for ((ratio=$(($interval*60*4));${ratio}>=0;ratio+=-1))
do
if [ $ratio -ne $(($interval*60*4)) ]
then
sleep 0.25
fi
ratio_s=$(($ratio/4))
printf " \033[37m等待:[%-30s]%d秒[%c]   \r" "${markl}" "${ratio_s}" "${ch[$(($ratio%4))]}"
markl=${mark:0:$((${#mark}/$(($interval*8))+1))}
mark="#${mark}"
done
fi
#错误次数超过指定次数，自动拉取新域名
if [ $lxcwhj -eq $cwmax ]
then
lxcwhj=0
for ((r=1;${r}<=$maxurl;r+=1))
do
echo 错误次数超过上限，等待更新域名 $date    
rm -rf watchdog
git clone --depth 1 $hub watchdog
new_url=`cat ./watchdog/url.list`
if [ $url != $new_url ]
then
url=$new_url
#获取到新域名，重置统计数据
cwnum=0
zcnum=0
echo
echo -e "\033[35m"更新域名为：$url
break
fi
echo
echo -e "\033[35m"域名未更新，等待30分钟 $date    
mark=''
markl=''
for ((ratio=7200;${ratio}>=0;ratio+=-1))
do
if [ $ratio -ne 7200 ]
then
sleep 0.25
fi
ratio_s=$(($ratio/240))
printf " \033[37m等待:[%-30s]%d分[%c]   \r" "${markl}" "${ratio_s}" "${ch[$(($ratio%4))]}"
markl=${mark:0:$((${#mark}/240+1))}
mark="#${mark}"
done
done
echo 已尝试更新域名，恢复域名检测 $date      
fi
done
#代码结束
