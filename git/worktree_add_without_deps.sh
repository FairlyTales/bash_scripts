#!/usr/bin/env zsh

git worktree add ../$1
cd ../$1

[ -f ../.env.auth ] && cp ../.env.auth ./.env.auth
[ -f ../.env.local ] && cp ../.env.local ./.env.local
[ -f ../.env ] && cp ../.env ./.env
[ -d ../.gemini ] && cp -a ../.gemini ./.gemini
[ -d ../.mcp_configs ] && cp -R ../.mcp_configs ./.mcp_configs
[ -f ../.aider.conf.yml ] && cp -a ../.aider.conf.yml ./

DIRNAME=$(dirname "$0")
$DIRNAME/../ide/launch_current_ide_in_pwd.sh
