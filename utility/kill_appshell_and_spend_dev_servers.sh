#!/usr/bin/env zsh

# terminate mysky app-shell and spend on ports 3000 and 3001
# normal and "polite" termination

printf "Attempting to terminate:\nMySky AppShell on port 3000...\nMySky Spend on port 3001...\n\n"

app_shell_pid=$(lsof -Pi :3000 -sTCP:LISTEN -t)
spend_pid=$(lsof -Pi :3001 -sTCP:LISTEN -t)

if [ -z $app_shell_pid ] && [ -z $spend_pid ]
then
    printf "No processes are running on port 3000 and 3001\n\n"
fi

if [ ! -z $app_shell_pid ]
then
    printf "Terminating current process on port 3000...\n"
    kill -15 $app_shell_pid
    until kill -s 0 "$app_shell_pid" 2>/dev/null; do sleep 1; done
    printf "Process on port 3000 terminated\n"
fi

if [ ! -z $spend_pid ]
then
    printf "Terminating current process on port 3001...\n"
    kill -15 $spend_pid
    until kill -s 0 "$spend_pid" 2>/dev/null; do sleep 1; done
    printf "Process on port 3001 terminated\n"
fi