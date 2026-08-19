import os
import subprocess

# QtWebEngine's GBM texture-import path produces black video frames on this
# RDNA4/Wayland setup. This is the targeted workaround qutebrowser applies to
# affected AMD systems; keep Chromium's GPU compositing enabled.
os.environ['QTWEBENGINE_FORCE_USE_GBM'] = '0'

config.load_autoconfig(False)
c.auto_save.session = True

c.qt.force_software_rendering = 'none'

# --- 1. SEARCH ENGINES & START PAGE ---
c.url.searchengines = {
    'DEFAULT': 'https://kagi.com/search?q={}',
    'g':  'https://google.com/search?q={}',
    'aw': 'https://wiki.archlinux.org/?search={}',
    'ch': 'https://kagi.com/search?q=site%3Achimera-linux.org%2Fdocs+{}',
    'yt': 'https://www.youtube.com/results?search_query={}',
    'gh': 'https://github.com/search?q={}'
}
c.url.default_page = 'https://kagi.com'
c.url.start_pages = ['https://kagi.com']

# --- 2. MODUS THEME ---
c.window.transparent = False

try:
    mode = subprocess.run(
        ['darkman', 'get'], capture_output=True, text=True, timeout=1,
    ).stdout.strip()
except (OSError, subprocess.SubprocessError):
    mode = 'dark'

palettes = {
    'light': {
        'bg': '#ffffff', 'bg_alt': '#f2f2f2', 'bg_soft': '#dae5ec',
        'surface': '#c4c4c4', 'sel': '#dae5ec', 'border': '#9f9f9f',
        'mute': '#595959', 'grey': '#3b3b3b', 'fg': '#000000',
        'bright': '#000000', 'keyword': '#8a290f', 'info': '#0031a9',
        'match': '#721045', 'string': '#006800', 'signal': '#6f5500',
        'error': '#a60000', 'warn': '#884900', 'ok': '#316500',
    },
    'dark': {
        'bg': '#000000', 'bg_alt': '#1e1e1e', 'bg_soft': '#2f3849',
        'surface': '#646464', 'sel': '#2f3849', 'border': '#646464',
        'mute': '#989898', 'grey': '#c4c4c4', 'fg': '#ffffff',
        'bright': '#ffffff', 'keyword': '#db7b5f', 'info': '#2fafff',
        'match': '#feacd0', 'string': '#44bc44', 'signal': '#d0bc00',
        'error': '#ff5f59', 'warn': '#fec43f', 'ok': '#70b900',
    },
}
p = palettes.get(mode, palettes['dark'])

# TABS (Solid & Minimal)
c.tabs.position = 'left'
c.tabs.width = 240
c.tabs.padding = {'top': 10, 'bottom': 10, 'left': 5, 'right': 5}
c.tabs.indicator.width = 0 
c.tabs.favicons.scale = 1.0
c.tabs.title.format = '{audio}{index}: {current_title}'
c.tabs.show = 'never'

# Tab Colors
c.colors.tabs.bar.bg = p['bg']

# Inactive Tabs (Background color + Muted Text)
c.colors.tabs.odd.bg = p['bg']
c.colors.tabs.even.bg = p['bg']
c.colors.tabs.odd.fg = p['mute']
c.colors.tabs.even.fg = p['mute']

# Active Tab (Selection Background + Bright Text)
c.colors.tabs.selected.odd.bg = p['sel']
c.colors.tabs.selected.even.bg = p['sel']
c.colors.tabs.selected.odd.fg = p['fg']
c.colors.tabs.selected.even.fg = p['fg']

# Pinned Tabs
c.colors.tabs.pinned.even.bg = p['sel']
c.colors.tabs.pinned.odd.bg = p['sel']
c.colors.tabs.pinned.even.fg = p['grey']
c.colors.tabs.pinned.odd.fg = p['grey']
c.colors.tabs.pinned.selected.even.bg = p['sel']
c.colors.tabs.pinned.selected.odd.bg = p['sel']
c.colors.tabs.pinned.selected.even.fg = p['bright']
c.colors.tabs.pinned.selected.odd.fg = p['bright']
c.colors.tabs.indicator.start = p['info']
c.colors.tabs.indicator.stop = p['ok']
c.colors.tabs.indicator.error = p['error']

# STATUS BAR
c.statusbar.padding = {'top': 5, 'bottom': 5, 'left': 5, 'right': 5}
c.statusbar.widgets = ['keypress', 'url', 'scroll', 'history', 'tabs', 'progress']

c.colors.statusbar.normal.bg = p['bg_alt']
c.colors.statusbar.normal.fg = p['fg']
c.colors.statusbar.insert.bg = p['info'] # Blue-ish for insert
c.colors.statusbar.insert.fg = p['bg']
c.colors.statusbar.command.bg = p['sel']
c.colors.statusbar.command.fg = p['fg']
c.colors.statusbar.command.private.bg = p['sel']
c.colors.statusbar.command.private.fg = p['match']
c.colors.statusbar.caret.bg = p['match']
c.colors.statusbar.caret.fg = p['bg']
c.colors.statusbar.caret.selection.bg = p['keyword']
c.colors.statusbar.caret.selection.fg = p['bg']
c.colors.statusbar.passthrough.bg = p['signal']
c.colors.statusbar.passthrough.fg = p['bg']
c.colors.statusbar.private.bg = p['bg_soft']
c.colors.statusbar.private.fg = p['match']
c.colors.statusbar.progress.bg = p['info']
c.colors.statusbar.url.error.fg = p['error']
c.colors.statusbar.url.hover.fg = p['match']
c.colors.statusbar.url.warn.fg = p['warn']
c.colors.statusbar.url.success.http.fg = p['mute']
c.colors.statusbar.url.success.https.fg = p['string']

# HINTS
c.colors.hints.bg = p['warn']
c.colors.hints.fg = p['bg']
c.colors.hints.match.fg = p['error']

# COMPLETION MENU
c.colors.completion.category.bg = p['bg']
c.colors.completion.category.fg = p['grey']
c.colors.completion.category.border.top = p['border']
c.colors.completion.category.border.bottom = p['border']
c.colors.completion.odd.bg = p['bg']
c.colors.completion.even.bg = p['bg_alt']
c.colors.completion.fg = p['fg']
c.colors.completion.item.selected.bg = p['sel']
c.colors.completion.item.selected.fg = p['bright']
c.colors.completion.item.selected.border.top = p['sel']
c.colors.completion.item.selected.border.bottom = p['sel']
c.colors.completion.match.fg = p['match']
c.colors.completion.item.selected.match.fg = p['keyword']
c.colors.completion.scrollbar.bg = p['bg_alt']
c.colors.completion.scrollbar.fg = p['grey']

# Prompts, messages, downloads, and key hints
c.colors.prompts.bg = p['bg_alt']
c.colors.prompts.fg = p['fg']
c.colors.prompts.border = '1px solid ' + p['border']
c.colors.prompts.selected.bg = p['sel']
c.colors.prompts.selected.fg = p['bright']
c.colors.messages.info.bg = p['bg_alt']
c.colors.messages.info.border = p['info']
c.colors.messages.info.fg = p['fg']
c.colors.messages.warning.bg = p['bg_alt']
c.colors.messages.warning.border = p['warn']
c.colors.messages.warning.fg = p['warn']
c.colors.messages.error.bg = p['bg_alt']
c.colors.messages.error.border = p['error']
c.colors.messages.error.fg = p['error']
c.colors.keyhint.bg = p['bg_alt']
c.colors.keyhint.fg = p['fg']
c.colors.keyhint.suffix.fg = p['keyword']
c.colors.downloads.bar.bg = p['bg']
c.colors.downloads.start.bg = p['info']
c.colors.downloads.start.fg = p['bg']
c.colors.downloads.stop.bg = p['string']
c.colors.downloads.stop.fg = p['bg']
c.colors.downloads.error.bg = p['error']
c.colors.downloads.error.fg = p['bg']

# WEBPAGE (Dark Mode Preference)
c.colors.webpage.bg = p['bg']
c.colors.webpage.preferred_color_scheme = "auto"
c.content.user_stylesheets = ["/home/evan/.config/qutebrowser/youtube.css"]

# --- 3. UI & FONTS ---
c.scrolling.bar = 'never'
c.fonts.default_family = "Berkeley Mono"
c.fonts.default_size = "12pt"
c.fonts.web.size.default = 16 

c.downloads.position = 'bottom'
c.downloads.remove_finished = 5000

# --- 4. PERFORMANCE & PRIVACY ---
c.scrolling.smooth = False # Instant scrolling (snappy)
c.content.autoplay = False
c.content.blocking.method = 'both'
c.content.blocking.adblock.lists = [
    "https://easylist.to/easylist/easylist.txt",
    "https://easylist.to/easylist/easyprivacy.txt", 
    "https://secure.fanboy.co.nz/fanboy-cookiemonster.txt",
    "https://secure.fanboy.co.nz/fanboy-annoyance.txt",
    "https://easylist.to/easylist/fanboy-social.txt"
]
# Cloudflare Turnstile must load its cross-origin challenge script and iframe.
c.content.blocking.whitelist = ['https://challenges.cloudflare.com/*']

c.content.tls.certificate_errors = 'block'

# Deny sensitive capabilities by default. Grant exceptions later with
# config.set(..., URL_PATTERN) when a specific site genuinely needs one.
c.content.desktop_capture = False
c.content.geolocation = False
c.content.javascript.clipboard = 'none'
c.content.media.audio_capture = False
c.content.media.audio_video_capture = False
c.content.media.video_capture = False
c.content.mouse_lock = False
c.content.notifications.enabled = False
c.content.persistent_storage = False
c.content.register_protocol_handler = False

# QtWebEngine reports GitHub's Trusted Types policy when qutebrowser injects
# caret-mode JavaScript. The operation still works, so hide only that expected
# internal error while preserving all other JavaScript error messages.
c.content.javascript.log_message.excludes['userscript:_qute_js'] = [
    '*TrustedHTML*',
]

# Password manager
config.bind('<Space>pl', 'spawn --userscript qute-bitwarden-fuzzel')
config.bind('<Space>pu', 'spawn --userscript qute-bitwarden-fuzzel --username-only')
config.bind('<Space>pp', 'spawn --userscript qute-bitwarden-fuzzel --password-only')
config.bind('<Space>po', 'spawn --userscript qute-bitwarden-fuzzel --totp-only')

# MPV
config.bind('M', 'hint links spawn --detach /home/evan/.local/share/qutebrowser/userscripts/qute-mpv {hint-url}')
config.bind('xm', 'spawn --detach /home/evan/.local/share/qutebrowser/userscripts/qute-mpv {url}')

# Navigation helpers
config.bind('J', 'tab-next')
config.bind('K', 'tab-prev')
config.bind('T', 'config-cycle tabs.show always never')
config.bind(';r', 'hint --rapid links tab-bg')
config.bind('m', 'quickmark-save')
config.bind('b', 'cmd-set-text -s :quickmark-load')
config.bind('B', 'cmd-set-text -s :quickmark-load -t')

# Edit form fields in Neovim with Ctrl+E while in insert mode.
c.editor.command = [
    'foot', '--app-id=qute-editor', 'nvim', '-f', '{file}',
    '-c', 'normal {line}G{column0}l',
]

# Readability (ZR)
config.bind('ZR', 'spawn --userscript readability-js')

# Keep forced dark mode available for site-specific overrides, but disabled
# globally so sites can follow their own preferred color scheme.
c.colors.webpage.darkmode.enabled = False
c.colors.webpage.darkmode.algorithm = 'lightness-cielab' 
c.colors.webpage.darkmode.policy.images = 'smart' # Don't invert photos
# YouTube supplies its own dark theme. Chromium's forced dark-mode compositor can
# make the video layer invisible while audio and controls continue to work.
config.set('colors.webpage.darkmode.enabled', False, 'https://www.youtube.com/*')
config.set('colors.webpage.darkmode.enabled', False, 'https://youtube.com/*')

c.content.cookies.accept = 'no-3rdparty'
c.content.headers.referer = 'same-domain'
# Cloudflare's human verification rejects modified Canvas/WebGL APIs.
c.content.canvas_reading = True

# Use home row keys for hints (Vim style)
c.hints.chars = 'asdfghjkl'

# 'yy' -> Copy URL
config.bind('yy', 'yank')
# 'yt' -> Copy Title and URL (Great for sharing/markdown)
# Copies: [Page Title](https://url...)
config.bind('yt', 'yank inline [{title}]({url})')
