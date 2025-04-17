#!/usr/bin/env zsh

git worktree add ../$1
cd ../$1

cp ../.env.auth ./.env.auth
cp ../.env.local ./.env.local

DIRNAME=$(dirname "$0")
$DIRNAME/../ide/launch_current_ide_in_pwd.sh