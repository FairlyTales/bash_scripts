#!/usr/bin/env zsh

# push new branch to remote

branch_name=$(git rev-parse --symbolic-full-name --abbrev-ref HEAD)
git push --set-upstream origin $branch_name