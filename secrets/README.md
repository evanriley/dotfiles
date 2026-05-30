# Secrets

This tree is reserved for agenix-encrypted secrets. Do not commit plaintext
secrets, SSH private keys, GPG private keys, recovery codes, or Syncthing
contents here.

YubiKey serials are not secret credentials, but they are unnecessary public
device identifiers. Keep exact serials out of committed docs and discover them
locally when provisioning:

```bash
ykman list
```

Generate each YubiKey age identity after `age-plugin-yubikey` is available.
Plug in one key at a time and replace `<serial>` with the local serial shown by
`ykman list`:

```bash
age-plugin-yubikey --generate --serial <serial> --name cinderace-primary --pin-policy never --touch-policy never > /tmp/yubikey-primary.txt
age-plugin-yubikey --generate --serial <serial> --name cinderace-backup --pin-policy never --touch-policy never > /tmp/yubikey-backup.txt
```

Install the identity files on cinderace:

```bash
sudo install -D -m 0600 /tmp/yubikey-primary.txt /etc/agenix/identities/yubikey-primary.txt
sudo install -D -m 0600 /tmp/yubikey-backup.txt /etc/agenix/identities/yubikey-backup.txt
```

List recipients:

```bash
age-plugin-yubikey --list
```

This makes secret decryption possession-based: the matching YubiKey needs to be
plugged in, but it should not require a touch or PIN prompt. If that is too weak
for a secret later, regenerate that key identity with `--pin-policy once`,
`--touch-policy cached`, or `--touch-policy always`, then re-encrypt affected
secrets to the new recipient.
