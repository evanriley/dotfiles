alias reload!='. ~/.zshrc'

alias cls='clear' # Good 'ol Clear Screen command

alias vi='nvim'
alias vim='nvim'


## get rid of command not found ##
alias cd..='cd ..'
 
## a quick way to get out of current directory ##
alias ..='cd ..'
alias ...='cd ../../../'
alias ....='cd ../../../../'
alias .....='cd ../../../../'
alias .4='cd ../../../../'
alias .5='cd ../../../../..'

## Colorize the grep command output for ease of use (good for log files)##
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

alias mkdir='mkdir -pv'

## this one saved by butt so many times ##
alias wget='wget -c'

## honestly this isn't something that should be used...##
alias gac='git add . && git commit -a -m '
alias gl='git pull --prune'
alias glog="git log --graph --pretty=format:'%Cred%h%Creset %an: %s - %Creset %C(yellow)%d%Creset %Cgreen(%cr)%Creset' --abbrev-commit --date=relative"
alias gp='git push origin HEAD'
alias gd='git diff --color | sed "s/^\([^-+ ]*\)[-+ ]/\\1/" | less -r'
alias gc='git commit'
alias gca='git commit -a'
alias gco='git checkout'
alias gcb='git copy-branch-name'
alias gb='git branch'
alias gs='git status -sb'
alias ge='git-edit-new'

#make then enter the dir#
alias mkcd='foo(){ mkdir -p "$1"; cd "$1" }; foo '

##wtf is my ip address...##
alias myip="curl http://ipecho.net/plain; echo"

## copy public ssh key
alias pubkey='pbcopy < ~/.ssh/id_rsa.pub'

## more util commands
alias ls='exa'
alias l='exa -l'
alias ll='exa -l | less'
alias la='exa -la'
alias cat='bat'
