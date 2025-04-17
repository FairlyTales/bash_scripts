#!/usr/bin/env zsh

# terminates the process by port
# normal and "polite" termination

# "lsof -ti:$1" returns a PID of the process by port
pid=$(lsof -ti:$1)

if [ -z $pid ]
then
    printf "No process on port $1\n"
else
    kill -15 $pid &&
    printf "Process on port $1 terminated\n"
fi