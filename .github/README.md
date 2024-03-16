# Setup on macOS

1. Install Homebrew

```shell
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2. Install yadm

```shell
brew install yadm
```


3. Clone repo

```shell
yadm clone https://github.com/evanriley/dotfiles.git
```

4. Setup symlinks

```shell
yadm alt
```

5. Bootstrap with yadm
```shell
yadm bootstrap
```

Restart & Enjoy


# Setup on Fedora (39)

1. Install yadm

```shell
sudo dnf config-manager --add-repo https://download.opensuse.org/repositories/home:TheLocehiliosan:yadm/Fedora_39/home:TheLocehiliosan:yadm.repo
sudo dnf install yadm
```

2. Clone repo

```shell
yadm clone https://github.com/evanriley/dotfiles.git
```

4. Setup symlinks

```shell
yadm alt
```

5. Bootstrap with yadm
```shell
yadm bootstrap
```
