# cinderace NixOS Migration

This branch builds a fresh NixOS install for `cinderace`.

## Confirmed Hardware

- OS drive: `/dev/nvme1n1`, Samsung SSD 9100 PRO 2TB
- Media: UUID `63b66b78-4f03-44ab-9a01-ddb98de974cf`, mounted at `/mnt/Media`
- Games: UUID `ccc88ac2-f5bd-48da-b033-03bafbd2c110`, mounted at `/mnt/Games`
- Primary YubiKey: YubiKey 5C NFC
- Backup YubiKey: YubiKey 5C NFC

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

- `~/.local/share/media-stack`, including FreshRSS and Lidarr Tidal data
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
git clone --branch nixos-cinderace https://github.com/evanriley/dotfiles.git /tmp/dotfiles
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

Repeat once for the daily YubiKey and once for the backup YubiKey.

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
6. Restore `~/.local/share/media-stack` before starting media services if it
   was not restored as part of the home directory.
7. Verify Niri, Waybar, swaync, audio, Steam, Tailscale, and Syncthing.

Verify the persistent PS5 audio route:

```bash
systemctl --user status ps5-audio-loopback.service
```

Verify the media services and local endpoints:

```bash
systemctl --user status jellyfin.service lidarr.service freshrss.service
curl --fail http://127.0.0.1:8096/health
curl --fail http://127.0.0.1:8686/ping
curl --fail http://127.0.0.1:8082
```

Jellyfin uses host networking so LAN discovery can reach UDP port 7359. After
restoring its configuration, ensure
`~/.local/share/media-stack/jellyfin/config/config/network.xml` does not contain
a stale loopback-only `LocalNetworkAddresses` override.

Lidarr builds from `ghcr.io/hotio/lidarr:pr-plugins`, adds FFmpeg, and mounts
the existing database at `~/.local/share/media-stack/lidarr`. Confirm that the
Tidal plugin loads and that `/downloads/complete/torrents/music` exists inside
the container.
