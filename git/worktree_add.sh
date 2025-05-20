#!/usr/bin/env zsh

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

cp ../.env.auth ./.env.auth
cp ../.env.local ./.env.local

mkdir -p ./.cursor/rules
cp -a /Users/user/Documents/Settings/ide/vs_code,cursor/cursor_general_project_rules/ ./.cursor/rules/ # universal rules
cp -a ../.project_cursorrules/ ./.cursor/rules/ # project specific rules

cp -a ../.aider.conf.yml ./ # aider rules

DIRNAME=$(dirname "$0")
$DIRNAME/../ide/launch_current_ide_in_pwd.sh