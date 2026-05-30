{ lib, ... }:

{
  eos.homeModules.evan = [
    (
      { pkgs, ... }:
      let
        awwwPkg = if pkgs ? awww then pkgs.awww else null;
        files = ../../../home/evan/files;
        swayncPkg = pkgs.swaynotificationcenter;
        swayosdPkg = pkgs.swayosd;
      in
      {
        home.file = {
          ".config/btop/btop.conf".source = files + "/.config/btop/btop.conf";
          ".config/direnv/direnvrc".source = files + "/.config/direnv/direnvrc";
          ".config/doom".source = files + "/.config/doom";
          ".config/fastfetch".source = files + "/.config/fastfetch";
          ".config/foot/foot.ini".source = files + "/.config/foot/foot.ini";
          ".config/ghostty/config".source = files + "/.config/ghostty/config";
          ".config/gtk-3.0/settings.ini".source = files + "/.config/gtk-3.0/settings.ini";
          ".config/gtk-4.0/settings.ini".source = files + "/.config/gtk-4.0/settings.ini";
          ".config/gtklock".source = files + "/.config/gtklock";
          ".config/kitty".source = files + "/.config/kitty";
          ".config/mimeapps.list".source = files + "/.config/mimeapps.list";
          ".config/mise/config.toml".source = files + "/.config/mise/config.toml";
          ".config/mpd/mpd.conf".source = files + "/.config/mpd/mpd.conf";
          ".config/mpv".source = files + "/.config/mpv";
          ".config/niri/config.kdl".source = files + "/.config/niri/config.kdl";
          ".config/nvim".source = files + "/.config/nvim";
          ".config/pipewire".source = files + "/.config/pipewire";
          ".config/qutebrowser".source = files + "/.config/qutebrowser";
          ".config/rmpc".source = files + "/.config/rmpc";
          ".config/rofi".source = files + "/.config/rofi";
          ".config/scripts/cliphist-rofi".source = files + "/.config/scripts/cliphist-rofi";
          ".config/scripts/e-os-appearance".source = files + "/.config/scripts/e-os-appearance";
          ".config/scripts/ns.py".source = files + "/.config/scripts/ns.py";
          ".config/scripts/powermenu".source = files + "/.config/scripts/powermenu";
          ".config/scripts/watch-media".source = files + "/.config/scripts/watch-media";
          ".config/swaync".source = files + "/.config/swaync";
          ".config/swayosd".source = files + "/.config/swayosd";
          ".config/waybar".source = files + "/.config/waybar";
          ".config/wezterm".source = files + "/.config/wezterm";
          ".config/wireplumber".source = files + "/.config/wireplumber";
          ".config/wlogout".source = files + "/.config/wlogout";
          ".config/xdg-desktop-portal/niri-portals.conf".source =
            files + "/.config/xdg-desktop-portal/niri-portals.conf";
          ".config/yazi".source = files + "/.config/yazi";
          ".config/yt-dlp/config".source = files + "/.config/yt-dlp/config";
          ".config/zathura/zathurarc".source = files + "/.config/zathura/zathurarc";
        };

        systemd.user.services = {
          emacs = {
            Unit = {
              Description = "Emacs text editor daemon";
              Documentation = "info:emacs man:emacs(1) https://gnu.org/software/emacs/";
              ConditionPathExists = [ "%h/.config/doom/init.el" ];
            };
            Service = {
              Type = "notify";
              Environment = [
                "COLORTERM=truecolor"
                "DOOMDIR=%h/.config/doom"
              ];
              ExecStart = "${pkgs.emacs-pgtk}/bin/emacs --fg-daemon";
              ExecStop = ''${pkgs.emacs-pgtk}/bin/emacsclient --eval "(kill-emacs)"'';
              Restart = "on-failure";
            };
            Install.WantedBy = [ "default.target" ];
          };

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

          e-os-appearance = {
            Unit = {
              Description = "Apply e-os desktop appearance defaults";
              PartOf = [ "graphical-session.target" ];
              After = [ "graphical-session.target" ];
              Requisite = [ "graphical-session.target" ];
            };
            Service = {
              Type = "oneshot";
              ExecStart = "%h/.config/scripts/e-os-appearance";
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
