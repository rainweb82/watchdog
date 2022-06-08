source ./config
rm -rf watchdog
git clone --depth 1 $hub watchdog
cp ./watchdog/run.sh run.sh
bash ./watchdog/watchdog.sh
