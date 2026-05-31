{
  eos.homeModules.evan = [
    (
      { pkgs, ... }:
      let
        files = ./files;
      in
      {
        home.username = "evan";
        home.homeDirectory = "/home/evan";
        home.stateVersion = "26.05";
        home.enableNixpkgsReleaseCheck = false;

        home.sessionVariables = {
          EDITOR = "e --tty --wait";
          VISUAL = "e --wait";
          XDG_CONFIG_HOME = "$HOME/.config";
          NIXOS_OZONE_WL = "1";
          MOZ_ENABLE_WAYLAND = "1";
        };

        home.sessionPath = [
          "$HOME/bin"
          "$HOME/.local/bin"
          "$HOME/go/bin"
          "$HOME/.cargo/bin"
        ];

        home.packages = with pkgs; [
          bash-completion
          btop
          cliphist
          direnv
          distrobox
          emacs-pgtk
          fastfetch
          foot
          gamemode
          grim
          kitty
          mpc
          mpd-discord-rpc
          mpv
          networkmanagerapplet
          protontricks
          qutebrowser
          rmpc
          slurp
          wl-clipboard
          wl-clip-persist
          yt-dlp
        ];

        programs.home-manager.enable = true;
        programs.git.enable = false;
        programs.direnv.enable = false;
        programs.bash.enable = false;
        programs.zoxide.enable = false;

        home.file = {
          ".bash_logout".text = ''
            clear
          '';

          ".bash_profile".text = ''
            if [[ -f ~/.bashrc ]] ; then
              . ~/.bashrc
            fi
          '';

          ".bashrc".source = files + "/.bashrc";
          ".gitconfig".source = files + "/.gitconfig";

          ".inputrc".text = ''
            "\e[A": history-search-backward
            "\e[B": history-search-forward

            set show-all-if-ambiguous on
            set completion-ignore-case on
          '';

          "bin/e".source = files + "/bin/e";
          "bin/doom-bootstrap".source = files + "/bin/doom-bootstrap";

          ".local/bin/thinkorswim".source = files + "/.local/bin/thinkorswim";

          ".local/share/applications/emacsclient.desktop".text = ''
            [Desktop Entry]
            Name=Emacs Client
            GenericName=Text Editor
            Comment=Edit text
            MimeType=text/english;text/plain;text/x-makefile;text/x-c++hdr;text/x-c++src;text/x-chdr;text/x-csrc;text/x-java;text/x-moc;text/x-pascal;text/x-tcl;text/x-tex;text/x-org;application/x-shellscript;
            Exec=/home/evan/bin/e --wait %F
            Icon=emacs
            Type=Application
            Terminal=false
            Categories=Utility;TextEditor;
            StartupWMClass=Emacs
            Keywords=Text;Editor;
          '';

          ".local/share/applications/thinkorswim.desktop".text = ''
            [Desktop Entry]
            Type=Application
            Name=thinkorswim
            Comment=Trading platform
            Exec=/home/evan/.local/bin/thinkorswim
            Icon=/home/evan/.local/opt/thinkorswim/.install4j/thinkorswim.png
            Terminal=false
            Categories=Finance;Office;
            StartupNotify=true
          '';

          ".local/share/flatpak/overrides/com.discordapp.Discord".text = ''
            [Environment]
            PULSE_LATENCY_MSEC=120
            PIPEWIRE_LATENCY=1024/48000
          '';

          ".local/share/fonts/material-design-iconic-font/Material-Design-Iconic-Font.ttf".source =
            files + "/.local/share/fonts/material-design-iconic-font/Material-Design-Iconic-Font.ttf";

          "Pictures/wallpapers/nebula.png".source = files + "/Pictures/wallpapers/nebula.png";
        };
      }
    )
  ];
}
