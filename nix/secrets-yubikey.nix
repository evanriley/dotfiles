{
  eos.nixosModules.cinderace = [
    (
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          age
          age-plugin-yubikey
          pcsc-tools
          pinentry-curses
          pinentry-gnome3
          yubikey-manager
          yubikey-personalization
        ];

        services.pcscd.enable = true;

        programs.gnupg.agent = {
          enable = true;
          enableSSHSupport = true;
          pinentryPackage = pkgs.pinentry-gnome3;
        };

        age = {
          identityPaths = [
            "/etc/agenix/identities/yubikey-20477902.txt"
            "/etc/agenix/identities/yubikey-20477782.txt"
          ];
        };

        systemd.tmpfiles.rules = [
          "d /etc/agenix 0755 root root -"
          "d /etc/agenix/identities 0700 root root -"
        ];
      }
    )
  ];
}
