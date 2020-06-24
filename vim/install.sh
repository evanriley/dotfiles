#!/bin/sh
#
# Install neovim dependencies

if test $(which nvim)
then
  if [[ ! $(pip3 show neovim) ]]
  then
    echo "Installing Python neovim client"
    pip3 install neovim
  else
    echo "Upgrading Python neovim client"
    pip3 install --upgrade neovim
  fi

  # if [[ `gem list -i neovim` = 'false' ]]
  # then
  #   echo "Installing Ruby neovim client"
  #    gem install neovim
  # else
  #   echo "Updating Ruby neovim client"
  #   gem update neovim
  # fi
fi

# Check for vim-plug
if [ ! -f ~/.local/share/nvim/site/autoload/plug.vim ]
then
  echo "Installing vim-plug"
  curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

echo "Installing vim plugins"
nvim +PlugUpgrade +PlugInstall +PlugUpdate +PlugClean! +qa

exit 0
