{ lib, ... }:

{
  eos.homeModules.evan = [
    (
      { pkgs, ... }:
      let
        awwwPkg = if pkgs ? awww then pkgs.awww else null;
        files = ../../../files/evan;
        swayncPkg = pkgs.swaynotificationcenter;
        swayosdPkg = pkgs.swayosd;
      in
      {
        home.file = {
          ".config/btop".source = files + "/.config/btop";
          ".config/direnv/direnvrc".text = ''
            layout_uv() {
                if [ ! -d .venv ]; then
                    uv venv
                fi

                source .venv/bin/activate
            }

            dotenv_if_exists() {
                local file="''${1:-.env.local}"

                if [ -f "$file" ]; then
                    dotenv "$file"
                fi
            }
          '';
          ".config/doom".source = files + "/.config/doom";
          ".config/fastfetch".source = files + "/.config/fastfetch";
          ".config/foot/foot.ini".text = ''
            [main]
            shell=bash
            font=Berkeley Mono:size=13:fontfeatures=-calt:-liga:-dlig, Symbols Nerd Font Mono:size=13
            pad=8x8
            [cursor]
            style=block
            blink=no
            [mouse]
            hide-when-typing=yes
            [scrollback]
            lines=10000
            multiplier=3.0
            indicator-position=relative
            indicator-format=""

            [colors-dark]
            foreground=ffffff
            background=000000
            selection-foreground=ffffff
            selection-background=7030af
            urls=c6daff
            cursor=ffffff 7030af

            regular0=000000
            regular1=ff5f59
            regular2=44bc44
            regular3=d0bc00
            regular4=2fafff
            regular5=feacd0
            regular6=00d3d0
            regular7=ffffff

            bright0=1e1e1e
            bright1=ff5f5f
            bright2=44df44
            bright3=efef00
            bright4=338fff
            bright5=ff66ff
            bright6=00eff0
            bright7=989898

            16=fec43f
            17=ff9580
          '';
          ".config/ghostty/config".text = ''
            command = bash
            working-directory = ~
            custom-shader-animation = true
            clipboard-read = allow
            clipboard-write = allow
            copy-on-select = false
            window-new-tab-position = end
            window-padding-balance = true
            theme = no-clown-fiesta
            font-size = 13
            font-family = Berkeley Mono
            font-family = Symbols Nerd Font Mono
            font-feature = -calt, -liga, -dlig
            macos-titlebar-style = transparent
            background-opacity = 1
            keybind = ctrl+t=new_tab
            window-padding-x = 8
            window-padding-y = 8
            mouse-hide-while-typing = true
            window-decoration = none
          '';
          ".config/ghostty/themes".source = files + "/.config/ghostty/themes";
          ".config/gtk-3.0/settings.ini".text = ''
            [Settings]
            gtk-theme-name=adw-gtk3-dark
            gtk-icon-theme-name=Papirus-Dark
            gtk-cursor-theme-name=Bibata-Original-Classic
            gtk-cursor-theme-size=24
            gtk-application-prefer-dark-theme=1
          '';
          ".config/gtk-4.0/settings.ini".text = ''
            [Settings]
            gtk-theme-name=adw-gtk3-dark
            gtk-icon-theme-name=Papirus-Dark
            gtk-cursor-theme-name=Bibata-Original-Classic
            gtk-cursor-theme-size=24
            gtk-application-prefer-dark-theme=1
          '';
          ".config/gtklock/config.ini".text = ''
            [main]
            gtk-theme=adw-gtk3-dark
            time-format=%H:%M
            date-format=%A, %B %d
            idle-hide=true
            idle-timeout=20
          '';
          ".config/gtklock/style.css".source = files + "/.config/gtklock/style.css";
          ".config/kitty".source = files + "/.config/kitty";
          ".config/mimeapps.list".source = files + "/.config/mimeapps.list";
          ".config/mise/config.toml".text = ''
            [tools]
            go = "latest"
            janet = "latest"
            node = "latest"
            python = "latest"
            zig = "latest"
            zls = "latest"
          '';
          ".config/mpd/mpd.conf".source = files + "/.config/mpd/mpd.conf";
          ".config/mpv/input.conf".text = ''
            WHEEL_UP      add volume 5
            WHEEL_DOWN    add volume -5

            l             seek  5
            h             seek -5
            L             seek  30
            H             seek -30

            q             quit
            ESC           set fullscreen no
          '';
          ".config/mpv/mpv.conf".text = ''
            vo=gpu-next
            gpu-api=vulkan
            hwdec=vaapi
            profile=high-quality
            scale=ewa_lanczossharp
            cscale=ewa_lanczossharp
            volume=50

            keep-open=yes
            save-position-on-quit=yes
            force-window=immediate
            window-scale=0.8
            keepaspect-window=no

            border=no
            osd-bar=no
            osd-font='Berkeley Mono'
            osd-font-size=30
            osd-color='#C5C9C7'
            osd-border-color='#090E13'
            osd-shadow-color='#090E13'
            osd-border-size=2
            osd-shadow-offset=1

            screenshot-format=png
            screenshot-directory=~/Pictures/Screenshots

            ytdl-format="((bestvideo[vcodec^=vp9]/bestvideo)+(bestaudio[acodec=opus]/bestaudio[acodec=vorbis]/bestaudio[acodec=aac]/bestaudio))/best"
          '';
          ".config/mpv/scripts".source = files + "/.config/mpv/scripts";
          ".config/niri/config.kdl".source = files + "/.config/niri/config.kdl";
          ".config/nvim".source = files + "/.config/nvim";
          ".config/pipewire/pipewire.conf.d/clock.rate.conf".text = ''
            context.properties = {
                default.clock.rate = 48000
                default.clock.allowed-rates = [ 44100 48000 88200 96000 176400 192000 ]
            }
          '';
          ".config/qutebrowser".source = files + "/.config/qutebrowser";
          ".config/rmpc".source = files + "/.config/rmpc";
          ".config/rofi".source = files + "/.config/rofi";
          ".config/scripts/cliphist-rofi".source = files + "/.config/scripts/cliphist-rofi";
          ".config/scripts/e-os-appearance".source = files + "/.config/scripts/e-os-appearance";
          ".config/scripts/ns.py".source = files + "/.config/scripts/ns.py";
          ".config/scripts/powermenu".source = files + "/.config/scripts/powermenu";
          ".config/scripts/watch-media".source = files + "/.config/scripts/watch-media";
          ".config/swaync".source = files + "/.config/swaync";
          ".config/swayosd/config.toml".text = ''
            [server]
            show_percentage = true
            max_volume = 100
            style = "./style.css"
          '';
          ".config/swayosd/style.css".source = files + "/.config/swayosd/style.css";
          ".config/waybar".source = files + "/.config/waybar";
          ".config/wezterm".source = files + "/.config/wezterm";
          ".config/wireplumber/wireplumber.conf.d/51-dx5ii.conf".text = ''
            monitor.alsa.rules = [
              {
                matches = [
                  {
                    device.name = "~alsa_card.usb-Topping_DX5_II.*"
                  }
                ]
                actions = {
                  update-props = {
                    device.nick = "Topping DX5 II"
                    device.description = "Topping DX5 II"
                    api.acp.auto-ports-wait = true
                  }
                }
              }
              {
                matches = [
                  {
                    node.name = "~alsa_output.usb-Topping_DX5_II.*"
                  }
                ]
                actions = {
                  update-props = {
                    node.nick = "Topping DX5 II"
                    node.description = "Topping DX5 II"
                    audio.rate = 0
                    audio.allowed-rates = [ 44100 48000 88200 96000 176400 192000 ]
                    api.alsa.multi-rate = true
                  }
                }
              }
            ]
          '';
          ".config/wlogout".source = files + "/.config/wlogout";
          ".config/xdg-desktop-portal/niri-portals.conf".text = ''
            [preferred]
            default=gnome;gtk;
            org.freedesktop.impl.portal.Access=gtk;
            org.freedesktop.impl.portal.Notification=gtk;
            org.freedesktop.impl.portal.Secret=gnome-keyring;
          '';
          ".config/yazi".source = files + "/.config/yazi";
          ".config/yt-dlp/config".text = ''
            --sponsorblock-remove all
          '';
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
