local wezterm = require 'wezterm'
local act = wezterm.action
local sessionizer = require 'sessionizer'
local smart_splits = wezterm.plugin.require 'https://github.com/mrjones2014/smart-splits.nvim'
local config = wezterm.config_builder()

-- config.default_prog = { '/home/evan/.cargo/bin/nu' }
config.default_workspace = 'main'
config.scrollback_lines = 3000
config.window_close_confirmation = 'AlwaysPrompt'
config.color_scheme_dirs = { '~/.config/wezterm/colors' }
-- local function get_appearance()
--   local handle = io.popen 'darkman get'
--   local result = handle:read '*a'
--   handle:close()
--   return result:match '^%s*(.-)%s*$'
-- end

-- local appearance = get_appearance()
config.color_scheme = 'kanagawa-paper-ink'

-- if appearance == 'dark' then
--   config.color_scheme = 'kanagawa-paper-ink'
-- end

config.leader = { key = ' ', mods = 'CTRL', timeout_milliseconds = 1000 }
config.keys = {
  { key = 'c', mods = 'LEADER', action = act.ActivateCopyMode },
  { key = 'phys:Space', mods = 'LEADER', action = act.ActivateCommandPalette },

  -- Pane keybindings
  { key = 's', mods = 'LEADER', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
  { key = 'v', mods = 'LEADER', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'q', mods = 'LEADER', action = act.CloseCurrentPane { confirm = true } },
  { key = 'z', mods = 'LEADER', action = act.TogglePaneZoomState },
  { key = 'o', mods = 'LEADER', action = act.RotatePanes 'Clockwise' },
  -- We can make separate keybindings for resizing panes
  -- But Wezterm offers custom "mode" in the name of "KeyTable"
  {
    key = 'r',
    mods = 'LEADER',
    action = act.ActivateKeyTable { name = 'resize_pane', one_shot = false },
  },

  -- Tab keybindings
  { key = 't', mods = 'LEADER', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = '[', mods = 'LEADER', action = act.ActivateTabRelative(-1) },
  { key = ']', mods = 'LEADER', action = act.ActivateTabRelative(1) },
  { key = 'n', mods = 'LEADER', action = act.ShowTabNavigator },
  {
    key = 'e',
    mods = 'LEADER',
    action = act.PromptInputLine {
      description = wezterm.format {
        { Attribute = { Intensity = 'Bold' } },
        { Foreground = { AnsiColor = 'Fuchsia' } },
        { Text = 'Renaming Tab Title...:' },
      },
      action = wezterm.action_callback(function(window, pane, line)
        if line then
          window:active_tab():set_title(line)
        end
      end),
    },
  },
  -- Key table for moving tabs around
  { key = 'm', mods = 'LEADER', action = act.ActivateKeyTable { name = 'move_tab', one_shot = false } },
  -- Or shortcuts to move tab w/o move_tab table. SHIFT is for when caps lock is on
  { key = '{', mods = 'LEADER|SHIFT', action = act.MoveTabRelative(-1) },
  { key = '}', mods = 'LEADER|SHIFT', action = act.MoveTabRelative(1) },

  -- Workspaces
  { key = 'w', mods = 'LEADER', action = act.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' } },
  {
    key = 'E',
    mods = 'LEADER',
    action = act.PromptInputLine {
      description = wezterm.format {
        { Attribute = { Intensity = 'Bold' } },
        { Foreground = { AnsiColor = 'Fuchsia' } },
        { Text = 'Renaming Workspace Title...:' },
      },
      action = wezterm.action_callback(function(window, pane, line)
        if line then
          wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
        end
      end),
    },
  },
  {
    key = 'g',
    mods = 'LEADER',
    action = act.SwitchToWorkspace {
      name = 'gh-dash',
      spawn = { args = { '/usr/bin/fish', '-c', 'gh dash' } },
    },
  },

  -- Open sessioniser window
  { key = 'f', mods = 'LEADER', action = wezterm.action_callback(sessionizer.toggle) },
}

-- I can use the tab navigator (LDR t), but I also want to quickly navigate tabs with index
for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = 'LEADER',
    action = act.ActivateTab(i - 1),
  })
end

config.key_tables = {
  resize_pane = {
    { key = 'h', action = act.AdjustPaneSize { 'Left', 1 } },
    { key = 'j', action = act.AdjustPaneSize { 'Down', 1 } },
    { key = 'k', action = act.AdjustPaneSize { 'Up', 1 } },
    { key = 'l', action = act.AdjustPaneSize { 'Right', 1 } },
    { key = 'Escape', action = 'PopKeyTable' },
    { key = 'Enter', action = 'PopKeyTable' },
  },
  move_tab = {
    { key = 'h', action = act.MoveTabRelative(-1) },
    { key = 'j', action = act.MoveTabRelative(-1) },
    { key = 'k', action = act.MoveTabRelative(1) },
    { key = 'l', action = act.MoveTabRelative(1) },
    { key = 'Escape', action = 'PopKeyTable' },
    { key = 'Enter', action = 'PopKeyTable' },
  },
}

config.force_reverse_video_cursor = true

config.font = wezterm.font_with_fallback {
  'Berkeley Mono',
  'Symbols Nerd Font Mono',
}

config.font_size = 14
config.line_height = 1.0

config.use_fancy_tab_bar = false
config.tab_max_width = 28
config.tab_bar_at_bottom = true
config.status_update_interval = 1000
config.window_decorations = 'NONE'
config.enable_scroll_bar = false

config.window_padding = {
  left = 5,
  right = 0,
  top = 0,
  bottom = 0,
}

config.freetype_load_target = 'Normal'

config.window_frame = {
  font = wezterm.font { family = 'Berkeley Mono', weight = 'Bold' },
  font_size = 14,
}

wezterm.on('update-status', function(window, pane)
  -- Workspace name
  local stat = window:active_workspace()
  local stat_color = '#f7768e'
  -- It's a little silly to have workspace name all the time
  -- Utilize this to display LDR or current key table name
  if window:active_key_table() then
    stat = window:active_key_table()
    stat_color = '#7dcfff'
  end
  if window:leader_is_active() then
    stat = 'LDR'
    stat_color = '#bb9af7'
  end

  local basename = function(s)
    -- Nothing a little regex can't fix
    return string.gsub(s, '(.*[/\\])(.*)', '%2')
  end

  -- Current working directory
  local cwd = pane:get_current_working_dir()
  if cwd then
    if type(cwd) == 'userdata' then
      -- Wezterm introduced the URL object in 20240127-113634-bbcac864
      cwd = basename(cwd.file_path)
    else
      -- 20230712-072601-f4abf8fd or earlier version
      cwd = basename(cwd)
    end
  else
    cwd = ''
  end

  -- Current command
  local cmd = pane:get_foreground_process_name()
  -- CWD and CMD could be nil (e.g. viewing log using Ctrl-Alt-l)
  cmd = cmd and basename(cmd) or ''

  -- Time
  local time = wezterm.strftime '%I:%M %P'

  -- Left status (left of the tab line)
  window:set_left_status(wezterm.format {
    { Foreground = { Color = stat_color } },
    { Text = '  ' },
    { Text = wezterm.nerdfonts.oct_table .. '  ' .. stat },
    { Text = ' | ' },
  })

  -- Right status
  window:set_right_status(wezterm.format {
    -- Wezterm has a built-in nerd fonts
    -- https://wezfurlong.org/wezterm/config/lua/wezterm/nerdfonts.html
    { Text = wezterm.nerdfonts.md_folder .. '  ' .. cwd },
    { Text = ' | ' },
    { Foreground = { Color = '#e0af68' } },
    { Text = wezterm.nerdfonts.fa_code .. '  ' .. cmd },
    'ResetAttributes',
    { Text = ' | ' },
    { Text = wezterm.nerdfonts.md_clock .. '  ' .. time },
    { Text = '  ' },
  })
end)

smart_splits.apply_to_config(config, {
  -- the default config is here, if you'd like to use the default keys,
  -- you can omit this configuration table parameter and just use
  -- smart_splits.apply_to_config(config)

  -- directional keys to use in order of: left, down, up, right
  direction_keys = { 'h', 'j', 'k', 'l' },
  -- modifier keys to combine with direction_keys
  modifiers = {
    move = 'CTRL', -- modifier to use for pane movement, e.g. CTRL+h to move left
    resize = 'META', -- modifier to use for pane resize, e.g. META+h to resize to the left
  },
})

return config
