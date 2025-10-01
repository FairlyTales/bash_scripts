#!/usr/bin/env zsh

# change app-shell dev server in .env.local

if [ -z "$1" ]
    then
      printf "Enter the server\n"
      read server

      sed -i '' -E 's/(dev[0-9]-|stage-)/'$server'-/g' /Users/user/Mysky/projects/app_shell/.env.local
      sed -i '' -E 's/(dev[0-9]-|stage-)/'$server'-/g' /Users/user/Mysky/projects/_spend/_spend-master/.env.local
      printf "\nServer URLs in App-Shell and Spend changed to $server\n\n"
    else
      sed -i '' -E 's/(dev[0-9]-|stage-)/'$1'-/g' /Users/user/Mysky/projects/app_shell/.env.local
      sed -i '' -E 's/(dev[0-9]-|stage-)/'$1'-/g' /Users/user/Mysky/projects/_spend/_spend-master/.env.local
      printf "\nServer in App-Shell and Spend changed to $1\n\n"
    fi

printf "Restarting App-Shell and Spend dev servers...\n\n"

DIRNAME=$(dirname "$0")
$DIRNAME/launch_appshell_and_spend_dev_servers.sh