#!/usr/bin/env zsh

# Detect the default branch from the remote HEAD
default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
if [ -z "$default_branch" ]; then
    git remote set-head origin --auto &>/dev/null
    default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
fi

# git worktree list returns a string
worktreeList=$(git worktree list)

# git for-each-ref returns an array of all the refs, then we filter out the default branch
refArray=($(git for-each-ref  --format="%(refname:short)" refs/heads/ | grep -v "^${default_branch}$"))
refArrayLength=${#refArray[@]}

isAnyTreePresent=

printf "\n"

# in bash array starts from 0 idx, but in zsh they start from 1
for (( i=1; i<=${refArrayLength}; i++ ));
do

    # we display only refs with names present in the worktree list string
    if [[ $worktreeList == *"[$refArray[i]]"* ]]
    then
        printf "$refArray[i]\n"
        isAnyTreePresent=true
    fi
done

if [ $isAnyTreePresent ]
then
    printf "\n"
else
    printf "There are no worktrees\n"
fi