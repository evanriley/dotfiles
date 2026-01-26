#!/bin/bash

# Configuration
BASEDIR="$HOME/.dotfiles"
REPOURL="https://github.com/evanriley/dotfiles"
SAVEDIR=(".config" ".github" "bin" "gnupg")
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +'%Y.%m.%d.%H.%M.%S')"
BRANCH="before-eos"

# Function Wrapper
function dots {
  /usr/bin/git --git-dir="$BASEDIR/" --work-tree="$HOME" "$@"
}

# 1. Prerequisite Check
if ! command -v git &> /dev/null; then
  echo "Error: Git is not installed."
  exit 1
fi

# 2. Clone or Update
if [ -d "$BASEDIR" ]; then
  echo "Updating existing dotfiles..."
  dots pull --quiet --rebase origin "$BRANCH"
else
  echo "Cloning bare repository ($BRANCH)..."
  # Clean up collision if folder exists but is empty/wrong
  rm -rf "$BASEDIR"

  # Clone specific branch, bare
  git clone --bare --branch "$BRANCH" --depth=1 "$REPOURL" "$BASEDIR"

  # 3. Checkout & Conflict Resolution
  echo "Attempting checkout..."
  dots checkout 2>/dev/null
  if [ $? -ne 0 ]; then
    echo "Conflicts detected. Backing up pre-existing files..."
    mkdir -p "$BACKUP_DIR"

    # Backup known config dirs if they exist
    for d in "${SAVEDIR[@]}"; do
      [ -d "$HOME/$d" ] && cp -R "$HOME/$d" "$BACKUP_DIR/"
    done

    # Note: This relies on English git output.
    dots checkout 2>&1 | grep -E "\s+\." | awk {'print $1'} | xargs -I{} mv {} "$BACKUP_DIR/"{}

    # Retry Checkout
    dots checkout
  fi

  # 4. Final Configuration
  dots config --local status.showUntrackedFiles no
  echo "Dotfiles installed successfully from branch: $BRANCH"
fi
