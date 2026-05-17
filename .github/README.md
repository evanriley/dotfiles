# dotfiles

Personal dotfiles for the Fedora Atomic / e-os setup on `cinderace`.

Install as a bare Git work tree:

```bash
curl -sL https://raw.githubusercontent.com/evanriley/dotfiles/refs/heads/main/bin/dotinstall.sh | bash
```

The active desktop setup is Niri. Core session helpers are started as user
services from `niri.service.wants`; GNOME remains available as the fallback
desktop and portal provider.
