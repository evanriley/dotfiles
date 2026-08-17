import os

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
    'fw': 'https://docs.fedoraproject.org/en-US/search/?q={}',
    'yt': 'https://www.youtube.com/results?search_query={}',
    'gh': 'https://github.com/search?q={}'
}
c.url.default_page = 'https://kagi.com'
c.url.start_pages = ['https://kagi.com']

# --- 2. LUNA THEME ---
# Transparency disabled for solid look
c.window.transparent = False

# https://github.com/WTFox/luna.nvim
p = {
    'bg': "#060606",
    'bg_alt': "#1c1c1c",
    'bg_soft': "#1f1f1f",
    'surface': "#333333",
    'sel': "#384048",
    'border': "#404040",
    'mute': "#7c7c7c",
    'grey': "#a8a8a8",
    'fg': "#e4e4e8",
    'bright': "#f0f0f0",
    'keyword': "#e19067",
    'info': "#75a1c7",
    'match': "#c4a8d6",
    'string': "#9eb38e",
    'signal': "#c2916a",
    'error': "#e08585",
    'warn': "#d9a35a",
    'ok': "#6fbe80",
}

# TABS (Solid & Minimal)
c.tabs.position = 'top'
c.tabs.padding = {'top': 10, 'bottom': 10, 'left': 5, 'right': 5}
c.tabs.indicator.width = 0 
c.tabs.favicons.scale = 1.0
c.tabs.title.format = '{audio}{index}: {current_title}'
c.tabs.show = 'multiple'

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

c.colors.statusbar.normal.bg = p['bg']
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

ua_chrome = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36'
config.set('content.headers.user_agent', ua_chrome, 'accounts.google.com')
config.set('content.headers.user_agent', ua_chrome, 'https://accounts.google.com/*')

c.content.tls.certificate_errors = 'block' # This might be bad but I'm too annoyed to care

# Bitwarden
config.bind('<Space>pl', 'spawn --userscript qute-bitwarden-fuzzel')
config.bind('<Space>pu', 'spawn --userscript qute-bitwarden-fuzzel --username-only')
config.bind('<Space>pp', 'spawn --userscript qute-bitwarden-fuzzel --password-only')
config.bind('<Space>po', 'spawn --userscript qute-bitwarden-fuzzel --totp-only')

# MPV
config.bind('M', 'hint links spawn --detach mpv {hint-url}')
config.bind('xm', 'spawn --detach mpv {url}')

# Editor (Ctrl+E)
c.editor.command = ["kitty", "--class", "dotfiles-floating", "-e", "nvim", "-f", "{file}", "-c", "normal {line}G{column0}l"]

# Readability (ZR)
config.bind('ZR', 'spawn --userscript readability-js')

# Force Dark Mode on all sites
# 'smart' tries to be intelligent about images, 'lightness-cielab' is usually the best looking algorithm
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

# Clone a git repo to Code folder
config.bind('gc', 'spawn --userscript git-clone')
