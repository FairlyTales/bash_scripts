#!/usr/bin/env zsh

# List all local branches except master and main
branchArray=($(git for-each-ref --format='%(refname:short)' refs/heads/ | grep -vE '^(master|main)$'))
branchArrayLength=${#branchArray[@]}

if [ $branchArrayLength -eq 0 ]
then
    printf "\nNo branches to delete (other than master/main).\n\n"
    exit 0
fi

printf "\nList of branches to delete:\n\n"
for (( i=1; i<=${branchArrayLength}; i++ )); do
    printf "[$i] $branchArray[i]\n"
done

printf "\nEnter index of the branch to delete it or press Enter to cancel:\n\n"
read -r branchIndex

if [ -z "$branchIndex" ]
then
    printf "\nCancelled.\n\n"
    exit 0
fi

if ! [[ "$branchIndex" =~ ^[0-9]+$ ]] || [ $branchIndex -lt 1 ] || [ $branchIndex -gt $branchArrayLength ]
then
    printf "\nError. Invalid index.\n\n"
    exit 1
fi

branchToDelete=${branchArray[$branchIndex]}

# Prevent deletion of the currently checked-out branch
currentBranch=$(git branch --show-current)
if [ "$branchToDelete" = "$currentBranch" ]; then
    printf "\nError: Cannot delete the currently checked-out branch ('$currentBranch').\n\n"
    exit 1
fi

git branch -d "$branchToDelete"
if [ $? -ne 0 ]; then
    printf "\nBranch not fully merged. Force delete? (y/N): "
    read -r forceDelete
    if [[ "$forceDelete" =~ ^[Yy]$ ]]; then
        git branch -D "$branchToDelete"
    else
        printf "\nCancelled.\n\n"
        exit 0
    fi
fi

printf "\nUpdated branch list:\n\n"
git branch 