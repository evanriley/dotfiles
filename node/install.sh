brew update
brew install node
if test ! $(which spoof)
then
  sudo npm install spoof -g
fi
