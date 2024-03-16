set -g fish_greeting
set -gx EDITOR nvim
set -gx PATH ~/bin ~/.local/bin $NPM_PACKAGES/bin ~/.roswell/bin ~/.yarn/bin ~/.cargo/bin ~/.config/emacs/bin /opt/homebrew/bin  /opt/homebrew/sbin ~/go/bin /opt/homebrew/opt/grep/libexec/gnubin '/Applications/Sublime Text.app/Contents/SharedSupport/bin' /home/evan/.local/share/bob/nvim-bin $PATH
set -gx GPG_TTY (tty)
## use asdf direnv plugin and hook into it
direnv hook fish | source

#source zoxide
zoxide init fish | source

# Aliases
alias vim 'nvim'
alias e  'run-emacs'

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
alias ls 'eza'
alias cat 'bat'
alias du 'dust'

## fast clj repl
alias clj-repl 'clj "-J-Dclojure.server.repl={:port 5555 :accept clojure.core.server/repl :server-daemon false}"'

# use pinentry-mac instead of pinentry on macos
if test (uname) = "Darwin"
  alias pinentry 'pinentry-mac'
end

# iTerm2 (on MacOS) has a nice tmux intergration. This commands just make it easier to use.
if test (uname) = "Darwin"
  # the -CC argument is take advantage of iTerm2's tmux features
 function tm # either create a new session or attach to if possible. "-A" makes new behave like attach-session if the session-name already exist
    if [ -z "$argv" ];
      tmux -CC new -A -s main
    else
      tmux -CC new -A -s $argv
    end
 end

  function remote-dev
    if [ -z "$argv" ]; # connects to a remote developer server through eternal terminal. Requires tailscale installation (server is the MagicDNS name for my server).
      et -c "tmux -CC new -A -s main" server
    else
      et -c "tmux -CC new -A -s main" $argv
    end
  end
end

# Kanagawa Theme
set -l foreground DCD7BA normal
set -l selection 2D4F67 brcyan
set -l comment 727169 brblack
set -l red C34043 red
set -l orange FF9E64 brred
set -l yellow C0A36E yellow
set -l green 76946A green
set -l purple 957FB8 magenta
set -l cyan 7AA89F cyan
set -l pink D27E99 brmagenta

# Syntax Highlighting Colors
set -g fish_color_normal $foreground
set -g fish_color_command $cyan
set -g fish_color_keyword $pink
set -g fish_color_quote $yellow
set -g fish_color_redirection $foreground
set -g fish_color_end $orange
set -g fish_color_error $red
set -g fish_color_param $purple
set -g fish_color_comment $comment
set -g fish_color_selection --background=$selection
set -g fish_color_search_match --background=$selection
set -g fish_color_operator $green
set -g fish_color_escape $pink
set -g fish_color_autosuggestion $comment

# Completion Pager Colors
set -g fish_pager_color_progress $comment
set -g fish_pager_color_prefix $cyan
set -g fish_pager_color_completion $foreground
set -g fish_pager_color_description $comment

source ~/.asdf/asdf.fish
mise activate fish | source

starship init fish | source
