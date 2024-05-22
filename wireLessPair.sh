#!/bin/bash

#? adb pair > use latest adb with pairing capabilities
if [ ! -d "platform-tools" ]; then
    curl -o platformTools.zip https://dl.google.com/android/repository/platform-tools_r34.0.1-linux.zip
    unzip platformTools.zip
    rm platformTools.zip
fi
PATH=$PWD/platform-tools:$PATH

# stop previous attempts to pure tcp/ip connect
adb kill-server

qrCode() {
  # https://github.com/saleehk/adb-wifi
  npm i adb-wifi
  ./node_modules/adb-wifi/cli.js
}

deviceCode() {
  echo "To see your IP on Android; you may disable VPN clients before debugging"
  read -p "IP Address to connect: " ip
  echo "Enter the Port seen in DeveloperOptions > Wifi Debugging > IP Address & Port (not the Device pair pop-up port)"
  read -p "Port to connect: " port
  echo "connecting to: $ip:$port"
  echo "Now open DeveloperOptions > Wifi Debugging > Pair device with pairing code ... enter the in this shell"
  adb pair $ip:$port
  adb connect $ip:$port
  adb devices
}

deviceCode