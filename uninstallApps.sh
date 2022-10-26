#!/bin/bash

uninstall() {
  app=$1
  read -p "Delete app '${app}' ? [y|n]"
  if [[ $REPLY == "y" ]]; then
    echo "killing ${app}"
    cmd="pm uninstall -k --user 0 ${app}"
    echo "running command on device: '${cmd}'"
    adb shell -t "${cmd}"
  else
    echo "aborted removal off ${app}."
  fi
}

listPkgs() {
  cmd="pm list packages -f"
  adb shell "${cmd}"
}

uninstallMenu() {
  filter=$1
  apps=$(listPkgs)
  if [[ ! -z "$filter" ]]; then
    echo "filtering ${filter}"
    apps=$(listPkgs | grep $filter)
  fi

  OPTIONS=( '!exit' '!filter' '!google' ${apps[@]} )
  echo "SELECT app to uninstall"
  select OPTION in ${OPTIONS[@]}; do
    if [ "$OPTION" == "!exit" ]; then
      break
    elif [ "$OPTION" == "!google" ]; then
      uninstallMenu "google"
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