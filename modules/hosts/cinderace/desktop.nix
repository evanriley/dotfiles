{
  flake.modules.nixos.cinderaceDesktop =
    { pkgs, ... }:
    {
      services = {
        xserver.enable = true;
        desktopManager.gnome.enable = true;
        displayManager.gdm.enable = true;
        pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
          jack.enable = true;
          wireplumber.enable = true;
        };
        udisks2.enable = true;
        upower.enable = true;
        gvfs.enable = true;
        tumbler.enable = true;
        udev = {
          extraRules = ''
            # Keep cinderace's wired mouse path awake across idle/resume/unlock.
            ACTION=="add|change", SUBSYSTEM=="usb", ATTR{idVendor}=="05e3", ATTR{idProduct}=="0610", TEST=="power/control", ATTR{power/control}="on"
            ACTION=="add|change", SUBSYSTEM=="usb", ATTR{idVendor}=="3367", ATTR{idProduct}=="1964", TEST=="power/control", ATTR{power/control}="on"
          '';
          packages = with pkgs; [
            yubikey-personalization
          ];
        };
      };

      programs = {
        niri.enable = true;
        dconf.enable = true;
        steam = {
          enable = true;
          remotePlay.openFirewall = true;
          dedicatedServer.openFirewall = true;
        };
      };

      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-gnome
          xdg-desktop-portal-gtk
        ];
        config.common.default = "*";
      };

      security.rtkit.enable = true;
    };
}
