if not status is-interactive
    return
end

set -gx SHELL /usr/bin/fish
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx ZVM_INSTALL $HOME/.zvm/self

# Colors for the current darkman mode. Absent until darkman has run at least
# once, in which case fzf keeps its own defaults. Read at shell startup only, so
# shells opened before a mode change keep the previous palette.
set -l state_root $XDG_STATE_HOME
test -n "$state_root"; or set state_root $HOME/.local/state
set -l fzf_colors $state_root/darkman/fzf.fish
if test -r $fzf_colors
    source $fzf_colors
end

set -g fish_greeting

alias fastfetch='fastfetch --config ~/.config/fastfetch/config.jsonc'
alias vim=nvim

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias ip='ip -c'
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'

alias clj-repl='clj "-J-Dclojure.server.repl={:port 5555 :accept clojure.core.server/repl :server-daemon false}"'

function mkcd --description 'Create a directory and enter it'
    if test (count $argv) -ne 1
        echo 'usage: mkcd DIRECTORY' >&2
        return 2
    end

    mkdir -p -- $argv[1]; and cd -- $argv[1]
end

function serve --description 'Serve the current directory over HTTP'
    set -l port 8000
    if test (count $argv) -gt 0
        set port $argv[1]
    end

    python3 -m http.server $port
end

if command -q fzf
    fzf --fish | source
end

if command -q zoxide
    zoxide init fish | source
end

if command -q direnv
    direnv hook fish | source
end

if command -q mise
    mise activate fish | source
end
