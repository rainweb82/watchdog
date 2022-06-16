#!/bin/bash
#Watchdog 直接复制到shell内运行

#v1 实现基本监控
#v2 增加可配置参数
#v3 增加错误推送功能
#v4 增加每日数据推送
#v5 优化输出样式
#v6 增加第2个推送地址支持
#v7 增加等待中的倒计时进度条
#v8 增加错误次数过多后，自动获取新域名功能
#v9 网站正常条件改为判断页面内容
#v9.1 每日推送增加历史错误日志内容
#v9.2 增加当前网络归属地的显示

#读取需监控的域名
url=`cat ./watchdog/url.list`
#读取配置文件
source ./config
clear
#等待进度条
function loading()
{
	ch=('|' '\' '-' '/')
	mark=''
	markl=''
	for ((ratio=$(($1*60*4));$ratio>=0;ratio+=-1))
	do
		if [ $ratio -ne $(($1*60*4)) ]
		then
			sleep 0.25
		fi
		ratio_s=$(($ratio/4))
		printf " \033[39m等待:[%-30s]%d秒[%c]    \r" "$markl" "$ratio_s" "${ch[$(($ratio%4))]}"
		markl=${mark:0:$((${#mark}/($1*60/30*4)+1))}
		mark="#$mark"
	done
	printf "%-50s\r"
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
nowmsg=http://www.pushplus.plus/send?token=$1$2
nowmsgcode=`curl -o /dev/null --retry 3 --retry-max-time 30 -s -w %{http_code} $nowmsg`
echo -e "\033[34m"本次PUSHPLUS推送已完成！代码:$nowmsgcode
}
#获取本机ip归属地信息
function ipp
{
strA="`curl --retry 3 --retry-max-time 30 -L -s ip38.com`"
result=$(echo "$strA" | egrep -o "(<font color=#FF0000>)(.*)(font>)")
ipp="`echo ${result:20:$((${#result}-27))}`"
uipp="`urlEncode $ipp`"
}
autograph="%3Cbr+%2F%3E%3Cbr+%2F%3E%E6%9C%AC%E9%80%9A%E7%9F%A5+By%EF%BC%9Agithub.com%2Frainweb82%2Fwatchdog"
#检测代码开始
zcnum=0
cwnum=0
lxcwhj=0
issend=0
wrong=''
tstart=`date '+%s'`
#推送容错时间计算
times=$(($msgtimes-$err))
temptimes=$times
jjurl $url
printf " 网络检测中，请稍后... \r"
while [[ $tries -lt 5 ]]
do
	baidu=`curl -o /dev/null --retry 3 --retry-max-time 30 -s -w %{http_code} baidu.com`
	if [ $baidu -ne 200 ] && [ $baidu -ne 301 ]
	then
		baidu=31m失败
		printf "\033[39m网络异常，访问百度:\033[$baidu\033[39m，60秒后重试\n"
		loading 1
	else
		baidu=32m正常
		printf "\033[39m网络正常，访问百度:\033[$baidu\033[39m，即将开始域名检测\n"
		ipp
		echo -e "\033[39m"网络位置：$ipp
		break
	fi
done
echo -e "\033[35m"监控域名:$url
#开始循环
while [[ $tries -lt 5 ]]
do
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
		echo -e "\033[35m"已检测:$(($zcnum+$cwnum))次 正常:$zcnum次 错误:$cwnum次 运行:$day天$hour小时$min分$sec秒
	fi
	#判断是否发送每日推送
	if [ $nowtime -eq $daypost ] && [ $issend -eq 1 ]
	then
		nowmsg=\&title=$surl%E7%9B%91%E6%8E%A7%E6%97%A5%E6%8A%A5\&content=%E7%9B%91%E6%8E%A7%E5%9F%9F%E5%90%8D%EF%BC%9A$surl%3Cbr+%2F%3E%E7%B4%AF%E8%AE%A1%E7%9B%91%E6%8E%A7%EF%BC%9A$(($zcnum+$cwnum))%E6%AC%A1+%E3%80%90%E6%AD%A3%E5%B8%B8%EF%BC%9A$zcnum%E6%AC%A1%EF%BC%8C%E9%94%99%E8%AF%AF%EF%BC%9A$cwnum%E6%AC%A1%E3%80%91%3Cbr+%2F%3E%E8%BF%90%E8%A1%8C%E6%97%B6%E9%97%B4%EF%BC%9A$day%E5%A4%A9$hour%E5%B0%8F%E6%97%B6$min%E5%88%86$sec%E7%A7%92%3Cbr+%2F%3E%E7%BD%91%E7%BB%9C%E5%BD%92%E5%B1%9E%EF%BC%9A$uipp%3Cbr+%2F%3E`date +"%m-%d_%H:%M:%S"`%3Cbr+%2F%3E$wrong$autograph\&template=html
		if [ ! $pushplustokena ]
		then
			echo -e "\033[34m"未设置PUSHPLUS-A，跳过本次每日推送任务
		else
			sendmsg $pushplustokena $nowmsg
		fi
		if [ ! $pushplustokenb ]
		then
			echo -e "\033[34m"未设置PUSHPLUS-B，跳过本次每日推送任务
		else
			nsendmsg $pushplustokenb $nowmsg
		fi
		issend=0
		#定时检查域名是否有更新
		rm -rf watchdog
		git clone --depth 1 $hub watchdog --quiet
		new_url=`cat ./watchdog/url.list`
		if [ $url != $new_url ]
		then
			url=$new_url
			#获取到新域名，重置统计数据
			cwnum=0
			zcnum=0
			wrong=''
			jjurl $url
			echo -e "\033[35m"更新域名为:$url
		else
			echo -e "\033[35m"域名无变化，继续监控:$url
		fi
		#更新运行文件
		cp ./watchdog/run.sh run.sh
	fi
	date=`date +"%m-%d %H:%M:%S"`
	#判断网站源码是否包含指定内容
	strA="`curl --retry 3 --retry-max-time 30 -L -s -w %{http_code} $url`"
	result=$(echo $strA | grep "$rtit" -a)
	code=${strA:$((${#strA}-3))}
	if [ "$result" != "" ]
	then
		#打印正常文字
		echo -e "\033[32m"网站正常,内容含:$rtit 代码:$code $date
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
		echo -e "\033[31m"网站异常,内容无指定文字 代码:$code $date
		#判断是否需要推送
		if [ $(( $times % $msgtimes )) = 0 ] && [ $times -ne 0 ] ; then
			#推送消息
			nowmsg=\&title=$surl%E7%BD%91%E7%AB%99%E6%8C%82%E4%BA%86\&content=$surl+%E5%9F%9F%E5%90%8D%E6%8C%82%E4%BA%86%EF%BC%8C%E5%BF%AB%E5%8E%BB%E7%9C%8B%E7%9C%8B%3Cbr+%2F%3E%E7%BD%91%E7%BB%9C%E5%BD%92%E5%B1%9E%EF%BC%9A$uipp%3Cbr+%2F%3E`date +"%m-%d_%H:%M:%S"`$autograph\&template=html
			if [ ! $pushplustokena ]
			then
				echo -e "\033[34m"未设置PUSHPLUS-A，跳过本次错误推送任务
			else
				sendmsg $pushplustokena $nowmsg
			fi
			if [ ! $pushplustokenb ]
			then
				echo -e "\033[34m"未设置PUSHPLUS-B，跳过本次错误推送任务
			else
				sendmsg $pushplustokenb $nowmsg
			fi
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
			echo -e "\033[31m"错误次数超过上限，等待更新域名 $date
			rm -rf watchdog
			git clone --depth 1 $hub watchdog --quiet
			new_url=`cat ./watchdog/url.list`
			if [ $url != $new_url ]
			then
				url=$new_url
				#获取到新域名，重置统计数据
				cwnum=0
				zcnum=0
				wrong=''
				jjurl $url
				echo -e "\033[35m"更新域名为:$url
				break
			fi
			echo -e "\033[35m"域名未更新，等待30分钟 $date
			loading 30
		done
		echo -e "\033[39m"重新开始域名检测 $date
	fi
done
#代码结束
