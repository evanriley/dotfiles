set -g fish_greeting
set -gx EDITOR nvim
set -gx XDG_CONFIG_HOME "$HOME/.config"
set -gx PATH ~/bin ~/.local/bin $NPM_PACKAGES/bin ~/.roswell/bin ~/.yarn/bin ~/.cargo/bin ~/.config/emacs/bin /opt/homebrew/bin /opt/homebrew/sbin ~/go/bin /opt/homebrew/opt/grep/libexec/gnubin '/Applications/Sublime Text.app/Contents/SharedSupport/bin' /home/evan/.local/share/bob/nvim-bin $PATH
set -gx GPG_TTY (tty)

# Aliases
alias vim nvim
alias e run-emacs

## get rid of command not found
alias cd.. 'cd ..'

## a quick way to get out of current directory ##
alias .. 'cd ..'
alias ... 'cd ../../../'
alias .... 'cd ../../../../'
alias ..... 'cd ../../../../'
alias .4 'cd ../../../../'
alias .5 'cd ../../../../..'

## easily find ips address
alias myip "curl -6 https://ifconfig.co; echo"

## more util commands
alias ls eza
alias cat bat
alias du dust

## fast clj repl
alias clj-repl 'clj "-J-Dclojure.server.repl={:port 5555 :accept clojure.core.server/repl :server-daemon false}"'

# use pinentry-mac instead of pinentry on macos
if test (uname) = Darwin
    alias pinentry pinentry-mac
end

# mise is an asdf replacement
mise activate fish | source

# use `z` to move around
zoxide init fish | source

# starship prompt
starship init fish | source
