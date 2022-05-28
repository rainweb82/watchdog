hub=`cat ./watchdog/hub.list`
rm -rf watchdog
git clone --depth 1 $hub watchdog
bash ./watchdog/watchdog.sh
