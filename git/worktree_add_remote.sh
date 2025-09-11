#!/usr/bin/env zsh

# run fetch and create worktree from already existing branch
# this command should be run from the repository root, not from the master

git fetch || {
    printf "Error: Failed to fetch from remote repository\n" >&2
    exit 1
}

# Check if the branch exists on remote after fetch
if ! git show-ref --verify --quiet "refs/remotes/origin/$1"; then
    printf "Error: Branch '%s' not found on remote repository\n" "$1" >&2
    printf "Please check the branch name or create the branch on remote first\n" >&2
    exit 1
fi

git worktree add "$1" "$1" || {
    printf "Error: Failed to create worktree for branch '%s'\n" "$1" >&2
    printf "The branch may already have a worktree or there may be a naming conflict\n" >&2
    exit 1
}

cd "$1" || {
    printf "Error: Failed to change to worktree directory '%s'\n" "$1" >&2
    exit 1
}

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
