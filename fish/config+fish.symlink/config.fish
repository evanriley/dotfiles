starship init fish | source

set -x PROJECTS ~/Code

set -x PATH /Users/evan/.nimble/bin:$PATH
set -x PATH "/usr/local/opt/llvm/bin:$PATH"

set -x GOPATH ~/Code/go
set -x GOROOT /usr/local/opt/go/libexec
set -x PATH "$GOPATH/bin:$PATH"
set -x PATH $PATH:$GOROOT/bin

set -x PATH ./bin:/usr/local/bin:/usr/local/sbin:$ZSH/bin:$PATH
set -x MANPATH /usr/local/man:/usr/local/mysql/man:/usr/local/git/man:$MANPATH
