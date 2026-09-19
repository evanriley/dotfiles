import pathlib

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

# --- 2. KANSO THEME ---
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
c.content.user_stylesheets = [str(pathlib.Path.home() / ".config/qutebrowser/youtube.css")]

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


# Static Kanso Zen palette; startup needs no generated theme files.
mode = 'dark'
apply_palette({
    'bg': '#090e13', 'bg_alt': '#1c1e25', 'bg_soft': '#12151c',
    'selection': '#22262d', 'border': '#393b44', 'muted': '#909398',
    'fg': '#c5c9c7', 'fg_alt': '#a6a69c', 'blue': '#8ba4b0',
    'green': '#8a9a7b', 'green_alt': '#87a987', 'magenta': '#a292a3',
    'yellow': '#c4b28a', 'yellow_bright': '#e6c384', 'red': '#c4746e',
    'rust': '#b6927b',
})

# --- 3. UI & FONTS ---
c.scrolling.bar = 'never'
c.fonts.default_family = "Berkeley Mono"
c.fonts.default_size = "12pt"
c.fonts.web.size.default = 16

c.downloads.position = 'bottom'
c.downloads.remove_finished = 5000
c.downloads.location.suggestion = 'both'
c.downloads.location.prompt = False
# Use Qt's standard location until the guide creates the Downloads directory.
_downloads = pathlib.Path.home() / 'Downloads'
c.downloads.location.directory = str(_downloads) if _downloads.is_dir() else None

c.completion.open_categories = ['history', 'quickmarks', 'bookmarks',
                                'searchengines', 'filesystem']

# The ':open' history completion is ordered by 'ORDER BY last_atime DESC' in
# completion/models/histcategory.py -- pure recency, with no term for how often
# a site is visited, so a page opened once yesterday outranks one visited daily
# for a year. No setting exposes the ordering, so the ORDER BY is rewritten as
# the query is handed to SQLite.
#
# The score is Mozilla's frecency shape: each visit contributes a weight that
# falls off with the age of that visit, summed per URL. Frequency accumulates
# while recency still breaks ties.
#
# This needs an index on History(url). qutebrowser declares one, but
# SqlTable.create_index returns early unless the schema version just changed,
# so a profile that never saw a version bump does not have it. Without the
# index the sort is a full table scan per candidate row: 2175 ms for an empty
# pattern, against 8.8 ms with it.
try:
    from qutebrowser.misc import sql as _sql

    _FRECENCY = """(SELECT SUM(CASE
        WHEN h.atime > strftime('%s','now') - 345600  THEN 100
        WHEN h.atime > strftime('%s','now') - 1209600 THEN 70
        WHEN h.atime > strftime('%s','now') - 2678400 THEN 50
        WHEN h.atime > strftime('%s','now') - 7776000 THEN 30
        ELSE 10 END)
      FROM History h
      WHERE h.url = CompletionHistory.url AND NOT h.redirect)"""

    _STOCK_ORDER = 'ORDER BY last_atime DESC'
    _orig_query = _sql.Database.query

    if not getattr(_orig_query, '_frecency_patched', False):
        _index_done = []

        def _frecency_query(self, querystr, forward_only=True):
            # Only the completion query itself. The max_items subquery in
            # _atime_expr() also selects from CompletionHistory with the same
            # ORDER BY and must be left alone; it does not select url, title.
            if querystr.startswith('SELECT url, title,') and _STOCK_ORDER in querystr:
                try:
                    if not _index_done:
                        _orig_query(self, 'CREATE INDEX IF NOT EXISTS '
                                          'HistoryIndex ON History (url)').run()
                        _index_done.append(True)
                except Exception:
                    # A locked or read-only history database would otherwise
                    # raise into the completion itself. Recency also happens
                    # to be the right fallback: without the index the frecency
                    # sort is a full table scan per candidate row, 2175ms
                    # against 8.8ms for an empty pattern.
                    pass
                else:
                    querystr = querystr.replace(
                        _STOCK_ORDER,
                        'ORDER BY {} DESC, last_atime DESC'.format(_FRECENCY))
            return _orig_query(self, querystr, forward_only)

        _frecency_query._frecency_patched = True
        _sql.Database.query = _frecency_query
except Exception:
    # An upgrade that moves this seam should cost stock ordering, never a
    # browser that cannot open a URL.
    pass
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

# --- QT 6.11 SCRIPT-INJECTION WORKAROUND ---
# QtWebEngine 6.11 sometimes drops the DocumentCreation injection of
# qutebrowser's own JavaScript; a redirecting URL opened in a new tab
# (':open -t http://duckduckgo.com') reproduces it. window._qutebrowser is then
# undefined in the application world, so 'f' fails with "Unknown error while
# getting elements" and j/k, <Ctrl-d>/<Ctrl-u> and caret mode stay dead until
# the tab is reloaded. Upstream: qutebrowser#8925, fix pending in #8940.
#
# find_css is the only affected path that reports an error, so it is the hook:
# on that specific failure the bundle is re-evaluated into the application
# world and the lookup retried once. Scrolling and caret mode come back with
# it, since the whole bundle is restored.
#
# Both steps are posted to the event loop. A runJavaScript issued from inside
# a runJavaScript callback never has its result delivered.
#
# stylesheet.js is deliberately left out of the bundle: injecting it here
# never returns, and user stylesheets do not error out visibly anyway.
#
# WebEngineElements is imported after config.py runs, and configfiles.py drops
# every module config.py imports back out of sys.modules, so the class cannot
# be reached directly. __init_subclass__ on its already-imported base catches
# the class as it is defined instead.
try:
    from qutebrowser.browser import browsertab as _browsertab
    from qutebrowser.utils import resources as _resources
    from qutebrowser.qt.core import QTimer as _QTimer

    _MISSING = 'Unknown error while getting elements'

    def _reinject_code():
        return ('(function() {{ "use strict";\n'
                'if (!window.hasOwnProperty("_qutebrowser")) {{'
                ' window._qutebrowser = {{"initialized": {{}}}}; }}\n'
                '{}\n'
                'window._qutebrowser.initialized["scripts"] = true;\n'
                '}})();').format('\n'.join(
                    _resources.read_file('javascript/' + name)
                    for name in ('scroll.js', 'webelem.js', 'caret.js')))

    def _patch_elements(cls):
        if getattr(cls.find_css, '_reinjects', False):
            return
        orig = cls.find_css

        def find_css(self, selector, callback, error_cb, *,
                     only_visible=False, _retry=True):
            def on_error(err):
                if not (_retry and _MISSING in str(err)):
                    error_cb(err)
                    return

                def retry():
                    find_css(self, selector, callback, error_cb,
                             only_visible=only_visible, _retry=False)

                def reinject():
                    self._tab.run_js_async(_reinject_code())
                    _QTimer.singleShot(0, retry)

                _QTimer.singleShot(0, reinject)

            orig(self, selector, callback, on_error, only_visible=only_visible)

        find_css._reinjects = True
        cls.find_css = find_css

    def _on_subclass(cls, **kwargs):
        super(_browsertab.AbstractElements, cls).__init_subclass__(**kwargs)
        if cls.__name__ == 'WebEngineElements':
            _patch_elements(cls)

    _browsertab.AbstractElements.__init_subclass__ = classmethod(_on_subclass)
    # ':config-source' re-runs this file after the class already exists.
    for _sub in _browsertab.AbstractElements.__subclasses__():
        if _sub.__name__ == 'WebEngineElements':
            _patch_elements(_sub)
except Exception:
    # A qutebrowser upgrade that moves this seam should cost the workaround,
    # never a browser that fails to start.
    pass

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
    '-c', 'call cursor({line}, {column})',
]

# Match the static dark desktop while respecting site-specific exceptions.
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

# Standalone Arch actions; account-dependent userscripts can be restored later.
config.bind('M', 'hint links spawn --detach mpv {hint-url}')
config.bind('xm', 'spawn --detach mpv {url}')
config.bind('yy', 'yank')
config.bind('yr', 'yank')
