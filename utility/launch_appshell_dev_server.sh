#!/usr/bin/env zsh

# launch or relaunch mysky app-shell, port 3000

pid=$(lsof -Pi :3000 -sTCP:LISTEN -t)

if [ ! -z $pid ]
then
    printf "Terminating current process on port 3000...\n"
    kill -15 $pid
    until ! kill -s 0 "$pid" 2>/dev/null; do sleep 1; done
    printf "Process on port 3000 terminated\n"
fi

printf "Launching MySky AppShell on port 3000...\n"
cd /Users/user/Mysky/projects/app_shell
yarn start