{
  flake.homeModules.evanBase =
    { lib, pkgs, ... }:
    let
      files = ../../../files/evan;
    in
    {
      home = {
        username = "evan";
        homeDirectory = "/home/evan";
        stateVersion = "26.05";
        enableNixpkgsReleaseCheck = false;

        sessionVariables = {
          EDITOR = "e --tty --wait";
          VISUAL = "e --wait";
          XDG_CONFIG_HOME = "$HOME/.config";
          NIXOS_OZONE_WL = "1";
          MOZ_ENABLE_WAYLAND = "1";
        };

        sessionPath = [
          "$HOME/bin"
          "$HOME/.local/bin"
          "$HOME/go/bin"
          "$HOME/.cargo/bin"
        ];

        packages = with pkgs; [
          bash-completion
          bitwarden-desktop
          btop
          brave
          chatterino2
          cliphist
          direnv
          discord
          distrobox
          emacs-pgtk
          fastfetch
          foot
          gamemode
          grim
          heroic
          kitty
          libreoffice-fresh
          mpc
          mission-center
          mpd-discord-rpc
          mpv
          networkmanagerapplet
          nicotine-plus
          obs-studio
          picard
          pika-backup
          protontricks
          protonplus
          qutebrowser
          qpwgraph
          rmpc
          signal-desktop
          slurp
          thunderbird
          trayscale
          wl-clipboard
          wl-clip-persist
          yt-dlp
        ];

        file = {
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

          ".local/share/fonts/material-design-iconic-font/Material-Design-Iconic-Font.ttf".source =
            files + "/.local/share/fonts/material-design-iconic-font/Material-Design-Iconic-Font.ttf";

          "Pictures/wallpapers/nebula.png".source = files + "/Pictures/wallpapers/nebula.png";
        };
      };

      programs = {
        home-manager.enable = true;
        git.enable = false;
        direnv.enable = false;
        bash.enable = false;
        zoxide.enable = false;
      };

      home.activation.migratePikaBackupConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        source_dir="$HOME/.var/app/org.gnome.World.PikaBackup/config/pika-backup"
        target_dir="$HOME/.config/pika-backup"

        if [ -d "$source_dir" ] && [ ! -e "$target_dir/backup.json" ]; then
          mkdir -p "$target_dir"
          cp -a "$source_dir"/. "$target_dir"/
        fi
      '';
    };
}
