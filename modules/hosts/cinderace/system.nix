{ lib, ... }:

{
  eos.nixosModules.cinderace = [
    (
      { pkgs, ... }:
      {
        system.stateVersion = "26.05";

        networking.hostName = "cinderace";
        time.timeZone = "America/New_York";
        i18n.defaultLocale = "en_US.UTF-8";

        nix.settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          auto-optimise-store = true;
        };

        nix.gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 14d";
        };

        nixpkgs.config.allowUnfree = true;

        users.users.evan = {
          isNormalUser = true;
          description = "Evan Riley";
          extraGroups = [
            "wheel"
            "networkmanager"
            "video"
            "audio"
            "input"
            "podman"
          ];
          shell = pkgs.bashInteractive;
        };

        security.sudo.wheelNeedsPassword = true;

        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;
        boot.supportedFilesystems = [ "btrfs" ];
        boot.kernelPackages = pkgs.linuxPackages_latest;
        boot.kernelParams = [
          "quiet"
          "splash"
          "bluetooth.disable_ertm=1"
        ];

        boot.initrd.systemd.enable = true;
        boot.initrd.luks.devices.crypted = {
          device = "/dev/disk/by-partlabel/nixos-cryptroot";
          allowDiscards = true;
          crypttabExtraOpts = [
            "fido2-device=auto"
            "token-timeout=30"
          ];
        };

        fileSystems."/mnt/Media" = {
          device = "/dev/disk/by-uuid/63b66b78-4f03-44ab-9a01-ddb98de974cf";
          fsType = "ext4";
          options = [
            "nosuid"
            "nodev"
            "nofail"
            "x-gvfs-show"
          ];
        };

        fileSystems."/mnt/Games" = {
          device = "/dev/disk/by-uuid/ccc88ac2-f5bd-48da-b033-03bafbd2c110";
          fsType = "ext4";
          options = [
            "nosuid"
            "nodev"
            "nofail"
            "x-gvfs-show"
          ];
        };

        zramSwap.enable = true;
        services.fstrim.enable = true;
        services.smartd.enable = true;
        services.fwupd.enable = true;
        networking.networkmanager.enable = true;
        networking.firewall = {
          enable = true;
          allowedTCPPorts = [
            6881
            50300
            8096
          ];
          allowedUDPPorts = [
            6881
            7359
          ];
        };

        services.tailscale.enable = true;
        services.avahi = {
          enable = true;
          nssmdns4 = true;
          openFirewall = true;
        };

        hardware.bluetooth = {
          enable = true;
          powerOnBoot = false;
        };
        services.blueman.enable = true;

        services.pcscd.enable = true;

        services.printing.enable = true;

        environment.sessionVariables = {
          NIXOS_OZONE_WL = "1";
          MOZ_ENABLE_WAYLAND = "1";
          QT_QPA_PLATFORM = "wayland;xcb";
          QT_QPA_PLATFORMTHEME = "gtk3";
        };

        environment.systemPackages = with pkgs; [
          age
          age-plugin-yubikey
          bat
          bibata-cursors
          borgbackup
          btop
          cmake
          cryptsetup
          delta
          direnv
          distrobox
          eza
          fd
          file-roller
          firefox
          fzf
          gh
          git
          gtklock
          jq
          lazygit
          libfido2
          libnotify
          micro
          mise
          mosh
          mpd
          mpd-mpris
          neovim
          networkmanagerapplet
          pavucontrol
          playerctl
          ripgrep
          rofi
          shellcheck
          sqlite
          starship
          swayidle
          swaynotificationcenter
          swayosd
          trash-cli
          unzip
          waybar
          wl-clipboard
          wlogout
          xwayland-satellite
          yazi
          yubikey-manager
          yubikey-personalization
          zathura
          zip
          zoxide
        ];

        fonts.packages = with pkgs; [
          nerd-fonts.symbols-only
        ];
      }
    )
  ];
}
