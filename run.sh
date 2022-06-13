#!/bin/bash
source ./config
rm -rf watchdog
echo 正在更新脚本，请稍后...
git clone --depth 1 $hub watchdog --quiet
cp ./watchdog/run.sh run.sh
bash ./watchdog/watchdog.sh
