#!/usr/bin/env zsh

# launch or relaunch mysky app-shell and spend
# ports are 3000 and 3001 accordingly

printf "Launching:\nMySky AppShell on port 3000...\nMySky Spend on port 3001...\n\n"

DIRNAME=$(dirname "$0")

$DIRNAME/launch_appshell_dev_server.sh &
$DIRNAME/launch_spend_dev_server.sh &