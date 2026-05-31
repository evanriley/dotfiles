{ lib, ... }:

let
  files = ../../../files/evan;

  mediaServices = [
    "homepage"
    "jellyfin"
    "lidarr"
    "prowlarr"
    "qbittorrent"
    "radarr"
    "recyclarr"
    "roonserver"
    "sabnzbd"
    "slskd"
    "sonarr"
    "soularr"
  ];

  lineSection =
    name: values:
    lib.optionalString (values != [ ]) (
      lib.concatMapStringsSep "\n" (value: "${name}=${value}") values + "\n"
    );

  quadlet =
    {
      image,
      autoUpdate ? true,
      network ? "media-stack.network",
      ports ? [ ],
      volumes ? [ ],
      environment ? [ ],
      user ? null,
      group ? null,
    }:
    ''
      [Unit]
      Wants=network-online.target
      After=network-online.target

      [Container]
      Image=${image}
      ${lib.optionalString autoUpdate "AutoUpdate=registry\n"}Network=${network}
      ${lineSection "PublishPort" ports}${lineSection "Volume" volumes}${lineSection "Environment" environment}${
        lib.optionalString (user != null) "User=${user}\n"
      }${lib.optionalString (group != null) "Group=${group}\n"}
      [Service]
      Restart=always
      RestartSec=10s

      [Install]
      WantedBy=default.target
    '';
in
{
  eos.nixosModules.cinderace = [
    {
      virtualisation.podman = {
        enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true;
        autoPrune = {
          enable = true;
          dates = "weekly";
        };
      };

      users.users.evan = {
        subUidRanges = [
          {
            startUid = 100000;
            count = 65536;
          }
        ];
        subGidRanges = [
          {
            startGid = 100000;
            count = 65536;
          }
        ];
      };
    }
  ];

  eos.homeModules.evan = [
    (
      { config, pkgs, ... }:
      {
        home.packages = with pkgs; [
          podman-compose
        ];

        home.file = {
          ".config/homepage".source = files + "/.config/homepage";
          ".config/recyclarr".source = files + "/.config/recyclarr";
          ".config/containers/systemd/media-stack.network".text = ''
            [Network]
            NetworkName=media-stack
            DisableDNS=false
          '';
        }
        //
          lib.mapAttrs'
            (name: text: {
              name = ".config/containers/systemd/${name}.container";
              value.text = text;
            })
            {
              homepage = quadlet {
                image = "ghcr.io/gethomepage/homepage:latest";
                ports = [ "127.0.0.1:3000:3000" ];
                volumes = [ "${config.home.homeDirectory}/.config/homepage:/app/config:Z" ];
                environment = [
                  "HOMEPAGE_ALLOWED_HOSTS=127.0.0.1:3000,localhost:3000,cinderace:3000"
                ];
              };

              jellyfin = quadlet {
                image = "lscr.io/linuxserver/jellyfin:latest";
                ports = [
                  "0.0.0.0:8096:8096"
                  "0.0.0.0:7359:7359/udp"
                ];
                volumes = [
                  "${config.home.homeDirectory}/.local/share/media-stack/jellyfin/config:/config:Z"
                  "${config.home.homeDirectory}/.local/share/media-stack/jellyfin/transcode:/transcode:Z"
                  "/mnt/Media/Movies:/data/movies:ro"
                  "/mnt/Media/TV:/data/tvshows:ro"
                ];
                environment = [
                  "PUID=1000"
                  "PGID=1000"
                  "TZ=America/New_York"
                  "UMASK=002"
                ];
              };

              lidarr = quadlet {
                image = "lscr.io/linuxserver/lidarr:latest";
                ports = [ "127.0.0.1:8686:8686" ];
                volumes = [
                  "${config.home.homeDirectory}/.local/share/media-stack/lidarr:/config:Z"
                  "/mnt/Media/Music:/music"
                  "/mnt/Media/Downloads:/downloads"
                ];
                environment = [
                  "PUID=1000"
                  "PGID=1000"
                  "TZ=America/New_York"
                  "UMASK=002"
                ];
              };

              prowlarr = quadlet {
                image = "lscr.io/linuxserver/prowlarr:latest";
                ports = [ "127.0.0.1:9696:9696" ];
                volumes = [ "${config.home.homeDirectory}/.local/share/media-stack/prowlarr:/config:Z" ];
                environment = [
                  "PUID=1000"
                  "PGID=1000"
                  "TZ=America/New_York"
                  "UMASK=002"
                ];
              };

              qbittorrent = quadlet {
                image = "lscr.io/linuxserver/qbittorrent:latest";
                ports = [
                  "127.0.0.1:8081:8081"
                  "0.0.0.0:6881:6881"
                  "0.0.0.0:6881:6881/udp"
                ];
                volumes = [
                  "${config.home.homeDirectory}/.local/share/media-stack/qbittorrent:/config:Z"
                  "/mnt/Media/Downloads:/downloads"
                ];
                environment = [
                  "PUID=1000"
                  "PGID=1000"
                  "TZ=America/New_York"
                  "UMASK=002"
                  "WEBUI_PORT=8081"
                ];
              };

              radarr = quadlet {
                image = "lscr.io/linuxserver/radarr:latest";
                ports = [ "127.0.0.1:7878:7878" ];
                volumes = [
                  "${config.home.homeDirectory}/.local/share/media-stack/radarr:/config:Z"
                  "/mnt/Media/Movies:/movies"
                  "/mnt/Media/Downloads:/downloads"
                ];
                environment = [
                  "PUID=1000"
                  "PGID=1000"
                  "TZ=America/New_York"
                  "UMASK=002"
                ];
              };

              recyclarr = quadlet {
                image = "ghcr.io/recyclarr/recyclarr:8";
                volumes = [
                  "${config.home.homeDirectory}/.config/recyclarr:/config:Z"
                  "${config.home.homeDirectory}/.local/share/media-stack/recyclarr:/data:Z"
                ];
                environment = [
                  "TZ=America/New_York"
                  "CRON_SCHEDULE=@daily"
                  "RECYCLARR_CONFIG_DIR=/config"
                  "RECYCLARR_DATA_DIR=/data"
                  "RECYCLARR_CREATE_CONFIG=false"
                ];
              };

              roonserver = quadlet {
                image = "ghcr.io/roonlabs/roonserver:latest";
                network = "host";
                volumes = [
                  "${config.home.homeDirectory}/.local/share/media-stack/roon:/Roon:Z"
                  "${config.home.homeDirectory}/.local/share/media-stack/roon-backups:/RoonBackups:Z"
                  "/mnt/Media/Music:/Music"
                ];
                environment = [
                  "TZ=America/New_York"
                  "HOSTNAME=cinderace"
                ];
              };

              sabnzbd = quadlet {
                image = "lscr.io/linuxserver/sabnzbd:latest";
                ports = [ "127.0.0.1:8080:8080" ];
                volumes = [
                  "${config.home.homeDirectory}/.local/share/media-stack/sabnzbd:/config:Z"
                  "/mnt/Media/Downloads:/downloads"
                ];
                environment = [
                  "PUID=1000"
                  "PGID=1000"
                  "TZ=America/New_York"
                  "UMASK=002"
                ];
              };

              slskd = quadlet {
                image = "docker.io/slskd/slskd:latest";
                ports = [
                  "127.0.0.1:5030:5030"
                  "127.0.0.1:5031:5031"
                  "0.0.0.0:50300:50300"
                ];
                volumes = [
                  "${config.home.homeDirectory}/.local/share/media-stack/slskd:/app:Z"
                  "/mnt/Media/Music:/music"
                  "/mnt/Media/Downloads:/downloads"
                ];
                environment = [
                  "SLSKD_HTTP_PORT=5030"
                  "SLSKD_HTTPS_PORT=5031"
                  "SLSKD_SLSK_LISTEN_PORT=50300"
                  "SLSKD_REMOTE_CONFIGURATION=true"
                ];
              };

              sonarr = quadlet {
                image = "lscr.io/linuxserver/sonarr:latest";
                ports = [ "127.0.0.1:8989:8989" ];
                volumes = [
                  "${config.home.homeDirectory}/.local/share/media-stack/sonarr:/config:Z"
                  "/mnt/Media/TV:/tv"
                  "/mnt/Media/Downloads:/downloads"
                ];
                environment = [
                  "PUID=1000"
                  "PGID=1000"
                  "TZ=America/New_York"
                  "UMASK=002"
                ];
              };

              soularr = quadlet {
                image = "docker.io/mrusse08/soularr:latest";
                ports = [ "127.0.0.1:8265:8265" ];
                volumes = [
                  "${config.home.homeDirectory}/.local/share/media-stack/soularr:/data:Z"
                  "/mnt/Media/Downloads:/downloads"
                ];
                environment = [
                  "PUID=1000"
                  "PGID=1000"
                  "TZ=America/New_York"
                  "SCRIPT_INTERVAL=300"
                ];
              };
            };

        home.activation.createMediaStackDirs = config.lib.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p \
            "$HOME/.config/containers/systemd" \
            "$HOME/.local/share/media-stack"/{homepage,jellyfin/config,jellyfin/transcode,lidarr,prowlarr,qbittorrent,radarr,recyclarr,roon,roon-backups,sabnzbd,slskd,sonarr,soularr}
        '';

        home.activation.enableMediaQuadlets = config.lib.dag.entryAfter [ "writeBoundary" ] ''
          if command -v systemctl >/dev/null 2>&1 && systemctl --user is-system-running >/dev/null 2>&1; then
            systemctl --user daemon-reload || true
            systemctl --user enable --now ${
              lib.concatMapStringsSep " " (name: "${name}.service") mediaServices
            } || true
          fi
        '';
      }
    )
  ];
}
