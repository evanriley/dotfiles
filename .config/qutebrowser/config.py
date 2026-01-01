import os

config.load_autoconfig(False)
c.auto_save.session = True

# --- 1. SEARCH ENGINES & START PAGE ---
c.url.searchengines = {
    'DEFAULT': 'https://kagi.com/search?q={}',
    'g':  'https://google.com/search?q={}',
    'aw': 'https://wiki.archlinux.org/?search={}',
    'gw': 'https://wiki.gentoo.org/?search-mr=1&search={}',
    'yt': 'https://www.youtube.com/results?search_query={}',
    'gh': 'https://github.com/search?q={}'
}
c.url.default_page = 'https://kagi.com'
c.url.start_pages = ['https://kagi.com']

# --- 2. THE SOLID KANSO ZEN THEME ---
# Transparency disabled for solid look
c.window.transparent = False

# Palette (Strictly based on Foot Config)
p = {
    'bg': "#090e13",       # Background
    'fg': "#c5c9c7",       # Foreground
    'sel': "#22262d",      # Selection Background
    'mute': "#a4a7a4",     # Regular 7 (Muted text)
    'match': "#938aa9",    # Bright 5 (Violet/Magenta)
    'error': "#e46876",    # Bright 1 (Red)
    'warn': "#e6c384",     # Bright 3 (Yellow)
    'info': "#7fb4ca",     # Bright 4 (Blue)
    'url':  "#72a7bc"      # Urls
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

# STATUS BAR
c.statusbar.padding = {'top': 5, 'bottom': 5, 'left': 5, 'right': 5}
c.statusbar.widgets = ['keypress', 'url', 'scroll', 'history', 'tabs', 'progress']

c.colors.statusbar.normal.bg = p['bg']
c.colors.statusbar.normal.fg = p['fg']
c.colors.statusbar.insert.bg = p['info'] # Blue-ish for insert
c.colors.statusbar.insert.fg = p['bg']
c.colors.statusbar.command.bg = p['sel']
c.colors.statusbar.command.fg = p['fg']
c.colors.statusbar.url.success.http.fg = p['mute']
c.colors.statusbar.url.success.https.fg = p['url']

# HINTS
c.colors.hints.bg = p['warn']
c.colors.hints.fg = p['bg']
c.colors.hints.match.fg = p['error']

# COMPLETION MENU
c.colors.completion.category.bg = p['bg']
c.colors.completion.item.selected.bg = p['sel']
c.colors.completion.item.selected.border.top = p['sel']
c.colors.completion.item.selected.border.bottom = p['sel']
c.colors.completion.match.fg = p['match']

# WEBPAGE (Dark Mode Preference)
c.colors.webpage.bg = "white"
c.colors.webpage.preferred_color_scheme = "dark"

# --- 3. UI & FONTS ---
c.scrolling.bar = 'never'
c.fonts.default_family = "Berkeley Mono"
c.fonts.default_size = "12pt"
c.fonts.web.size.default = 16 

c.colors.downloads.bar.bg = p['bg']
c.colors.downloads.start.bg = p['info']
c.colors.downloads.stop.bg = p['match']
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

c.qt.args = [
    '--enable-gpu-rasterization',
    '--enable-features=VaapiVideoDecodeLinuxGL',
    '--ignore-gpu-blocklist',
    '--enable-zero-copy',
    '--enable-smooth-scrolling',
    '--use-gl=egl'
]

ua_chrome = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36'
config.set('content.headers.user_agent', ua_chrome, 'accounts.google.com')
config.set('content.headers.user_agent', ua_chrome, 'https://accounts.google.com/*')

c.content.tls.certificate_errors = 'block' # This might be bad but I'm too annoyed to care

# RBW (Bitwarden)
config.bind('<Space>pl', 'spawn --userscript qute-rbw')
config.bind('<Space>pu', 'spawn --userscript qute-rbw --target username')
config.bind('<Space>po', 'spawn --userscript qute-rbw --target totp')

# MPV
config.bind('M', 'hint links spawn mpv {hint-url}')
config.bind('xm', 'spawn mpv {url}')

# Editor (Ctrl+E)
c.editor.command = ["kitty", "--class", "dotfiles-floating", "-e", "nvim", "-f", "{file}", "-c", "normal {line}G{column0}l"]

# Readability (ZR)
config.bind('ZR', 'spawn --userscript readability-js')

# Force Dark Mode on all sites
# 'smart' tries to be intelligent about images, 'lightness-cielab' is usually the best looking algorithm
c.colors.webpage.darkmode.enabled = True
c.colors.webpage.darkmode.algorithm = 'lightness-cielab' 
c.colors.webpage.darkmode.policy.images = 'smart' # Don't invert photos

c.content.cookies.accept = 'no-3rdparty'
c.content.headers.referer = 'same-domain'
c.content.canvas_reading = False

# Use home row keys for hints (Vim style)
c.hints.chars = 'asdfghjkl'

# 'yy' -> Copy URL
config.bind('yy', 'yank')
# 'yt' -> Copy Title and URL (Great for sharing/markdown)
# Copies: [Page Title](https://url...)
config.bind('yt', 'yank inline [{title}]({url})')

# Clone a git repo to Code folder
config.bind('gc', 'spawn --userscript git-clone')
