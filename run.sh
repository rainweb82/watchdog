source ./config
rm -rf watchdog
git clone --depth 1 $hub watchdog
cp ./watchdog/run.sh run.sh
cp ./watchdog/config config
bash ./watchdog/watchdog.sh
