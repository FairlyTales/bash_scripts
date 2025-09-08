#!/usr/bin/env zsh

# git worktree list returns a string
worktreeList=$(git worktree list)

# git for-each-ref returns an array of all the refs, then we filter out master
refArray=($(git for-each-ref  --format="%(refname:short)" refs/heads/ | grep -v "^master$" | grep -v "^main$"))
refArrayLength=${#refArray[@]}

isAnyTreePresent=

printf "\n"

# in bash array starts from 0 idx, but in zsh they start from 1
for (( i=1; i<=${refArrayLength}; i++ ));
do

# ЭТОТ ИФ ПРОВЕРЯЕТ НАЛИЧИЕ СТРОКИ В СТРОКЕ, А НЕ ЕЁ ПОЛНОЕ СООТВЕТСТВИЕ, ПОЭТОМУ
# ЕСЛИ ЕСТЬ ВЕТКА "master", ТО ОНА БУДЕТ НАЙДЕНА В ДЕРЕВЕ "master1"
# НАДО БЫ ЗАМЕНИТЬ НА ПОЛНОЕ СООТВЕТСТВИЕ

    # we display only refs with names present in the worktree list string
    if [[ $worktreeList == *$refArray[i]* ]]
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