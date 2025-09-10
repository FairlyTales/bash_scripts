#!/usr/bin/env zsh

# kills the process by port
# immediate and "rude" termination without the cleanup

# Use external kill command if KILL_CMD is not set (for test mocking)
KILL_CMD=${KILL_CMD:-kill}

# "lsof -ti:$1" returns PIDs of processes by port
pids=$(lsof -ti:$1)

if [[ -z "$pids" ]]
then
    printf "No process on port $1\n"
else
    # Handle multiple PIDs - kill the first one found
    first_pid=$(echo "$pids" | head -n1)
    $KILL_CMD -9 "$first_pid" 2>/dev/null
    printf "Process on port $1 terminated\n"
fi