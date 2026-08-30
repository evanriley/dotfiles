import os
import pathlib
import re

config.load_autoconfig(False)
c.auto_save.session = True

c.qt.force_software_rendering = 'none'

# Black video frames on this RDNA4/Wayland setup come from the zero-copy leg
# of the GBM texture-import path, not from hardware decode itself. Turning off
# QTWEBENGINE_FORCE_USE_GBM disables both, which costs hardware video decode
# (Chromium then drops AcceleratedVideoDecoder). Disabling only the zero-copy
# feature keeps the decoder and renders correctly.
#
# If black frames ever come back, set QTWEBENGINE_FORCE_USE_GBM=0 in the
# environment instead -- that is the blunt version of this workaround.
c.qt.args = ['disable-features=AcceleratedVideoDecodeLinuxZeroCopyGL']

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
# ':open gh' visits github.com instead of searching for the string "gh".
c.url.open_base_url = True

# --- 2. MODUS THEME ---
c.window.transparent = False

# TABS (Solid & Minimal)
c.tabs.position = 'left'
c.tabs.width = 240
c.tabs.padding = {'top': 10, 'bottom': 10, 'left': 5, 'right': 5}
c.tabs.indicator.width = 0
c.tabs.favicons.scale = 1.0
c.tabs.title.format = '{audio}{index}: {current_title}'
c.tabs.show = 'never'

# STATUS BAR
c.statusbar.show = 'in-mode'
c.statusbar.padding = {'top': 5, 'bottom': 5, 'left': 5, 'right': 5}
c.statusbar.widgets = ['keypress', 'url', 'scroll', 'history', 'tabs', 'progress']

c.colors.webpage.preferred_color_scheme = "auto"
c.content.user_stylesheets = ["/home/evan/.config/qutebrowser/youtube.css"]

# The Modus palette lives in ~/.local/share/darkman/10-modus-theme, which
# regenerates this file on every mode switch. qutebrowser keeps no copy.
PALETTE_FILE = (
    pathlib.Path(os.environ.get('XDG_STATE_HOME') or pathlib.Path.home()
                 / '.local' / 'state') / 'darkman' / 'qutebrowser.conf'
)
PALETTE_KEYS = frozenset({
    'bg', 'bg_alt', 'bg_soft', 'selection', 'border', 'muted', 'fg', 'fg_alt',
    'blue', 'green', 'green_alt', 'magenta', 'yellow', 'yellow_bright', 'red',
    'rust',
})
HEX_COLOR = re.compile(r'#[0-9a-f]{6}')
FALLBACK_MODE = 'dark'


def load_palette(path):
    """Read the generated palette, or None when it is unusable.

    Absent, unreadable, half-written and malformed files all yield None so
    that qutebrowser still starts -- notably on a checkout where darkman has
    never run. Validation is strict because a partial palette would paint an
    unreadable mix of the two modes.
    """
    try:
        text = path.read_text(encoding='utf-8')
    except (OSError, UnicodeDecodeError):
        return None
    palette = {}
    for line in text.splitlines():
        if not line.strip():
            continue
        key, separator, value = line.partition('=')
        if not separator:
            return None
        palette[key.strip()] = value.strip()
    if palette.get('mode') not in ('light', 'dark'):
        return None
    if not PALETTE_KEYS <= palette.keys():
        return None
    if not all(HEX_COLOR.fullmatch(palette[key]) for key in PALETTE_KEYS):
        return None
    return palette


def apply_palette(p):
    # Tab Colors
    c.colors.tabs.bar.bg = p['bg']

    # Inactive Tabs (Background color + Muted Text)
    c.colors.tabs.odd.bg = p['bg']
    c.colors.tabs.even.bg = p['bg']
    c.colors.tabs.odd.fg = p['muted']
    c.colors.tabs.even.fg = p['muted']

    # Active Tab (Selection Background + Bright Text)
    c.colors.tabs.selected.odd.bg = p['selection']
    c.colors.tabs.selected.even.bg = p['selection']
    c.colors.tabs.selected.odd.fg = p['fg']
    c.colors.tabs.selected.even.fg = p['fg']

    # Pinned Tabs
    c.colors.tabs.pinned.even.bg = p['selection']
    c.colors.tabs.pinned.odd.bg = p['selection']
    c.colors.tabs.pinned.even.fg = p['fg_alt']
    c.colors.tabs.pinned.odd.fg = p['fg_alt']
    c.colors.tabs.pinned.selected.even.bg = p['selection']
    c.colors.tabs.pinned.selected.odd.bg = p['selection']
    c.colors.tabs.pinned.selected.even.fg = p['fg']
    c.colors.tabs.pinned.selected.odd.fg = p['fg']
    c.colors.tabs.indicator.start = p['blue']
    c.colors.tabs.indicator.stop = p['green_alt']
    c.colors.tabs.indicator.error = p['red']

    # Status bar
    c.colors.statusbar.normal.bg = p['bg_alt']
    c.colors.statusbar.normal.fg = p['fg']
    c.colors.statusbar.insert.bg = p['blue']
    c.colors.statusbar.insert.fg = p['bg']
    c.colors.statusbar.command.bg = p['selection']
    c.colors.statusbar.command.fg = p['fg']
    c.colors.statusbar.command.private.bg = p['selection']
    c.colors.statusbar.command.private.fg = p['magenta']
    c.colors.statusbar.caret.bg = p['magenta']
    c.colors.statusbar.caret.fg = p['bg']
    c.colors.statusbar.caret.selection.bg = p['rust']
    c.colors.statusbar.caret.selection.fg = p['bg']
    c.colors.statusbar.passthrough.bg = p['yellow']
    c.colors.statusbar.passthrough.fg = p['bg']
    c.colors.statusbar.private.bg = p['bg_soft']
    c.colors.statusbar.private.fg = p['magenta']
    c.colors.statusbar.progress.bg = p['blue']
    c.colors.statusbar.url.error.fg = p['red']
    c.colors.statusbar.url.hover.fg = p['magenta']
    c.colors.statusbar.url.warn.fg = p['yellow_bright']
    c.colors.statusbar.url.success.http.fg = p['muted']
    c.colors.statusbar.url.success.https.fg = p['green']

    # HINTS
    c.colors.hints.bg = p['yellow_bright']
    c.colors.hints.fg = p['bg']
    c.colors.hints.match.fg = p['red']

    # COMPLETION MENU
    c.colors.completion.category.bg = p['bg']
    c.colors.completion.category.fg = p['fg_alt']
    c.colors.completion.category.border.top = p['border']
    c.colors.completion.category.border.bottom = p['border']
    c.colors.completion.odd.bg = p['bg']
    c.colors.completion.even.bg = p['bg_alt']
    c.colors.completion.fg = p['fg']
    c.colors.completion.item.selected.bg = p['selection']
    c.colors.completion.item.selected.fg = p['fg']
    c.colors.completion.item.selected.border.top = p['selection']
    c.colors.completion.item.selected.border.bottom = p['selection']
    c.colors.completion.match.fg = p['magenta']
    c.colors.completion.item.selected.match.fg = p['rust']
    c.colors.completion.scrollbar.bg = p['bg_alt']
    c.colors.completion.scrollbar.fg = p['fg_alt']

    # Prompts, messages, downloads, and key hints
    c.colors.prompts.bg = p['bg_alt']
    c.colors.prompts.fg = p['fg']
    c.colors.prompts.border = '1px solid ' + p['border']
    c.colors.prompts.selected.bg = p['selection']
    c.colors.prompts.selected.fg = p['fg']
    c.colors.messages.info.bg = p['bg_alt']
    c.colors.messages.info.border = p['blue']
    c.colors.messages.info.fg = p['fg']
    c.colors.messages.warning.bg = p['bg_alt']
    c.colors.messages.warning.border = p['yellow_bright']
    c.colors.messages.warning.fg = p['yellow_bright']
    c.colors.messages.error.bg = p['bg_alt']
    c.colors.messages.error.border = p['red']
    c.colors.messages.error.fg = p['red']
    c.colors.keyhint.bg = p['bg_alt']
    c.colors.keyhint.fg = p['fg']
    c.colors.keyhint.suffix.fg = p['rust']
    c.colors.downloads.bar.bg = p['bg']
    c.colors.downloads.start.bg = p['blue']
    c.colors.downloads.start.fg = p['bg']
    c.colors.downloads.stop.bg = p['green']
    c.colors.downloads.stop.fg = p['bg']
    c.colors.downloads.error.bg = p['red']
    c.colors.downloads.error.fg = p['bg']

    c.colors.webpage.bg = p['bg']


_palette = load_palette(PALETTE_FILE)
# Without a palette the stock qutebrowser colors stand; forced page darkening
# still needs a mode, and dark is the safer guess for an unthemed session.
mode = _palette['mode'] if _palette is not None else FALLBACK_MODE
if _palette is not None:
    apply_palette(_palette)

# --- 3. UI & FONTS ---
c.scrolling.bar = 'never'
c.fonts.default_family = "Berkeley Mono"
c.fonts.default_size = "12pt"
c.fonts.web.size.default = 16 

c.downloads.position = 'bottom'
c.downloads.remove_finished = 5000
c.downloads.location.suggestion = 'both'
c.downloads.location.prompt = False
c.downloads.location.directory = '~/Downloads'

c.completion.open_categories = ['quickmarks', 'bookmarks', 'history',
                                'searchengines', 'filesystem']
c.tabs.last_close = 'startpage'
c.tabs.mode_on_change = 'restore'
c.confirm_quit = ['downloads']
c.spellcheck.languages = ['en-US']

# --- 4. PERFORMANCE & PRIVACY ---
c.scrolling.smooth = False # Instant scrolling (snappy)
# One renderer per site rather than per site-instance: less memory across a
# large restored session, at the cost of less isolation between tabs.
c.qt.chromium.process_model = 'process-per-site'
c.content.autoplay = False
# The system pdf.js in /usr/share/pdf.js is installed.
c.content.pdfjs = True
c.session.lazy_restore = True
c.content.blocking.method = 'both'
# qutebrowser's adblocker is network-only -- it never applies element-hiding
# rules -- so a list's cosmetic half is parsed and discarded. The fanboy
# annoyance/social/cookiemonster lists were 92-95% cosmetic and contributed
# almost nothing here. uBlock Origin's lists are network-dense, and unbreak
# and quick-fixes are exception rules that undo breakage the other lists
# cause: the /akam/ whitelist below is exactly that class of problem.
c.content.blocking.adblock.lists = [
    "https://easylist.to/easylist/easylist.txt",
    "https://easylist.to/easylist/easyprivacy.txt",
    "https://ublockorigin.github.io/uAssets/filters/filters.txt",
    "https://ublockorigin.github.io/uAssets/filters/badware.txt",
    "https://ublockorigin.github.io/uAssets/filters/privacy.txt",
    "https://ublockorigin.github.io/uAssets/filters/quick-fixes.txt",
    "https://ublockorigin.github.io/uAssets/filters/unbreak.txt",
    # Peter Lowe's list: every rule is a network rule, none are cosmetic.
    "https://pgl.yoyo.org/adservers/serverlist.php"
    "?hostformat=adblockplus&showintro=0&mimetype=plaintext",
]
# Cloudflare Turnstile must load its cross-origin challenge script and iframe.
# EasyPrivacy's /akam/1{0,1,3}/* rules block Akamai Bot Manager's sensor
# endpoint, which makes sites like bestbuy.com return "Access Denied".
c.content.blocking.whitelist = [
    'https://challenges.cloudflare.com/*',
    '*://*/akam/*',
]

c.content.tls.certificate_errors = 'block'

# Deny sensitive capabilities by default. Grant exceptions later with
# config.set(..., URL_PATTERN) when a specific site genuinely needs one.
c.content.desktop_capture = False
c.content.geolocation = False
c.content.media.audio_capture = False
c.content.media.audio_video_capture = False
c.content.media.video_capture = False
c.content.mouse_lock = False
c.content.notifications.enabled = False
c.content.persistent_storage = False
c.content.register_protocol_handler = False

# 'none' also makes qutebrowser auto-deny Qt 6.8's ClipboardReadWrite
# permission, which breaks every site's "Copy" button. 'access' allows
# JavaScript clipboard writes and reads but still blocks execCommand('paste').
c.content.javascript.clipboard = 'access'

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
# Generate a fresh addy.io alias, type it into the focused field and put it on
# the clipboard so it can be pasted into the Bitwarden entry being saved.
config.bind('<Space>pa', 'spawn --userscript qute-addy')

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
# Search mouse-highlighted or primary-selected text in a new tab.
config.bind('ss', 'open -t {primary}')

# Edit form fields in Neovim with Ctrl+E while in insert mode.
c.editor.command = [
    'foot', '--app-id=qute-editor', 'nvim', '-f', '{file}',
    '-c', 'normal {line}G{column0}l',
]

# Readability (ZR)
config.bind('ZR', 'spawn --userscript readability-js')

# Forced dark mode follows darkman. Only 'enabled' can change at runtime; its
# siblings below are startup-only, so darkman switches toggle just this one.
# Blink already leaves alone any page that declares `color-scheme: dark`, so
# this never touches github, gitlab, duckduckgo, x, wikipedia, mdn,
# docs.python.org, kagi or lobste.rs -- they render their own dark theme.
c.colors.webpage.darkmode.enabled = mode == 'dark'
c.colors.webpage.darkmode.algorithm = 'lightness-cielab'
c.colors.webpage.darkmode.policy.images = 'smart' # Don't invert photos

# Sites that ship a good dark theme but drive it from an account setting or a
# JS toggle rather than a declared color-scheme. Chromium cannot detect those,
# so forcing dark on top of them inverts an already-dark page. YouTube is the
# worst case: its forced dark-mode compositor can make the video layer
# invisible while audio and controls keep working.
#
# Check a site with <Space>td (toggles for the current host and reloads); if
# the page looks better untouched, add it here. Reddit is deliberately absent:
# the old layout has no dark theme of its own and does want forcing, and the
# account preference serves it from www.reddit.com rather than old.reddit.com.
darkmode_native_sites = [
    '*://*.youtube.com/*',
    '*://*.discord.com/*',
    '*://*.fastmail.com/*',
    '*://*.codeberg.org/*',
    '*://*.crates.io/*',
]
for _pattern in darkmode_native_sites:
    config.set('colors.webpage.darkmode.enabled', False, _pattern)

# Try a site's own dark theme instead of Chromium's, for the current host.
config.bind(
    '<Space>td',
    'config-cycle -t -p -u *://{url:host}/* colors.webpage.darkmode.enabled'
    ' false true ;; reload',
)

c.content.cookies.accept = 'no-3rdparty'
c.content.headers.referer = 'same-domain'
# Cloudflare's human verification rejects modified Canvas/WebGL APIs.
c.content.canvas_reading = True

# Use home row keys for hints (Vim style)
c.hints.chars = 'asdfghjkl'

# 'yy' -> Copy URL, with tracking parameters stripped (ClearURLs ruleset).
# The userscript writes to the clipboard itself with wl-copy rather than going
# through ':yank inline', which would run the URL through the command parser.
# If cleaning fails for any reason it copies the URL unchanged and says so.
config.bind('yy', 'spawn --userscript qute-cleanurl')
# 'yr' -> Copy the raw URL, exactly as the address bar has it. 'yY' is taken by
# the builtin (yank --sel), so the raw copy lives on a free key instead.
config.bind('yr', 'yank')
# 'yt' -> Copy Title and cleaned URL (Great for sharing/markdown)
# Copies: [Page Title](https://url...)
config.bind('yt', 'spawn --userscript qute-cleanurl --markdown')
