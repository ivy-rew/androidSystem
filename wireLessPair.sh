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

# https://github.com/saleehk/adb-wifi
npm i adb-wifi
./node_modules/adb-wifi/cli.js
