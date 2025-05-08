#
# Terminal settings and plugins
#

# set default git directory to homebrew's git instead of apple's git directory
export PATH=/usr/local/bin:$PATH

# disable adding packageManager field to package.json
export COREPACK_ENABLE_AUTO_PIN=0

# zsh plugins
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source ~/.zsh/powerlevel10k/powerlevel10k.zsh-theme

# powerlevel10k - zsh theme. To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# keybinding for autocomplete (zsh-autosuggestions) with tab key
bindkey '\t' end-of-line

# variables for storing paths to bash script directories used in the aliases
ROOT_SCRIPTS_PATH="/Users/user/bash_scripts"
UTILITY_SCRIPTS_PATH="$ROOT_SCRIPTS_PATH/utility"
GIT_SCRIPTS_PATH="$ROOT_SCRIPTS_PATH/git"
IDE_SCRIPTS_PATH="$ROOT_SCRIPTS_PATH/ide"


# ------------------------------------------------------------------------------------------


#
# Version managers and SDKs
#

# nvm (node version manager) - installed via Brew
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# nvm (node version manager) - if installed directly, not via Brew
#export NVM_DIR="$HOME/.nvm"
#[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
#[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm #bash_completion


# pyenv (python version manager)  - installed via Brew
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# chruby (ruby version manager) - installed via Brew
source /opt/homebrew/opt/chruby/share/chruby/chruby.sh
chruby 3.1.4

# flutter sdk
#export PATH="$PATH:$HOME/flutter/bin"



# ------------------------------------------------------------------------------------------


#
# JS package manager aliases
#

alias n="npm"
alias ns="npm start"
alias ni="npm install"
alias nid="npm install --save-dev"
alias nr="npm uninstall"
alias nt="npm test"

alias y="yarn"
alias н="y"
alias ys="yarn start"
alias yys="yarn && yarn start"
alias ны="ys"
alias yb="yarn build"
alias ya="yarn add"
alias yad="yarn add --dev"
alias yr="yarn remove"
alias yl="yarn lint"
alias ylf="yarn lint --fix"
alias yts="yarn tsc"
alias yp="yarn prettier --write ."
alias yf="yarn tsc && yarn eslint && yarn test"

# Work specific yarn aliases
alias yst="yarn start:templates"
alias yt="yarn playwright test"
alias ytu="yarn test:ui"
alias yte="yarn test:e2e"
alias yti="yarn test:integration"
alias yta="yarn test:a11y"
alias ytau="yarn test:ui-a11y"

alias esl="yarn eslint"
alias eslf="yarn eslint --fix"

alias b="bun"
alias bi="bun install"
alias bs="bun start"
alias bbs="bun install && bun start"
alias bb="bun build"
alias ba="bun add"
alias bad="bun add --dev"
alias br="bun remove"
alias bl="bun lint"
alias blf="bun lint --fix"
alias bts="bun tsc"
alias bt="bun test"

alias v="vite"
alias vs="vite start"

alias r="rush"
alias ra="rush add"
alias ru="rush update --purge"
alias rur="rush update --purge && rush rebuild"
alias rb="rush build"
alias rr="rush rebuild"
alias rc="rush change"



# ------------------------------------------------------------------------------------------


#
# Utility alises
#

# open .zshrc and bash_script directory in VSCode
alias z="code /Users/user/bash_scripts && code -a /Users/user/.zshrc"
alias csettings="code /Users/user/Documents/Settings/ide/vs_code,\ cursor"
alias cs="csettings"


# get list of all active ports
alias ports="lsof -i -n -P"

# terminate the process by port, normal and "polite" termination
alias killport:soft="$UTILITY_SCRIPTS_PATH/killport.sh"
alias killport="killport:soft"

# kill the process by port, immediate and "rude" termination without the cleanup
alias killport:hard="$UTILITY_SCRIPTS_PATH/killport_hard.sh"

# change app-shell dev server in .env.local and restart the dev servers
alias dch="$UTILITY_SCRIPTS_PATH/change_dev_server_appshell_and_spend.sh"

# launch or relaunch mysky app-shell, port 3000
alias l:as="$UTILITY_SCRIPTS_PATH/launch_appshell_dev_server.sh"

# launch or relaunch mysky spend, port 3001
alias l:sp="$UTILITY_SCRIPTS_PATH/launch_spend_dev_server.sh"

# launch or relaunch mysky app-shell and spend, ports 3000 and 3001 accordingly
alias l="$UTILITY_SCRIPTS_PATH/launch_appshell_and_spend_dev_servers.sh"

# terminate mysky app-shell and spend on ports 3000 and 3001, soft termination
alias k:soft="$UTILITY_SCRIPTS_PATH/kill_appshell_and_spend_dev_servers.sh"
alias k="k:soft"

# kill mysky app-shell and spend on ports 3000 and 3001, immediate termination
alias k:hard="$UTILITY_SCRIPTS_PATH/kill_appshell_and_spend_dev_servers.sh"

alias cd.="cd ../"
alias t="touch"
alias m="mkdir"

# ------------------------------------------------------------------------------------------


#
# IDE and simulator aliases
#

# WebStorm
# alias s="$IDE_SCRIPTS_PATH/launch_phpstorm_in_pwd.sh"
alias s="$IDE_SCRIPTS_PATH/launch_webstorm_in_pwd.sh"
alias ы='s'

# VS code
alias c='code ./' # латинская c
alias с='code ./' # кириллическая

# Cursor
alias cr='cursor ./'
alias cc='cursor ./'

# launch local browser tools server for browser tools MCP
alias bt='npx @agentdeskai/browser-tools-server@1.2.0'

# XCode
alias xcode='open -a Xcode'
alias xc='xcode'

# XCode Simulator
alias simulator='open -a Simulator'

# ------------------------------------------------------------------------------------------


#
# Git aliases
#

alias g="git"
alias gp="printf 'command not found, similar commands are:\n\n\tgpl - git pull\n\tgps - git push\n\tgpsf - git push -f\n\nyou can find all available aliases using the command: alias\n'"
alias gs="git status"
alias gb="git branch"
alias gbd="git branch -D"
alias gf="git fetch"
alias gpl="git pull"
alias gply="git pull && yarn"
alias gplys="git pull && yarn && yarn start"
alias gplyts="git pull && yarn && yarn tsc"
alias ga="git add ."
alias gc="git commit -m"
alias gps="git push"
alias gpsn="$GIT_SCRIPTS_PATH/push_new_branch.sh"
alias gpsf="git push -f"
alias gpswip="gpsf && grst && ga"
alias grst="$GIT_SCRIPTS_PATH/reset_soft.sh"
alias gl="git log --pretty=format:\"%C(dim magenta)%h%Creset -%C(dim cyan)%d%Creset %s %C(dim green)(%cr) %C(brightblue)<%an>%Creset\" --abbrev-commit -30"
alias glg="git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(auto)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)'"

# remove all uncommitted changes and delete all untracked files
alias gclean="git reset --hard HEAD && git clean -fd"

# display list of all worktrees excluding master
alias gtl="$GIT_SCRIPTS_PATH/get_list_of_worktrees.sh"

# remove git worktree, delete the corresponding branch and pull master branch
alias gtd="$GIT_SCRIPTS_PATH/worktree_delete.sh"

# remove git worktree and delete the corresponding branch
alias gtdn="$GIT_SCRIPTS_PATH/worktree_delete_no_pull_master.sh"

# clone repo and set it up
alias gcl="$GIT_SCRIPTS_PATH/clone_repo.sh"

# clone bare repo for git worktree usage and set it up
alias gclb="$GIT_SCRIPTS_PATH/clone_repo_bare.sh"

# create new worktree from current directory
alias gta="$GIT_SCRIPTS_PATH/worktree_add.sh"

# create new worktree from current directory without opening ide
alias gtan="$GIT_SCRIPTS_PATH/worktree_add_without_ide.sh"

# create new worktree from current directory without installing dependencies
alias gta:nodeps="$GIT_SCRIPTS_PATH/worktree_add_without_deps.sh"

# fetch branches and create worktree from already existing branch
alias gtar="$GIT_SCRIPTS_PATH/worktree_add_remote.sh"

# git stash
alias gst="git stash"
alias gstl="git stash list"
alias gstp="git stash pop"
alias gsta="git stash apply"
alias gstd="git stash drop"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/user/.lmstudio/bin"
