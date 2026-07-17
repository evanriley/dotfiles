# NewsBlur

NewsBlur runs as a Podman Compose stack supervised by `newsblur.service`.

- Web UI: <https://cinderace.tailfe05b.ts.net>
- Compose config: `~/.config/newsblur/compose.yml`
- Application and persistent data: `~/.local/share/media-stack/newsblur`
- Local secrets: `~/.local/share/media-stack/newsblur/newsblur.env`

New accounts are assigned the Premium Archive tier automatically. Stories and
story hashes use a 365,000-day retention window, and Elasticsearch provides
full-archive search.

Ask AI and Daily Briefing require one supported provider key. Add an
`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, or `GOOGLE_GEMINI_API_KEY` value to the
local `newsblur.env` file and restart `newsblur.service`.

Useful commands:

```bash
systemctl --user restart newsblur.service
systemctl --user status newsblur.service
podman-compose -f ~/.config/newsblur/compose.yml ps
podman-compose -f ~/.config/newsblur/compose.yml logs -f
```
