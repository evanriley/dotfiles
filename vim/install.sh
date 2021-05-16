#!/bin/sh
#
# Install neovim dependencies

if ! command -v nvim -v &> /dev/null
then
  echo "Installing Neovim"
  brew install neovim
else
  echo "Neovim already installed"
fi

# Check for vim-plug
if [ ! -f ~/.local/share/nvim/site/autoload/plug.vim ]
then
  echo "Installing vim-plug"
  curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

echo "Installing vim plugins"
nvim +PackerUpdate +PackerInstall +PackerUpdate +PackerClean! +qa

exit 0
