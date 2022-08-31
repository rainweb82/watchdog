#!/bin/bash

#读取配置文件
source ./config

#等待进度条
function loading()
{
sleep $(($1*60))
}
#生成简化url
function jjurl()
{
url_h="${1//www./}"&&url_h="${url_h//https:\/\//}"&&url_h="${url_h//http:\/\//}"
url_s=$((${#url_h}/2-1))
surl=${url_h:0:url_s}**${url_h:$((${#url_h}-${url_s}))}
}
#urlEncode编码
function urlEncode() {
	local length="${#1}"
	for (( i = 0; i < length; i++ )); do
		local c="${1:i:1}"
		case $c in
			[a-zA-Z0-9.~_-]) printf "$c" ;;
			*) printf "$c" | xxd -p -c1 | while read x;do printf "%%%s" "$x";done
		esac
	done
}
#Pushplus推送
function sendmsg()
{
tokentimes=0
if [[ $pushplustoken == "" ]]
then
    echo 未设置PUSHPLUS，跳过本次推送任务
else
for token in $pushplustoken
do
	tokentimes=$(($tokentimes+1))
    nowmsg=http://www.pushplus.plus/send?token=$token$1
    nowmsgcode=`curl -o /dev/null --retry 3 --retry-max-time 30 -s -w %{http_code} $nowmsg`
    echo PUSHPLUS$tokentimes 已完成推送！代码:$nowmsgcode
done
fi
}
#获取本机ip归属地信息
function ipp
{
strA="`curl --retry 3 --retry-max-time 30 -L -s ip38.com`"
result=$(echo "$strA" | egrep -o "(<font color=#FF0000>)(.*)(font>)")
ipp="`echo ${result:20:$((${#result}-27))}`"
uipp="`urlEncode $ipp`"
}
#更新检测url
function updateurl
{
if [[ ! $urlhub ]]
then
	rm -rf watchdog
	git clone --depth 1 $hub watchdog --quiet
	new_url=`cat ./watchdog/url.list`
else
	new_url="`curl --retry 3 --retry-max-time 30 -L -s $urlhub`"
fi
}

#检测代码开始
clear
zcnum=0
cwnum=0
lxcwhj=0
issend=0
wrong=''
tstart=`date '+%s'`
autograph="%3Cbr+%2F%3E%3Cbr+%2F%3Ehttp%3A%2F%2Fgithub.com%2Frainweb82%2Fwatchdog"
#如填写了urlhub，则使用此地址的url进行检测
if [[ ! $urlhub ]]
then
#读取需监控的域名
    url=`cat ./watchdog/url.list`
else
	url="`curl --retry 3 --retry-max-time 30 -L -s $urlhub`"
fi
#推送容错时间计算
times=$(($msgtimes-$err))
temptimes=$times
jjurl $url
echo 网络检测中，请稍后...
while [[ $tries -lt 5 ]]
do
	baidu=`curl -o /dev/null --retry 3 --retry-max-time 30 -s -w %{http_code} baidu.com`
	if [ $baidu -ne 200 ] && [ $baidu -ne 301 ]
	then
		echo 网络异常，访问百度:失败，60秒后重试
		loading 1
	else
		echo 网络正常，访问百度:正常，即将开始域名检测
		ipp
		echo 网络位置：$ipp
		break
	fi
done
if [[ $url != "stop" ]]
then
	echo 监控域名：$url
fi
#开始循环
while [[ $tries -lt 5 ]]
do
	if [[ $url == "stop" ]]
	then
		echo 接受到停止指令，暂停域名监控！
		loading 120
		bash ./watchdog/watchdog.sh
	fi
	#每日推送
	nowtime=$(($(date +%-H)%12))
	if [ $nowtime -ne $daypost ]
	then
		issend=1
	fi
	#运行时间计算
	tend=`date '+%s'`
	second=$(( $tend-$tstart ))
	day=$(( $second/86400 ))
	hour=$(( ($second-$day*86400)/3600 ))
	min=$(( ($second-$day*86400-$hour*3600)/60 ))
	sec=$(( $second-$day*86400-$hour*3600-$min*60 ))
	#每x次检测输出1次监控运行统计
	if [ $(( $(($zcnum+$cwnum)) % $tjnum )) = 0 ] && [ $(($zcnum+$cwnum)) -ne 0 ]
	then
		echo -e "\033[35m""已检测:"$(($zcnum+$cwnum))"次 正常:"$zcnum"次 错误:"$cwnum"次 运行:"$day"天"$hour"小时"$min"分"$sec"秒"
		#定时检查域名是否有更新
		updateurl
		if [ $url != $new_url ]
		then
			url=$new_url
			#获取到新域名，重置统计数据
			cwnum=0
			zcnum=0
			wrong=''
			jjurl $url
			echo 更新域名为:$url
		else
			echo 域名无更新，继续监控:$url
		fi
		#更新运行文件
		cp ./watchdog/run.sh run.sh
	fi
	#判断是否发送每日推送
	if [ $nowtime -eq $daypost ] && [ $issend -eq 1 ]
	then
		if [ ! $wrong ]
		then
			wrongmsg=%3Cbr+%2F%3E%E6%9A%82%E6%97%A0%E9%94%99%E8%AF%AF%E6%97%A5%E5%BF%97
		else
			wrongmsg=%3Cbr+%2F%3E%E9%94%99%E8%AF%AF%E6%97%A5%E5%BF%97%EF%BC%9A${wrong:0:84*20}
		fi
		nowmsg=\&title=$surl%E7%9B%91%E6%8E%A7%E6%97%A5%E6%8A%A5\&content=%E7%9B%91%E6%8E%A7%E5%9F%9F%E5%90%8D%EF%BC%9A$surl%3Cbr+%2F%3E%E7%B4%AF%E8%AE%A1%E7%9B%91%E6%8E%A7%EF%BC%9A$(($zcnum+$cwnum))%E6%AC%A1+%E3%80%90%E6%AD%A3%E5%B8%B8%EF%BC%9A$zcnum%E6%AC%A1%EF%BC%8C%E9%94%99%E8%AF%AF%EF%BC%9A$cwnum%E6%AC%A1%E3%80%91%3Cbr+%2F%3E%E8%BF%90%E8%A1%8C%E6%97%B6%E9%97%B4%EF%BC%9A$day%E5%A4%A9$hour%E5%B0%8F%E6%97%B6$min%E5%88%86$sec%E7%A7%92%3Cbr+%2F%3E%E7%BD%91%E7%BB%9C%E5%BD%92%E5%B1%9E%EF%BC%9A$uipp%3Cbr+%2F%3E`date +"%m-%d_%H:%M:%S"`%3Cbr+%2F%3E$wrongmsg$autograph\&template=html
		sendmsg $nowmsg
		issend=0
	fi
	date=`date +"%m-%d %H:%M:%S"`
	#判断网站源码是否包含指定内容
	strA="`curl --retry 3 --retry-max-time 30 -L -s -w %{http_code} $url`"
	result=$(echo $strA | grep "$rtit" -a)
	code=${strA:$((${#strA}-3))}
	if [ "$result" != "" ]
	then
		#打印正常文字
		echo "正常,内容含『"$rtit"』 代码:"$code" 等待"$interval"分钟" $date
		#更新正常计数
		zcnum=$(($zcnum+1))
		#重置连续错误计数
		times=$temptimes
		lxcwhj=0
		#访问正常，待命x分钟后重试
		loading $interval
	else
		#更新报错通知计数
		times=$(($times+1))
		#更新错误计数
		cwnum=$(($cwnum+1))
		#更新连续错误计数，超过指定次数更新域名时使用
		lxcwhj=$(($lxcwhj+1))
		#记录错误日志，以备每日推送时使用
		wrong="%3Cbr+%2F%3E%E4%BB%A3%E7%A0%81%EF%BC%9A$code+%E6%97%B6%E9%97%B4%EF%BC%9A`date +"%m-%d_%H:%M:%S"`$wrong"
		#打印错误文字
		echo "异常,内容无『"$rtit"』 代码:"$code" 等待1分钟后重试 "$date
		#判断是否需要推送
		if [ $(( $times % $msgtimes )) = 0 ] && [ $times -ne 0 ] ; then
			#推送消息
			nowmsg=\&title=$surl%E7%BD%91%E7%AB%99%E6%8C%82%E4%BA%86\&content=$surl+%E5%9F%9F%E5%90%8D%E6%8C%82%E4%BA%86%EF%BC%8C%E5%BF%AB%E5%8E%BB%E7%9C%8B%E7%9C%8B%3Cbr+%2F%3E%E7%BD%91%E7%BB%9C%E5%BD%92%E5%B1%9E%EF%BC%9A$uipp%3Cbr+%2F%3E`date +"%m-%d_%H:%M:%S"`$autograph\&template=html
			sendmsg $nowmsg
			#重置报错计数
			times=0
			temptimes=0
		fi
		#发现异常待命1分钟后重试
		loading 1
	fi
	#错误次数超过指定次数，自动拉取新域名
	if [ $lxcwhj -eq $cwmax ]
	then
		lxcwhj=0
		for ((r=1;$r<=$maxurl;r+=1))
		do
			echo 错误次数超过上限，等待更新域名 $date
			updateurl
			if [ $url != $new_url ]
			then
				url=$new_url
				#获取到新域名，重置统计数据
				cwnum=0
				zcnum=0
				wrong=''
				jjurl $url
				echo 更新域名为:$url
				break
			fi
			echo 域名无更新，等待30分钟
			loading 30
		done
		echo 重新开始域名检测 $date
	fi
done
#代码结束
