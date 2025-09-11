#!/usr/bin/env zsh

# change app-shell dev server in .env.local

if [ -z "$1" ]
    then
      printf "Enter the server number\n"
      read serverNumber

      sed -i '' s/dev\[0-9]\/dev$serverNumber/g /Users/user/Mysky/projects/app_shell/.env.local
      sed -i '' s/dev\[0-9]\/dev$serverNumber/g /Users/user/Mysky/projects/_spend/_spend-master/.env.local
      printf "\nDev server URLs in App-Shell and Spend changed to $serverNumber\n\n"
    else
      sed -i '' s/dev\[0-9]\/dev$1/g /Users/user/Mysky/projects/app_shell/.env.local
      sed -i '' s/dev\[0-9]\/dev$1/g /Users/user/Mysky/projects/_spend/_spend-master/.env.local
      printf "\nDev server in App-Shell and Spend changed to $1\n\n"
    fi

printf "Restarting App-Shell and Spend dev servers...\n\n"

DIRNAME=$(dirname "$0")
$DIRNAME/launch_appshell_and_spend_dev_servers.sh