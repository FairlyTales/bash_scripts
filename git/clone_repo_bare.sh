#!/usr/bin/env zsh

# $1 - ssh link
# $2 - local repo name
# $3 - package manager

if [ -n "$2" ]
then
    git clone --bare $1 $2
    cd $2
else
    printf "\nSpecify the directory name:\n"
    read directoryname
    printf "\n"
    git clone --bare $1 $directoryname
    cd $directoryname
fi

mkdir .bare
mkdir .project_cursorrules
mv ./* ./.bare
echo "gitdir: ./.bare" > .git

# git clone --bare don't add a refspec to the config, thus we add it manually
echo 'fetch = +refs/heads/*:refs/remotes/origin/*' >> .bare/config

defaultbranch="master"
printf "\nSpecify the master branch name (default is master, if you use GitHub enter main)\n"
read masterbranch
: ${masterbranch:=$defaultbranch}
git worktree add ./$masterbranch $masterbranch
cd ./$masterbranch

if [ -n "$3" ]
then
    $3 install
else
    printf "\n\nSpecify package manager:\n[Y - yarn]\n[N - npm]\n[Enter - none]\n"
        read -k packagemanager
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

printf "\n\nRepository successfully cloned \\(^_^)/, worktree directory structure created, master branch created and set to remote\n\n\nYou can enter a new branch name to create and start working on it or just press enter to finish\n"

DIRNAME=$(dirname "$0")

read branchname
if [ -n "$branchname" ]
then
    $DIRNAME/worktree_add.sh $branchname
fi