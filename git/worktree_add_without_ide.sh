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
cp /Users/user/Documents/Settings/ide/vs_code,\ cursor/cursor_project_specific_rules.mdc ./.cursor/rules/
