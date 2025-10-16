#!/usr/bin/env zsh

# show list of current worktrees with indexes and let user
# enter an index to delete worktree and corresponding branch
# then delete worktree and branch, then update master branch

# git worktree list returns a string
worktreeListString=$(git worktree list)

# git for-each-ref returns an array of all the refs, then we filter out master
refArray=($(git for-each-ref  --format="%(refname:short)" refs/heads/ | grep -v "^master$" | grep -v "^main$"))
refArrayLength=${#refArray[@]}

worktreeArray=()

printf "\nList fo worktrees:\n\n"

# in bash array starts from 0 idx, but in zsh they start from 1
for (( i=1; i<=${refArrayLength}; i++ ));
do
    # we display only refs with names present in the worktree list string
    if [[ $worktreeListString == *$refArray[i]* ]]
    then
        worktreeArray+=("$refArray[i]")
        printf "[$i] $refArray[i]\n"
    fi
done
printf "\n\nEnter index of the tree to delete it or press enter to cancel:\n\n"

read -r treeIndex

if [ -z $treeIndex ]
then

else
    if [ -z $refArray[$treeIndex] ]
    then
        printf "\nError. No ref with such index found\n\n"
    else
        if [[ $(echo ${worktreeArray[@]} | fgrep -w $refArray[$treeIndex]) ]]
        then
            printf "\nCleaning $refArray[$treeIndex] branch before deletion...\n\n"
            originalDir=$(pwd)
            cd "$originalDir/$refArray[$treeIndex]" && git reset --hard HEAD && git clean -fd && cd "$originalDir"

            printf "\nDeleting $refArray[$treeIndex] branch and worktree...\n\n"

            git worktree remove $refArray[$treeIndex] &&
            git branch -D $refArray[$treeIndex] &&
            
            DIRNAME=$(dirname "$0") &&
            $DIRNAME/get_list_of_worktrees.sh
        else
            printf "\nError. No worktree with such index found\n\n"
        fi
    fi
fi