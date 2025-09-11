#!/usr/bin/env zsh

# terminates the process by port
# normal and "polite" termination

# Use mock commands if in test environment
LSOF_CMD=${TEST_TEMP_DIR:+$TEST_TEMP_DIR/lsof}
LSOF_CMD=${LSOF_CMD:-lsof}
KILL_CMD=${TEST_TEMP_DIR:+$TEST_TEMP_DIR/kill}
KILL_CMD=${KILL_CMD:-kill}

# "lsof -ti:$1" returns a PID of the process by port
pid=$($LSOF_CMD -ti:$1)

if [ -z "$pid" ]
then
    printf "No process on port $1\n"
else
    # Handle multiple PIDs by killing only the first one
    first_pid=$(echo "$pid" | head -n1)
    if $KILL_CMD -15 "$first_pid" 2>/dev/null; then
        printf "Process on port $1 terminated\n"
    else
        printf "Failed to terminate process on port $1\n"
    fi
fi