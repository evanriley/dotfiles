# dotfiles

The active configuration is on `main`. previous setups are preserved on different branches.

Install by cloning the repo to `~/sync/dotfiles` and symlinking the tracked files into `$HOME` and `~/.config`.

One host prerequisite is not satisfiable by symlinking. The `adguardhome`
dinit service publishes DNS on port 53, and rootless podman cannot bind below
`net.ipv4.ip_unprivileged_port_start`. Lower it in `/etc/sysctl.d/`:

    net.ipv4.ip_unprivileged_port_start = 53
