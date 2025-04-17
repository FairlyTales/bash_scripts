#!/usr/bin/env zsh

# kills the process by port
# immediate and "rude" termination without the cleanup

# "lsof -ti:$1" returns a PID of the process by port
pid=$(lsof -ti:$1)

if [ -z $pid ]
then
    printf "No process on port $1\n"
else
    kill -9 $pid &&
    printf "Process on port $1 terminated\n"
fi