{ lib, ... }:

{
  flake.homeModules.evanDesktop =
    { pkgs, ... }:
    let
      awwwPkg = pkgs.awww or null;
      files = ../../../files/evan;
      theme = import ../../../themes/kanso-zen.nix;
      inherit (theme) colors fonts;
      hex = lib.removePrefix "#";
      swayncPkg = pkgs.swaynotificationcenter;
      swayosdPkg = pkgs.swayosd;
      ghosttyTheme = ''
        palette = 0=${colors.background}
        palette = 1=${colors.red}
        palette = 2=${colors.green}
        palette = 3=${colors.yellow}
        palette = 4=${colors.blue}
        palette = 5=${colors.magenta}
        palette = 6=${colors.cyan}
        palette = 7=${colors.foregroundMuted}
        palette = 8=${colors.gray}
        palette = 9=${colors.redBright}
        palette = 10=${colors.greenBright}
        palette = 11=${colors.yellowBright}
        palette = 12=${colors.blueBright}
        palette = 13=${colors.magentaBright}
        palette = 14=${colors.cyanBright}
        palette = 15=${colors.foreground}

        background = ${colors.background}
        foreground = ${colors.foreground}
        cursor-color = ${colors.foreground}
        cursor-text = ${colors.background}
        selection-background = ${colors.backgroundAlt}
        selection-foreground = ${colors.foreground}
      '';
      waybarStyle = ''
        @define-color fg ${colors.foreground};
        @define-color muted ${colors.foregroundMuted};
        @define-color sepcolor ${colors.border};
        @define-color bg ${colors.background};
        @define-color bordercolor ${colors.backgroundDark};
        @define-color disabled ${colors.foregroundDim};
        @define-color warning ${colors.magentaBright};
        @define-color alert ${colors.redBright};
        @define-color activegreen ${colors.cyanBright};
        @define-color highlight ${colors.yellowBright};

        * {
          min-height: 25px;
          font-size: 15px;
          font-family: "${fonts.mono}";
        }

        window#waybar {
          color: @fg;
          background: @bg;
          transition-property: background-color;
          transition-duration: 1s;
          border: 2px solid @bordercolor;
          border-radius: 0px;
        }

        window#waybar.empty {
          opacity: 0.3;
        }

        .hidden {
          opacity: 0;
          margin-left: -6px;
        }

        button {
          box-shadow: inset 0 -3px transparent;
          border: none;
        }

        button:hover {
          background: inherit;
          box-shadow: inset 0 -3px transparent;
        }

        #workspaces button {
          color: @fg;
          padding: 0px 7px;
          background: @bg;
        }

        #workspaces button:hover,
        #workspaces button.empty:hover,
        #workspaces button.active {
          color: @highlight;
        }

        #workspaces button.urgent {
          color: @alert;
        }

        #workspaces button.empty {
          color: @muted;
        }

        #workspaces {
          margin-left: 7px;
        }

        #clock,
        #cpu,
        #memory,
        #disk,
        #temperature,
        #language,
        #backlight,
        #backlight-slider,
        #network,
        #wireplumber,
        #custom-media,
        #taskbar,
        #mode,
        #idle_inhibitor,
        #scratchpad,
        #custom-power,
        #custom-notification,
        #window,
        #keyboard-state,
        #bluetooth,
        #custom-vpn,
        #mpd,
        #tray {
          background: transparent;
          border: none;
          padding: 0px 5px;
          margin: 3px 3px;
          color: @fg;
        }

        #custom-thm-cpu,
        #custom-thm-amd,
        #custom-thm-nvidia,
        #custom-thm-nvme,
        #custom-thm-amb,
        #custom-thm-pwr,
        #custom-thm-batv,
        #custom-thm-bati,
        #custom-thm-fan,
        #mpd {
          background: transparent;
          border: none;
          padding: 0px 4px;
          margin: 2px 2px;
        }

        #custom-clock.local {
          color: @fg;
        }

        #custom-clock.nonlocal {
          color: @highlight;
        }

        #clock:hover,
        #cpu:hover,
        #memory:hover,
        #disk:hover,
        #temperature:hover,
        #language:hover,
        #backlight:hover,
        #backlight-slider:hover,
        #network:hover,
        #wireplumber:hover,
        #custom-media:hover,
        #taskbar:hover,
        #mode:hover,
        #idle_inhibitor:hover,
        #scratchpad:hover,
        #custom-power:hover,
        #custom-notification:hover,
        #window:hover,
        #keyboard-state:hover,
        #bluetooth:hover,
        #custom-vpn:hover,
        #mpd:hover,
        .bar_item:hover {
          color: @highlight;
        }

        #custom-separator {
          color: @sepcolor;
        }

        #custom-power {
          color: @fg;
          padding-left: 10px;
        }

        #tray {
          background-color: @bordercolor;
          border-radius: 0px;
          padding: 0px 10px;
          margin: 5px;
        }

        label:focus {
          background-color: @bg;
        }

        #pulseaudio.warning,
        #wireplumber.warning {
          color: @warning;
        }

        #pulseaudio.critical,
        #wireplumber.critical,
        #network.disconnected,
        #pulseaudio.muted,
        #wireplumber.muted {
          color: @alert;
        }

        tooltip {
          border-radius: 0px;
          background-color: @bg;
          color: @fg;
        }
      '';
      gtklockStyle = ''
        window {
          background-color: ${colors.black};
          color: ${colors.foreground};
          font-family: "${fonts.mono}";
        }

        #window-box {
          background: rgba(9, 14, 19, 0.88);
          border: 1px solid rgba(197, 201, 199, 0.14);
          border-radius: 12px;
          box-shadow: 0 24px 80px rgba(0, 0, 0, 0.55);
          padding: 32px;
        }

        window #clock-label,
        window.focused:not(.hidden) #clock-label {
          color: ${colors.foreground};
          font-size: 64px;
          font-weight: 700;
          margin-bottom: 2px;
        }

        window #date-label,
        window.focused:not(.hidden) #date-label,
        #input-label {
          color: rgba(197, 201, 199, 0.74);
          font-size: 16px;
        }

        #date-label {
          margin-bottom: 22px;
        }

        #input-label {
          font-size: 0;
          min-width: 0;
        }

        #input-field {
          background: rgba(197, 201, 199, 0.09);
          border: 1px solid rgba(197, 201, 199, 0.14);
          border-radius: 8px;
          color: ${colors.foreground};
          min-height: 42px;
          min-width: 280px;
          padding: 0 14px;
        }

        #input-field:focus {
          border-color: rgba(127, 180, 202, 0.55);
          box-shadow: 0 0 0 3px rgba(127, 180, 202, 0.16);
        }

        #warning-label,
        #error-label {
          color: ${colors.redBright};
        }

        #unlock-button {
          background: rgba(127, 180, 202, 0.18);
          border: 1px solid rgba(127, 180, 202, 0.28);
          border-radius: 8px;
          color: ${colors.foreground};
          padding: 8px 14px;
        }

        #unlock-button:hover,
        #unlock-button:focus {
          background: rgba(127, 180, 202, 0.28);
        }
      '';
      swayncStyle = ''
        :root {
          --cc-bg: rgba(9, 14, 19, 0.82);
          --noti-bg: rgba(34, 38, 45, 0.78);
          --noti-bg-hover: rgba(57, 59, 68, 0.80);
          --noti-bg-focus: rgba(57, 59, 68, 0.88);
          --noti-bg-floating: rgba(9, 14, 19, 0.86);
          --noti-border-color: rgba(197, 201, 199, 0.12);
          --noti-border-hover: rgba(127, 180, 202, 0.30);
          --noti-border-focus: rgba(127, 180, 202, 0.42);
          --button-bg: rgba(197, 201, 199, 0.10);
          --button-hover: rgba(127, 180, 202, 0.18);
          --button-active: rgba(127, 180, 202, 0.28);
          --close-bg: rgba(197, 201, 199, 0.10);
          --close-hover: rgba(228, 104, 118, 0.35);
          --text-primary: ${colors.foreground};
          --text-secondary: rgba(197, 201, 199, 0.82);
          --text-disabled: rgba(164, 167, 164, 0.68);
          --border-radius: 10px;
          --transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
        }

        .notification-window,
        .blank-window {
          background: transparent;
        }

        .control-center {
          background: var(--cc-bg);
          border-radius: var(--border-radius);
          border: 1px solid var(--noti-border-color);
          box-shadow: 0 8px 32px rgba(0, 0, 0, 0.5);
          padding: 2px;
        }

        .control-center scrollbar,
        .control-center scrollbar slider {
          background: transparent;
          opacity: 0;
        }

        .widget-mpris {
          margin: 6px 6px 4px 6px;
        }

        .widget-mpris > box > box,
        .notification-row .notification-background .notification,
        .notification-group.collapsed {
          background: var(--noti-bg);
          border-radius: var(--border-radius);
          border: 1px solid var(--noti-border-color);
        }

        .widget-mpris > box > box {
          padding: 10px;
        }

        .mpris-album-art,
        .notification image,
        .notification .body-image {
          border-radius: 6px;
        }

        .mpris-album-art {
          margin-right: 10px;
          min-width: 56px;
          min-height: 56px;
        }

        .mpris-title,
        .widget-title > box > label,
        .notification .summary,
        .notification-group-headers .notification-group-icon,
        .notification-group-headers .notification-group-header {
          color: var(--text-primary);
          font-weight: 600;
        }

        .mpris-title,
        .widget-title > box > label,
        .notification .summary {
          font-size: 14px;
        }

        .mpris-artist,
        .notification .body,
        .notification-group-headers .notification-group-count {
          color: var(--text-secondary);
          font-size: 13px;
        }

        .mpris-controls button,
        .widget-title > box > button {
          background: var(--button-bg);
          border: 1px solid var(--noti-border-color);
          border-radius: 6px;
          color: var(--text-primary);
          transition: var(--transition);
        }

        .mpris-controls button {
          min-width: 32px;
          min-height: 32px;
          margin: 0 3px;
          border: none;
        }

        .mpris-controls button:hover,
        .widget-title > box > button:hover {
          background: var(--button-hover);
          border-color: var(--noti-border-hover);
        }

        .mpris-controls button:active,
        .widget-title > box > button:active {
          background: var(--button-active);
          border-color: var(--noti-border-focus);
        }

        .widget-title {
          margin: 4px 6px;
        }

        .widget-title > box {
          padding: 6px;
        }

        .widget-title > box > button {
          padding: 4px 10px;
          font-size: 12px;
        }

        .widget-dnd {
          margin: 4px 6px;
        }

        .widget-dnd label {
          opacity: 0;
          min-height: 0;
          margin: 0;
          padding: 0;
        }

        .widget-dnd switch {
          background: rgba(34, 38, 45, 0.72);
          border: 1px solid var(--noti-border-color);
          border-radius: 10px;
          min-height: 24px;
          min-width: 44px;
        }

        .widget-dnd switch:checked {
          background: rgba(127, 180, 202, 0.28);
          border-color: var(--noti-border-hover);
        }

        .widget-dnd switch slider {
          background: ${colors.foregroundMuted};
          border-radius: 50%;
          min-width: 18px;
          min-height: 18px;
          margin: 3px;
        }

        .widget-dnd switch:checked slider {
          background: ${colors.blueBright};
        }

        .widget-notifications {
          margin: 2px;
        }

        .notification-row {
          background: none;
          outline: none;
        }

        .notification-row .notification-background {
          padding: 3px;
        }

        .notification-row .notification-background .notification {
          margin: 3px 0;
          transition: var(--transition);
          box-shadow: 0 2px 6px rgba(0, 0, 0, 0.2);
        }

        .notification-row .notification-background .notification:hover,
        .notification-group.collapsed:hover {
          background: var(--noti-bg-hover);
          border-color: var(--noti-border-hover);
          box-shadow: 0 3px 10px rgba(0, 0, 0, 0.35);
        }

        .notification-row .notification-background .notification .notification-default-action {
          padding: 10px;
          color: var(--text-primary);
          border-radius: var(--border-radius);
        }

        .floating-notifications .notification {
          background: var(--noti-bg-floating) !important;
          border-radius: var(--border-radius);
          border: 1px solid var(--noti-border-color);
          box-shadow: 0 8px 24px rgba(0, 0, 0, 0.6);
          padding: 10px;
        }

        .notification .notification-content {
          padding: 3px;
        }

        .notification .body,
        .notification .summary {
          margin-bottom: 3px;
        }

        .notification .time,
        .blank-window label {
          color: var(--text-disabled);
          font-size: 11px;
        }

        .notification image {
          margin-right: 10px;
          min-width: 44px;
          min-height: 44px;
        }

        .notification .body-image {
          margin-top: 6px;
        }

        .close-button {
          background: var(--close-bg);
          color: var(--text-primary);
          border-radius: 100%;
          min-width: 22px;
          min-height: 22px;
          margin: 6px;
          transition: var(--transition);
        }

        .close-button:hover {
          background: var(--close-hover);
        }

        .notification-group {
          margin: 3px;
        }

        .notification-group.collapsed {
          margin: 3px 0;
          transition: var(--transition);
        }

        .notification-group-headers {
          padding: 10px 12px;
          margin: 0;
        }

        .notification-group-headers .notification-group-icon,
        .notification-group-headers .notification-group-header {
          font-size: 13px;
        }

        .notification-group-headers .notification-group-count {
          font-size: 12px;
          font-weight: 500;
        }

        .blank-window label {
          font-size: 13px;
          font-style: italic;
        }
      '';
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
          font=${fonts.mono}:size=13:fontfeatures=-calt:-liga:-dlig, ${fonts.symbols}:size=13
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
          foreground=${hex colors.foreground}
          background=${hex colors.background}
          selection-foreground=${hex colors.foreground}
          selection-background=${hex colors.backgroundAlt}
          urls=${hex colors.url}
          cursor=${hex colors.foreground} ${hex colors.background}

          regular0=${hex colors.background}
          regular1=${hex colors.red}
          regular2=${hex colors.green}
          regular3=${hex colors.yellow}
          regular4=${hex colors.blue}
          regular5=${hex colors.magenta}
          regular6=${hex colors.cyan}
          regular7=${hex colors.foregroundMuted}

          bright0=${hex colors.gray}
          bright1=${hex colors.redBright}
          bright2=${hex colors.greenBright}
          bright3=${hex colors.yellowBright}
          bright4=${hex colors.blueBright}
          bright5=${hex colors.magentaBright}
          bright6=${hex colors.cyanBright}
          bright7=${hex colors.foreground}

          16=${hex colors.orange}
          17=${hex colors.peach}
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
          theme = ${theme.name}
          font-size = 13
          font-family = ${fonts.mono}
          font-family = ${fonts.symbols}
          font-feature = -calt, -liga, -dlig
          macos-titlebar-style = transparent
          background-opacity = 1
          keybind = ctrl+t=new_tab
          window-padding-x = 8
          window-padding-y = 8
          mouse-hide-while-typing = true
          window-decoration = none
        '';
        ".config/ghostty/themes/${theme.name}".text = ghosttyTheme;
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
        ".config/gtklock/style.css".text = gtklockStyle;
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
          osd-font='${fonts.mono}'
          osd-font-size=30
          osd-color='${colors.foreground}'
          osd-border-color='${colors.background}'
          osd-shadow-color='${colors.background}'
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
        ".config/scripts/desktop-appearance".source = files + "/.config/scripts/desktop-appearance";
        ".config/scripts/ns.py".source = files + "/.config/scripts/ns.py";
        ".config/scripts/powermenu".source = files + "/.config/scripts/powermenu";
        ".config/scripts/watch-media".source = files + "/.config/scripts/watch-media";
        ".config/swaync/config.json".source = files + "/.config/swaync/config.json";
        ".config/swaync/style.css".text = swayncStyle;
        ".config/swayosd/config.toml".text = ''
          [server]
          show_percentage = true
          max_volume = 100
          style = "./style.css"
        '';
        ".config/swayosd/style.css".source = files + "/.config/swayosd/style.css";
        ".config/waybar/config.jsonc".source = files + "/.config/waybar/config.jsonc";
        ".config/waybar/style.css".text = waybarStyle;
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
        ".config/zathura/zathurarc".text = ''
          set default-bg                  "${colors.background}"
          set default-fg                  "${colors.foreground}"

          set statusbar-bg                "${colors.backgroundAlt}"
          set statusbar-fg                "${colors.foreground}"

          set inputbar-bg                 "${colors.background}"
          set inputbar-fg                 "${colors.blueBright}"

          set notification-error-bg       "${colors.redBright}"
          set notification-error-fg       "${colors.background}"

          set notification-warning-bg     "${colors.yellowBright}"
          set notification-warning-fg     "${colors.background}"

          set highlight-color             "${colors.backgroundAlt}"
          set highlight-active-color      "${colors.blueBright}"

          set completion-bg               "${colors.backgroundAlt}"
          set completion-fg               "${colors.foreground}"

          set completion-highlight-bg     "${colors.blueBright}"
          set completion-highlight-fg     "${colors.background}"

          set recolor                     "true"
          set recolor-lightcolor          "${colors.background}"
          set recolor-darkcolor           "${colors.foreground}"
        '';
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

        desktop-appearance = {
          Unit = {
            Description = "Apply desktop appearance defaults";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
            Requisite = [ "graphical-session.target" ];
          };
          Service = {
            Type = "oneshot";
            ExecStart = "%h/.config/scripts/desktop-appearance";
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

        desktop-wallpaper = lib.mkIf (awwwPkg != null) {
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
    };
}
