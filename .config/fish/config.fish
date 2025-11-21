set -g fish_greeting
set -gx EDITOR nvim
set -gx XDG_CONFIG_HOME "$HOME/.config"
set -gx PATH ~/bin ~/.local/bin ~/go/bin ~/.config/emacs/bin ~/.cargo/bin $PATH


alias dots 'git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

alias vim nvim
alias emacs emacsclient

alias cd.. 'cd ..'
alias .. 'cd ..'
alias ... 'cd ../../'
alias .... 'cd ../../../'
alias ..... 'cd ../..//../'

alias ls eza
alias cat bat
alias du dust

alias clj-repl 'clj "-J-Dclojure.server.repl={:port 5555 :accept clojure.core.server/repl :server-daemon false}"'

zoxide init fish | source
mise activate fish | source

# opencode
fish_add_path /home/evan/.opencode/bin
