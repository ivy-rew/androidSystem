#!/bin/bash

uninstall() {
    param=$1
    app=${param::-1}
    read -p "Delete app ${app}? [y|n]"
    if [[ $REPLY == "y" ]]; then
        echo "killing ${app}"
        cmd="pm uninstall -k --user 0 ${app}"
        echo "running command on device: '${cmd}'"
        adb shell -t "${cmd}"
    else
        echo "aborted remove off ${app}."
    fi
}

uninstallMenu() {
  apps=$(adb shell 'pm list packages -f')
  OPTIONS=( '!exit' ${apps[@]} )1

  echo "SELECT app to uninstall"
  select OPTION in ${OPTIONS[@]}; do
    if [ "$OPTION" == "!exit" ]; then
        break
    else
        app=$(echo "${OPTION}" | sed 's/.*=//')
        uninstall "${app}"
    fi
  done
}

uninstallMenu