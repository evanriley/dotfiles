{
  eos.homeModules.evan = [
    (
      { pkgs, ... }:
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
          ".bash_logout".source = ../../../.bash_logout;
          ".bash_profile".source = ../../../.bash_profile;
          ".bashrc".source = ../../../.bashrc;
          ".gitconfig".source = ../../../.gitconfig;
          ".inputrc".source = ../../../.inputrc;

          "bin/e".source = ../../../bin/e;
          "bin/dotinstall.sh".source = ../../../bin/dotinstall.sh;
          "bin/doom-bootstrap".source = ../../../bin/doom-bootstrap;

          "Pictures/wallpapers/nebula.png".source = ../../../Pictures/wallpapers/nebula.png;
        };
      }
    )
  ];
}
