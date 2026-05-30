# Secrets

This tree is reserved for agenix-encrypted secrets. Do not commit plaintext
secrets, SSH private keys, GPG private keys, recovery codes, or Syncthing
contents here.

Confirmed YubiKeys:

- Primary: YubiKey 5C NFC, serial `20477902`
- Backup: YubiKey 5C NFC, serial `20477782`

Generate each YubiKey age identity after `age-plugin-yubikey` is available:

```bash
age-plugin-yubikey --generate --serial 20477902 --name cinderace-primary --pin-policy never --touch-policy never > /tmp/yubikey-20477902.txt
age-plugin-yubikey --generate --serial 20477782 --name cinderace-backup --pin-policy never --touch-policy never > /tmp/yubikey-20477782.txt
```

Install the identity files on cinderace:

```bash
sudo install -D -m 0600 /tmp/yubikey-20477902.txt /etc/agenix/identities/yubikey-20477902.txt
sudo install -D -m 0600 /tmp/yubikey-20477782.txt /etc/agenix/identities/yubikey-20477782.txt
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
