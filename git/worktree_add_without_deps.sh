#!/usr/bin/env zsh

git worktree add ../$1
cd ../$1

cp ../.env.auth ./.env.auth
cp ../.env.local ./.env.local

mkdir -p ./.cursor/rules
cp -a /Users/user/Documents/Settings/ide/vs_code,cursor/_cursor_general_project_rules/ ./.cursor/rules/ # universal rules
cp -a ../.project_cursorrules/ ./.cursor/rules/ # project specific rules

cp -a /Users/user/Documents/Settings/ide/vs_code,cursor/.aider.conf.yml ./ # aider rules

DIRNAME=$(dirname "$0")
$DIRNAME/../ide/launch_current_ide_in_pwd.sh