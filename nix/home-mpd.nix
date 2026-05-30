{
  eos.homeModules.evan = [
    (
      { pkgs, ... }:
      {
        systemd.user.services = {
          mpd = {
            Unit = {
              Description = "Music Player Daemon";
              PartOf = [ "graphical-session.target" ];
              After = [
                "graphical-session.target"
                "pipewire.service"
                "wireplumber.service"
              ];
              Requisite = [ "graphical-session.target" ];
              ConditionPathIsDirectory = [
                "%h/.config/mpd"
                "/mnt/Media/Music"
              ];
            };
            Service = {
              ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/.config/mpd/playlists";
              ExecStart = "${pkgs.mpd}/bin/mpd --no-daemon %h/.config/mpd/mpd.conf";
              Restart = "on-failure";
            };
            Install.WantedBy = [ "niri.service" ];
          };

          mpd-mpris = {
            Unit = {
              Description = "MPD MPRIS bridge";
              PartOf = [ "graphical-session.target" ];
              After = [
                "graphical-session.target"
                "mpd.service"
              ];
              Requires = [ "mpd.service" ];
              Requisite = [ "graphical-session.target" ];
              ConditionPathIsDirectory = [ "/mnt/Media/Music" ];
            };
            Service = {
              ExecStart = "${pkgs.mpd-mpris}/bin/mpd-mpris";
              Restart = "on-failure";
            };
            Install.WantedBy = [ "niri.service" ];
          };

          mpd-discord-rpc = {
            Unit = {
              Description = "MPD Discord rich presence";
              PartOf = [ "graphical-session.target" ];
              After = [
                "graphical-session.target"
                "mpd.service"
              ];
              Requires = [ "mpd.service" ];
              Requisite = [ "graphical-session.target" ];
              ConditionPathExists = [ "%h/.config/discord-rpc/config.toml" ];
            };
            Service = {
              ExecStart = "${pkgs.mpd-discord-rpc}/bin/mpd-discord-rpc";
              Restart = "on-failure";
              RestartSec = "5s";
            };
            Install.WantedBy = [ "niri.service" ];
          };
        };
      }
    )
  ];
}
