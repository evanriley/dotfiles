# Media Stack

Rootless Podman Quadlet services for media automation on cinderace.

## Services

- Lidarr: <http://127.0.0.1:8686>
- Radarr: <http://127.0.0.1:7878>
- Sonarr: <http://127.0.0.1:8989>
- Prowlarr: <http://127.0.0.1:9696>
- SABnzbd: <http://127.0.0.1:8080>
- slskd: <http://127.0.0.1:5030>

## Paths

- App config: `~/.local/share/media-stack`
- Downloads: `/mnt/Media/Downloads`
- Music: `/mnt/Media/Music`
- Movies: `/mnt/Media/Movies`
- TV: `/mnt/Media/TV`

Inside the containers, use these paths:

- Downloads: `/downloads`
- Music: `/music`
- Movies: `/movies`
- TV: `/tv`

In SABnzbd, use `/downloads/incomplete` for temporary downloads and
`/downloads/complete` for completed downloads.

