{
  eos.nixosModules.cinderace = [
    (
      { pkgs, ... }:
      {
        services.xserver.enable = true;
        services.desktopManager.gnome.enable = true;
        services.displayManager.gdm.enable = true;

        programs.niri.enable = true;
        programs.dconf.enable = true;
        programs.steam = {
          enable = true;
          remotePlay.openFirewall = true;
          dedicatedServer.openFirewall = true;
        };

        xdg.portal = {
          enable = true;
          extraPortals = with pkgs; [
            xdg-desktop-portal-gnome
            xdg-desktop-portal-gtk
          ];
          config.common.default = "*";
        };

        services.pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
          jack.enable = true;
          wireplumber.enable = true;
        };

        security.rtkit.enable = true;
        services.udisks2.enable = true;
        services.upower.enable = true;
        services.gvfs.enable = true;
        services.tumbler.enable = true;

        services.udev.extraRules = ''
          # Keep cinderace's wired mouse path awake across idle/resume/unlock.
          ACTION=="add|change", SUBSYSTEM=="usb", ATTR{idVendor}=="05e3", ATTR{idProduct}=="0610", TEST=="power/control", ATTR{power/control}="on"
          ACTION=="add|change", SUBSYSTEM=="usb", ATTR{idVendor}=="3367", ATTR{idProduct}=="1964", TEST=="power/control", ATTR{power/control}="on"
        '';

        services.udev.packages = with pkgs; [
          yubikey-personalization
        ];
      }
    )
  ];
}
