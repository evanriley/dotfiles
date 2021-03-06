# evanriley's dotfiles

Your dotfiles are how you personalize your system. These are mine.

Fork from [holman](https://github.com/holman/dotfiles) a very long time ago

## install

Run this:

```sh
git clone git@github.com:evanriley/dotfiles.git ~/.dotfiles/
cd ~/.dotfiles
script/bootstrap
```

This will symlink the appropriate files in `.dotfiles` to your home directory.
Everything is configured and tweaked within `~/.dotfiles`.

The main file you'll want to change right off the bat is `zsh/zshrc.symlink`,
which sets up a few paths that'll be different on your particular machine.

`dot` is a simple script that installs some dependencies, sets sane macOS
defaults, and so on. Tweak this script, and occasionally run `dot` from
time to time to keep your environment fresh and up-to-date. You can find
this script in `bin/`.
