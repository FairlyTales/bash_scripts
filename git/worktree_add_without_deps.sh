#!/usr/bin/env zsh

git worktree add ../$1
cd ../$1

cp ../.env.auth ./.env.auth
cp ../.env.local ./.env.local
mkdir -p ./.cursor/rules
cp /Users/user/Documents/Settings/ide/vs_code,\ cursor/cursor_project_specific_rules.mdc ./.cursor/rules/

DIRNAME=$(dirname "$0")
$DIRNAME/../ide/launch_current_ide_in_pwd.sh