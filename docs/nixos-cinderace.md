# cinderace NixOS Migration

This branch builds a fresh NixOS install for `cinderace`.

## Confirmed Hardware

- OS drive: `/dev/nvme1n1`, Samsung SSD 9100 PRO 2TB
- Media: UUID `63b66b78-4f03-44ab-9a01-ddb98de974cf`, mounted at `/mnt/Media`
- Games: UUID `ccc88ac2-f5bd-48da-b033-03bafbd2c110`, mounted at `/mnt/Games`
- Primary YubiKey: 5C NFC serial `20477902`
- Backup YubiKey: 5C NFC serial `20477782`

## Pre-Install Validation

```bash
nix flake check
nix build .#nixosConfigurations.cinderace.config.system.build.toplevel
```

Build a VM test before touching disks:

```bash
nix build .#nixosConfigurations.cinderace.config.system.build.vm
```

## Backup Before Install

Back up at least:

- `~/.local/share/media-stack`
- `~/.config/homepage`
- `~/.config/recyclarr`
- `~/.config/listenbrainz-mpd`
- `~/.config/discord-rpc`
- SSH/GPG/age material
- browser profile data if desired
- any desired files under `~/sync`

Do not wipe `/dev/nvme0n1` or `/dev/nvme2n1`.

## Disk Install

The disko config wipes `/dev/nvme1n1`.

From NixOS installer media:

```bash
git clone --branch nixos-cinderace git@github.com:evanriley/dotfiles.git /tmp/dotfiles
cd /tmp/dotfiles
sudo nix --experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode disko --flake .#cinderace
sudo nixos-install --flake .#cinderace
```

## YubiKey LUKS Enrollment

After the LUKS device exists, enroll both keys. Plug in only the key being
enrolled for each command.

```bash
sudo systemd-cryptenroll \
  --fido2-device=auto \
  --fido2-with-user-presence=false \
  --fido2-with-user-verification=false \
  /dev/disk/by-partlabel/nixos-cryptroot
```

Repeat once for serial `20477902` and once for serial `20477782`.

Keep a recovery passphrase in a separate slot:

```bash
sudo systemd-cryptenroll --password /dev/disk/by-partlabel/nixos-cryptroot
```

If no-touch enrollment is rejected or unreliable, use touch-required FIDO2:

```bash
sudo systemd-cryptenroll --fido2-device=auto /dev/disk/by-partlabel/nixos-cryptroot
```

The no-touch enrollment is intentionally equivalent to possession-based unlock:
if the enrolled YubiKey is plugged in at boot, systemd-cryptsetup should unlock
without a touch or PIN prompt. The passphrase slot remains the recovery path.

## First Boot Checks

1. Boot with primary YubiKey only.
2. Boot with backup YubiKey only.
3. Boot with no YubiKey and verify recovery passphrase unlock.
4. Install YubiKey age identity files into `/etc/agenix/identities`.
5. Run `sudo nixos-rebuild switch --flake .#cinderace`.
6. Verify Niri, Waybar, swaync, audio, Steam, Tailscale, Syncthing, and media Quadlets.
