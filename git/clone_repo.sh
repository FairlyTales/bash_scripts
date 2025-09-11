#!/usr/bin/env zsh

if [ -n "$2" ]
then
    git clone $1 $2
    cd $2
else
    printf "\nSpecify the directory name:\n"
    read directoryname
    printf "\n"
    git clone $1 $directoryname
    cd $directoryname
fi

if [ -n "$3" ]
then
    $3 install
else
    printf "\n\nSpecify package manager:\n[y - yarn]\n[n - npm]\n[Enter - none]\n"
    read packagemanager
    case $packagemanager in
    [Yy]* ) yarn install;;
    [Nn]* ) npm install;;
    * ) ;;
    esac
fi

printf "\nType user name or press Enter to use global:\n"
read username
git config user.name $username

printf "\nType user email or press Enter to use global:\n"
read useremail
git config user.email $useremail

printf "\n\nRepository successfully cloned \\(^_^)/\n\nYou need to manually add Claude Code, Gemini CLI, Cursor and aider configs to this new project\n\nDo you want to launch IDE in this project? [Y/n]\n"
read yn

DIRNAME=$(dirname "$0")

case $yn in
    [Yy]* ) $DIRNAME/../ide/launch_current_ide_in_pwd.sh;;
    [Nn]* ) ;;
esac

printf "\n"