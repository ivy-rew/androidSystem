#!/bin/bash

uninst=""
uninstall() {
  app=$1
  read -p "Delete app '${app}' ? [y|n]"
  if [[ $REPLY == "y" ]]; then
    echo "killing ${app}"
    cmd="pm uninstall${uninst} --user 0 ${app}"
    echo "running command on device: '${cmd}'"
    echo "${cmd}" >> uninstall.log 
    adb shell -t "${cmd}"
  else
    echo "aborted removal off ${app}."
  fi
}

list=""
listPkgs() {
  cmd="pm list packages ${list}"
  adb shell "${cmd}"
}

pkg() {
  cmd="pm"
  adb shell "${cmd}"
}

uninstallMenu() {
  filter=$1
  apps=$(listPkgs)
  if [[ ! -z "$filter" ]]; then
    echo "filtering ${filter}"
    apps=$(listPkgs | grep $filter)
  fi

  OPTIONS=( '!exit' '!filter' '!pkg:help' '!list:full' '!data:keep' '!google' ${apps[@]} )
  echo "SELECT app to uninstall"
  select OPTION in ${OPTIONS[@]}; do
    if [ "$OPTION" == "!exit" ]; then
      break
    elif [ "$OPTION" == "!google" ]; then
      uninstallMenu "google"
      break
    elif [ "$OPTION" == "!pkg:help" ]; then
      pkg
      break
    elif [ "$OPTION" == "!data:keep" ]; then
      uninst="${uninst} -k"
      uninstallMenu "$filter"
      break
    elif [ "$OPTION" == "!list:full" ]; then
      list="${list} -f"
      uninstallMenu "$filter"
      break
    elif [ "$OPTION" == "!filter" ]; then
      read -p "Search for what? "
      uninstallMenu "$REPLY"
      break
    else
      app=$(echo "${OPTION}" | sed 's/.*=//')
      uninstall "${app}"
    fi
  done
}

uninstallMenu