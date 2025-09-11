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
mv ./* ./.bare
echo "gitdir: ./.bare" > .git

# Store the project name for worktree naming
if [ -n "$2" ]
then
    projectname="$2"
else
    projectname="$directoryname"
fi

defaultbranch="master"
printf "\nSpecify the master branch name (default is master, if you use GitHub enter main)\n"
read masterbranch

if [ -z "$masterbranch" ]; then
    masterbranch="$defaultbranch"
fi

printf "Default branch is set to: $defaultbranch\n\n"

# git clone --bare don't add a refspec to the config, thus we add it manually
echo '        fetch = +refs/heads/*:refs/remotes/origin/*
[branch "'$masterbranch'"]
	remote = origin
	merge = refs/heads/'$masterbranch'
	vscode-merge-base = origin/'$masterbranch'' >> .bare/config

git fetch origin
git worktree add ./${projectname}-${masterbranch} origin/$masterbranch
cd ./${projectname}-${masterbranch}
git checkout $masterbranch

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
if [ -n "$username" ]; then
    git config user.name "$username"
fi

printf "\nType user email or press Enter to use global:\n"
read useremail
if [ -n "$useremail" ]; then
    git config user.email "$useremail"
fi

printf "\nRepository successfully cloned \\(^_^)/, worktree directory structure created, master branch created and set to remote\n\n\nYou need to manually add Claude Code, Gemini CLI, Cursor and aider configs to this new project\n"
