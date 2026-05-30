# dotfiles

Personal NixOS and Home Manager configuration.

The first NixOS host is `cinderace`, a desktop workstation using Niri, GDM,
GNOME fallback, Podman media services, and YubiKey-assisted disk and secret
unlocking.

## Check

```bash
nix flake check
```

On a machine without Nix installed, run the same check in a container:

```bash
podman run --rm -v "$PWD:/work:Z" -w /work docker.io/nixos/nix:latest sh -lc \
  'git config --global --add safe.directory /work && nix --extra-experimental-features "nix-command flakes" flake check'
```

## Install cinderace

Boot the NixOS installer, connect to the network, clone this repo, and enter it:

```bash
git clone https://github.com/evanriley/dotfiles.git
cd dotfiles
```

Partition and format the target disk:

```bash
sudo nix --experimental-features 'nix-command flakes' run github:nix-community/disko -- \
  --mode disko --flake .#cinderace
```

Install NixOS:

```bash
sudo nixos-install --flake .#cinderace
```

Before rebooting, enroll the YubiKeys and recovery passphrase for the encrypted
root disk. The detailed checklist is in `docs/nixos-cinderace.md`.

## After Install

Copy the age-plugin-yubikey identity files to:

```text
/etc/agenix/identities/
```

Then rebuild normally:

```bash
sudo nixos-rebuild switch --flake .#cinderace
```
