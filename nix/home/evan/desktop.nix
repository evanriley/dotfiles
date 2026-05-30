{ lib, ... }:

{
  eos.homeModules.evan = [
    (
      { pkgs, ... }:
      let
        awwwPkg = if pkgs ? awww then pkgs.awww else null;
        swayncPkg = pkgs.swaynotificationcenter;
        swayosdPkg = pkgs.swayosd;
      in
      {
        home.file = {
          ".config/btop/btop.conf".source = ../../../.config/btop/btop.conf;
          ".config/direnv/direnvrc".source = ../../../.config/direnv/direnvrc;
          ".config/fastfetch".source = ../../../.config/fastfetch;
          ".config/foot/foot.ini".source = ../../../.config/foot/foot.ini;
          ".config/ghostty/config".source = ../../../.config/ghostty/config;
          ".config/gtk-3.0/settings.ini".source = ../../../.config/gtk-3.0/settings.ini;
          ".config/gtk-4.0/settings.ini".source = ../../../.config/gtk-4.0/settings.ini;
          ".config/gtklock".source = ../../../.config/gtklock;
          ".config/kitty".source = ../../../.config/kitty;
          ".config/mimeapps.list".source = ../../../.config/mimeapps.list;
          ".config/mise/config.toml".source = ../../../.config/mise/config.toml;
          ".config/mpd/mpd.conf".source = ../../../.config/mpd/mpd.conf;
          ".config/mpv".source = ../../../.config/mpv;
          ".config/niri/config.kdl".source = ../../../.config/niri/config.kdl;
          ".config/nvim".source = ../../../.config/nvim;
          ".config/pipewire".source = ../../../.config/pipewire;
          ".config/qutebrowser/config.py".source = ../../../.config/qutebrowser/config.py;
          ".config/rmpc".source = ../../../.config/rmpc;
          ".config/rofi".source = ../../../.config/rofi;
          ".config/scripts/cliphist-rofi".source = ../../../.config/scripts/cliphist-rofi;
          ".config/scripts/e-os-appearance".source = ../../../.config/scripts/e-os-appearance;
          ".config/scripts/ns.py".source = ../../../.config/scripts/ns.py;
          ".config/scripts/powermenu".source = ../../../.config/scripts/powermenu;
          ".config/scripts/watch-media".source = ../../../.config/scripts/watch-media;
          ".config/swaync".source = ../../../.config/swaync;
          ".config/swayosd".source = ../../../.config/swayosd;
          ".config/waybar".source = ../../../.config/waybar;
          ".config/wireplumber".source = ../../../.config/wireplumber;
          ".config/wlogout".source = ../../../.config/wlogout;
          ".config/xdg-desktop-portal/niri-portals.conf".source = ../../../.config/xdg-desktop-portal/niri-portals.conf;
          ".config/yazi".source = ../../../.config/yazi;
          ".config/yt-dlp/config".source = ../../../.config/yt-dlp/config;
          ".config/zathura/zathurarc".source = ../../../.config/zathura/zathurarc;
        };

        systemd.user.services = {
          cliphist-store = {
            Unit = {
              Description = "Clipboard history store for Niri";
              PartOf = [ "graphical-session.target" ];
              After = [ "graphical-session.target" ];
              Requisite = [ "graphical-session.target" ];
            };
            Service = {
              ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store";
              Restart = "on-failure";
            };
            Install.WantedBy = [ "niri.service" ];
          };

          swayidle = {
            Unit = {
              Description = "Idle manager for Niri";
              PartOf = [ "graphical-session.target" ];
              After = [ "graphical-session.target" ];
              Requisite = [ "graphical-session.target" ];
            };
            Service = {
              ExecStart = "${pkgs.swayidle}/bin/swayidle -w timeout 300 '${pkgs.bash}/bin/sh -c \"pidof gtklock >/dev/null || ${pkgs.gtklock}/bin/gtklock &\"' before-sleep '${pkgs.gtklock}/bin/gtklock' after-resume '${pkgs.bash}/bin/sh -lc \"sleep 1; ${pkgs.niri}/bin/niri msg action power-on-monitors || true; sleep 1; ${pkgs.niri}/bin/niri msg action power-on-monitors || true\"'";
              Restart = "on-failure";
            };
            Install.WantedBy = [ "niri.service" ];
          };

          swaync = {
            Unit = {
              Description = "Notification daemon for Niri";
              PartOf = [ "graphical-session.target" ];
              After = [ "graphical-session.target" ];
              Requisite = [ "graphical-session.target" ];
            };
            Service = {
              ExecStartPre = "-${pkgs.procps}/bin/pkill -xu %u mako";
              ExecStart = "${swayncPkg}/bin/swaync";
              Restart = "on-failure";
            };
            Install.WantedBy = [ "niri.service" ];
          };

          swayosd = {
            Unit = {
              Description = "On-screen display server for Niri";
              PartOf = [ "graphical-session.target" ];
              After = [ "graphical-session.target" ];
              Requisite = [ "graphical-session.target" ];
            };
            Service = {
              ExecStart = "${swayosdPkg}/bin/swayosd-server";
              Restart = "on-failure";
            };
            Install.WantedBy = [ "niri.service" ];
          };

          waybar = {
            Unit = {
              Description = "Waybar for Niri";
              PartOf = [ "graphical-session.target" ];
              After = [ "graphical-session.target" ];
              Requisite = [ "graphical-session.target" ];
            };
            Service = {
              ExecStart = "${pkgs.waybar}/bin/waybar";
              Restart = "on-failure";
            };
            Install.WantedBy = [ "niri.service" ];
          };

          xfce-polkit-agent = {
            Unit = {
              Description = "Xfce PolicyKit authentication agent for Niri";
              PartOf = [ "graphical-session.target" ];
              After = [ "graphical-session.target" ];
              Requisite = [ "graphical-session.target" ];
            };
            Service = {
              ExecStart = "${pkgs.xfce4-session}/libexec/xfce-polkit";
              Restart = "on-failure";
            };
            Install.WantedBy = [ "niri.service" ];
          };

          e-os-wallpaper = lib.mkIf (awwwPkg != null) {
            Unit = {
              Description = "Set Niri wallpaper";
              PartOf = [ "graphical-session.target" ];
              After = [
                "graphical-session.target"
                "awww-daemon.service"
              ];
              Requisite = [ "graphical-session.target" ];
            };
            Service = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = "${pkgs.bash}/bin/sh -lc '${awwwPkg}/bin/awww img \"$HOME/Pictures/wallpapers/nebula.png\" || { sleep 1; ${awwwPkg}/bin/awww img \"$HOME/Pictures/wallpapers/nebula.png\"; }'";
            };
            Install.WantedBy = [ "niri.service" ];
          };

          awww-daemon = lib.mkIf (awwwPkg != null) {
            Unit = {
              Description = "Wallpaper daemon for Niri";
              PartOf = [ "graphical-session.target" ];
              After = [ "graphical-session.target" ];
              Requisite = [ "graphical-session.target" ];
            };
            Service = {
              ExecStart = "${awwwPkg}/bin/awww-daemon";
              Restart = "on-failure";
            };
            Install.WantedBy = [ "niri.service" ];
          };
        };
      }
    )
  ];
}
