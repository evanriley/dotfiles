#!/bin/bash

{ 

  basedir=$HOME/.dotfiles
  repourl=https://github.com/evanriley/dotfiles
  savedir=(".config" ".github" "bin", "gnupg")
  current=$(date +"%Y.%m.%d.%H.%M.%S")
  backup=$HOME/.dotfiles_backup/$current

  function dots {
    /usr/bin/git --git-dir="$HOME"/.dotfiles/ --work-tree="$HOME" "$@"
  }

  if [[ ! -x $(command -v git) ]]; then
    echo "Error: Git is not installed!"
    exit 1
  fi

  if [[ -d $basedir ]]; then
    dots pull --quiet --rebase origin master || exit 1
    echo "Updated dotfiles."
  else
    rm -rf "$basedir"
    git clone --bare --quiet --depth=1 "$repourl" "$basedir"
    dots checkout 2>/dev/null
    if [[ $? != 0 ]]; then
      echo "Backing up pre-existing dotfiles to $current."
      mkdir -p "$backup"
      for d in "${savedir[@]}"; do
        [[ -d $HOME/$d ]] && cp -R "$HOME/$d" "$backup"
      done
      dots checkout 2>&1 | grep -E "\s+\." | awk "{print $1}" | xargs -I{} mv {} "$backup/"{}
      dots checkout -f
    fi
    echo "Checked out dotfiles."
    dots config --local status.showUntrackedFiles no
  fi

}
