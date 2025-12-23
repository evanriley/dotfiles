[[ $- != *i* ]] && return

export EDITOR="nvim"
export XDG_CONFIG_HOME="$HOME/.config"
export PATH="$HOME/bin:$HOME/.local/bin:$HOME/go/bin:$HOME/.cargo/bin:$PATH"

export FZF_DEFAULT_OPTS="
  --color=fg:#C5C9C7,bg:#090E13,hl:#c4746e
  --color=fg+:#C5C9C7,bg+:#393B44,hl+:#E46876
  --color=info:#c4b28a,prompt:#8a9a7b,pointer:#8a9a7b
  --color=marker:#8a9a7b,spinner:#c4b28a,header:#8ba4b0"

export HISTSIZE=50000
export HISTFILESIZE=100000
export HISTCONTROL=ignoreboth:erasedups # Ignore spaces and duplicates
shopt -s histappend # Append to history, don't overwrite

# This replaces standard Ctrl+R with a fuzzy search window
[ -f /usr/share/fzf/key-bindings.bash ] && source /usr/share/fzf/key-bindings.bash
[ -f /usr/share/bash-completion/bash_completion ] && source /usr/share/bash-completion/bash_completion

set_bash_prompt() {
    local EXIT_CODE=$? # Capture status immediately

    # Blue (Directory): #8ba4b0 -> 139;164;176
    local K_BLUE="\[\033[38;2;139;164;176m\]"

    # Red (Git Branch): #c4746e -> 196;116;110
    local K_RED="\[\033[38;2;196;116;110m\]"

    # Bright Red (Errors): #E46876 -> 228;104;118
    local K_ERR="\[\033[38;2;228;104;118m\]"

    # Green (Success Arrow): #8a9a7b -> 138;154;123
    local K_GREEN="\[\033[38;2;138;154;123m\]"

    # Yellow (Dirty/Jobs): #c4b28a -> 196;178;138
    local K_YELLOW="\[\033[38;2;196;178;138m\]"

    local RESET="\[\033[0m\]"

    local GIT_INFO=""
    if command -v git &>/dev/null; then
        if git rev-parse --is-inside-work-tree &>/dev/null; then
            local BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
            # Muted red for branch name
            GIT_INFO=" ${K_RED}(${BRANCH})${RESET}"

            # Yellow asterisk if modified
            if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
                GIT_INFO="${GIT_INFO}${K_YELLOW}*${RESET}"
            fi
        fi
    fi

    local JOB_INDICATOR=""
    if [ "$(jobs | wc -l)" -gt 0 ]; then
        JOB_INDICATOR=" ${K_YELLOW}⚙${RESET}"
    fi

    # Default: Sage Green Arrow
    local PROMPT_SYMBOL="${K_GREEN}➜${RESET}"

    # Error: Bright Red Arrow with code
    if [ $EXIT_CODE -ne 0 ]; then
        PROMPT_SYMBOL="${K_ERR}➜ [${EXIT_CODE}]${RESET}"
    fi

    # Directory (Sage Blue) + Git + Jobs + Arrow
    PS1="${K_BLUE}\w${RESET}${GIT_INFO}${JOB_INDICATOR} ${PROMPT_SYMBOL} "
}

PROMPT_COMMAND=set_bash_prompt

alias dots='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias vim='nvim'
alias emacs='emacsclient'

alias ..='cd ..'
alias ...='cd ../../'
alias ....='cd ../../../'
alias .....='cd ../../../..'

# Standard Utils (Colorized)
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias ip='ip -c'

alias gsync='doas emaint --auto sync'
alias gupdate='doas emerge --ask --verbose --update --deep --newuse @world'
alias gclean='doas emerge --ask --depclean'
alias glogs='ls -lt /var/tmp/portage/*/*/temp/build.log'

# Clojure REPL
alias clj-repl='clj "-J-Dclojure.server.repl={:port 5555 :accept clojure.core.server/repl :server-daemon false}"'

if command -v zoxide &> /dev/null; then
    eval "$(zoxide init bash)"
    alias cd='z'
fi

if command -v mise &> /dev/null; then
    eval "$(mise activate bash)"
fi
