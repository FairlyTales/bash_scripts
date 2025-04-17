#!/usr/bin/env zsh

# launch or relaunch mysky spend, port 3001

pid=$(lsof -Pi :3001 -sTCP:LISTEN -t)

if [ ! -z $pid ]
then
    printf "Terminating current process on port 3001...\n"
    kill -15 $pid
    until kill -s 0 "$pid" 2>/dev/null; do sleep 1; done
    printf "Process on port 3001 terminated\n"
fi

printf "Launching MySky Spend on port 3001...\n"
cd /Users/user/Mysky/projects/mysky_spend
yarn start