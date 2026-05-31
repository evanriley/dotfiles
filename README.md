# dotfiles

Personal NixOS and Home Manager configuration.

The first NixOS host is `cinderace`, a desktop workstation using Niri, GDM,
GNOME fallback, Podman media services, and YubiKey-assisted disk and secret
unlocking.

## Layout

- `flake.nix`: flake entry point with dendritic imports
- `flake`: flake outputs and shared project options
- `hosts/cinderace`: NixOS modules for the desktop
- `home/evan`: Home Manager modules for Evan's account
- `home/evan/files`: files linked into Evan's home by Home Manager
- `secrets`: agenix notes and encrypted secrets
- `docs`: detailed host runbooks

This is a normal flake repository, not a bare home-directory checkout. Home
files are installed declaratively by Home Manager.

## Fresh Install

These steps start from a blank machine booted into the NixOS installer.

Connect to the network:

```bash
systemctl start wpa_supplicant
wpa_cli
```

For wired networking, skip that step. Confirm the network works:

```bash
ping -c 3 github.com
```

Clone this branch:

```bash
git clone --branch nixos-cinderace https://github.com/evanriley/dotfiles.git
cd dotfiles
```

Check the flake:

```bash
nix --extra-experimental-features 'nix-command flakes' flake check
```

Partition and format the OS disk. This wipes `/dev/nvme1n1`:

```bash
sudo nix --experimental-features 'nix-command flakes' run github:nix-community/disko -- \
  --mode disko --flake .#cinderace
```

Install NixOS:

```bash
sudo nixos-install --flake .#cinderace
```

Before rebooting, enroll disk unlock methods:

```bash
sudo systemd-cryptenroll \
  --fido2-device=auto \
  --fido2-with-user-presence=false \
  --fido2-with-user-verification=false \
  /dev/disk/by-partlabel/nixos-cryptroot

sudo systemd-cryptenroll --password /dev/disk/by-partlabel/nixos-cryptroot
```

Repeat the FIDO2 enrollment once for the daily YubiKey and once for the backup
YubiKey. Plug in only the key being enrolled.

Reboot:

```bash
sudo reboot
```

## First Boot

Log in as `evan`, clone the repo if it is not already in place, and enter it:

```bash
git clone --branch nixos-cinderace https://github.com/evanriley/dotfiles.git ~/Developer/dotfiles
cd ~/Developer/dotfiles
```

Create YubiKey age identity files:

```bash
ykman list
age-plugin-yubikey --generate --serial <daily-serial> --name cinderace-primary --pin-policy never --touch-policy never > /tmp/yubikey-primary.txt
age-plugin-yubikey --generate --serial <backup-serial> --name cinderace-backup --pin-policy never --touch-policy never > /tmp/yubikey-backup.txt
sudo install -D -m 0600 /tmp/yubikey-primary.txt /etc/agenix/identities/yubikey-primary.txt
sudo install -D -m 0600 /tmp/yubikey-backup.txt /etc/agenix/identities/yubikey-backup.txt
```

Apply the system:

```bash
sudo nixos-rebuild switch --flake .#cinderace
```

Check the desktop and services:

```bash
systemctl --user status waybar.service swaync.service swayidle.service
systemctl --user list-units 'podman-*.service'
```

The longer checklist is in `docs/nixos-cinderace.md`.
