#!/usr/bin/env zsh

# create worktree from current branch
# this command should be run from the branch you want to create a worktree from

git fetch &&
git worktree add ../$1 &&
cd ../$1 &&

if [ -n "$2" ]
then
    printf "\nUsing ${2} to install dependencies...\n\n"
    $2 install
else
    printf "\nPackage manager not specified, using yarn to install dependencies...\n\n"
    yarn install;
fi

[ -f ../.env.auth ] && cp ../.env.auth ./.env.auth
[ -f ../.env.local ] && cp ../.env.local ./.env.local
[ -f ../.env ] && cp ../.env ./.env
[ -d ../.gemini ] && cp -a ../.gemini ./.gemini
[ -d ../.mcp_configs ] && cp -R ../.mcp_configs ./.mcp_configs
[ -f ../.aider.conf.yml ] && cp -a ../.aider.conf.yml ./

DIRNAME=$(dirname "$0")
$DIRNAME/../ide/launch_current_ide_in_pwd.sh
