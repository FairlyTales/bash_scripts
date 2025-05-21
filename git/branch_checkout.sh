#!/usr/bin/env zsh

# List all local branches
branchArray=($(git for-each-ref --format='%(refname:short)' refs/heads/))
branchArrayLength=${#branchArray[@]}

if [ $branchArrayLength -eq 0 ]
then
    printf "\nNo branches to checkout.\n\n"
    exit 0
fi

printf "\nList of branches to checkout:\n\n"
for (( i=1; i<=${branchArrayLength}; i++ )); do
    printf "[$i] $branchArray[i]\n"
done

printf "\nEnter index of the branch to checkout it or press Enter to cancel:\n\n"
read -r branchIndex

if [ -z "$branchIndex" ]
then
    printf "Cancelled.\n\n"
    exit 0
fi

if ! [[ "$branchIndex" =~ ^[0-9]+$ ]] || [ $branchIndex -lt 1 ] || [ $branchIndex -gt $branchArrayLength ]
then
    printf "Error. Invalid index.\n\n"
    exit 1
fi

branchToCheckout=${branchArray[$branchIndex]}

git checkout "$branchToCheckout"
