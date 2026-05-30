{
  eos.homeModules.evan = [
    (
      { pkgs, ... }:
      let
        files = ../../../home/evan/files;
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
          ".bash_logout".source = files + "/.bash_logout";
          ".bash_profile".source = files + "/.bash_profile";
          ".bashrc".source = files + "/.bashrc";
          ".gitconfig".source = files + "/.gitconfig";
          ".inputrc".source = files + "/.inputrc";

          "bin/e".source = files + "/bin/e";
          "bin/doom-bootstrap".source = files + "/bin/doom-bootstrap";

          ".local/bin/thinkorswim".source = files + "/.local/bin/thinkorswim";
          ".local/share/applications/emacsclient.desktop".source =
            files + "/.local/share/applications/emacsclient.desktop";
          ".local/share/applications/thinkorswim.desktop".source =
            files + "/.local/share/applications/thinkorswim.desktop";
          ".local/share/flatpak/overrides/com.discordapp.Discord".source =
            files + "/.local/share/flatpak/overrides/com.discordapp.Discord";
          ".local/share/flatpak/overrides/io.mpv.Mpv".source =
            files + "/.local/share/flatpak/overrides/io.mpv.Mpv";
          ".local/share/fonts/material-design-iconic-font/Material-Design-Iconic-Font.ttf".source =
            files + "/.local/share/fonts/material-design-iconic-font/Material-Design-Iconic-Font.ttf";

          "Pictures/wallpapers/nebula.png".source = files + "/Pictures/wallpapers/nebula.png";
        };
      }
    )
  ];
}
