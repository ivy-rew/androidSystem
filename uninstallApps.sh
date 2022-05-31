#!/bin/bash

uninstall() {
    app=$1
    read -p "Delete app ${app}? [y|n]"
    if [[ $REPLY == "y" ]]; then
        echo "killing ${app}"
        cmd="pm uninstall -k --user 0 ${app}"
        echo "running command on device: '${cmd}'"
        adb shell -t "${cmd}"
    else
        echo "aborted removal off ${app}."
    fi
}

uninstallMenu() {
  filter=$1
  apps=$(adb shell 'pm list packages -f')
  if [[ ! -z "$filter" ]]; then
    echo "filtering ${filter}"
    apps=$(adb shell 'pm list packages -f' | grep $filter)
  fi

  OPTIONS=( '!exit' '!google' '!huawei' ${apps[@]} )
  echo "SELECT app to uninstall"
  select OPTION in ${OPTIONS[@]}; do
    if [ "$OPTION" == "!exit" ]; then
        break
    elif [ "$OPTION" == "!google" ]; then
        uninstallMenu "google"
        break
    elif [ "$OPTION" == "!huawei" ]; then
        uninstallMenu "huawei"
        break
    else
        app=$(echo "${OPTION}" | sed 's/.*=//')
        uninstall "${app::-1}"
    fi
  done
}

uninstallMenu