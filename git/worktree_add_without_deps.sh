#!/usr/bin/env zsh

git worktree add ../$1
cd ../$1

cp ../.env.auth ./.env.auth
cp ../.env.local ./.env.local
cp ../.env ./.env
cp -a ../.gemini ./.gemini

# Cursor rules are under git from 28.05.2025
# mkdir -p ./.cursor/rules
# cp -a /Users/user/Documents/Settings/ide/vs_code,cursor/cursor_general_project_rules/ ./.cursor/rules/ # universal rules
# cp -a ../.project_cursorrules/ ./.cursor/rules/ # project specific rules

cp -a ../.aider.conf.yml ./ # aider rules

DIRNAME=$(dirname "$0")
$DIRNAME/../ide/launch_current_ide_in_pwd.sh