local mod = "SUPER"

local workspaces = {
    { id = 1, name = "web" },
    { id = 2, name = "social" },
    { id = 3, name = "game" },
    { id = 4, name = "misc" },
    { id = 5, name = "system" },
}

local function app(command)
    return "uwsm app -- " .. command
end

local function app_shell(command)
    return app("sh -lc " .. string.format("%q", command))
end

local function shell(command)
    return hl.dsp.exec_cmd(app_shell(command))
end

hl.monitor({
    output = "DP-2",
    mode = "5120x1440@119.979",
    position = "0x0",
    scale = 1,
})

hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = "auto",
})

hl.config({
    general = {
        layout = "master",
        gaps_in = 0,
        gaps_out = 0,
        border_size = 0,
        resize_on_border = false,
        allow_tearing = false,
        col = {
            active_border = "rgb(596467)",
            inactive_border = "rgb(20272b)",
        },
    },
    decoration = {
        rounding = 6,
        rounding_power = 2,
        active_opacity = 1,
        inactive_opacity = 1,
        shadow = {
            enabled = true,
            range = 14,
            render_power = 3,
            color = "rgba(090d12b0)",
        },
        blur = {
            enabled = false,
        },
    },
    animations = {
        enabled = false,
    },
    master = {
        orientation = "center",
        slave_count_for_center_master = 0,
        center_master_fallback = "left",
        mfact = 0.5,
        new_status = "slave",
        new_on_active = "after",
        smart_resizing = true,
    },
    input = {
        kb_layout = "us",
        repeat_delay = 300,
        repeat_rate = 90,
        numlock_by_default = true,
        follow_mouse = 1,
        sensitivity = 0,
        accel_profile = "flat",
        touchpad = {
            natural_scroll = false,
            tap_to_click = true,
            disable_while_typing = true,
        },
    },
    cursor = {
        no_warps = false,
        inactive_timeout = 5,
    },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
        focus_on_activate = true,
    },
    xwayland = {
        force_zero_scaling = true,
    },
})

for _, workspace in ipairs(workspaces) do
    hl.workspace_rule({
        workspace = tostring(workspace.id),
        default_name = workspace.name,
        persistent = true,
    })
end

hl.workspace_rule({
    workspace = "special:rmpc",
    on_created_empty = "foot --app-id scratch_rmpc -e rmpc",
})

hl.workspace_rule({
    workspace = "special:btop",
    on_created_empty = "foot --app-id scratch_btop -e btop",
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

hl.on("hyprland.start", function()
    hl.exec_cmd(app_shell("~/.config/scripts/hypr-autostart"))
end)

hl.bind(mod .. " + RETURN", hl.dsp.exec_cmd(app("foot")))
hl.bind(mod .. " + SPACE", hl.dsp.exec_cmd(app("hyprlauncher")))
hl.bind(mod .. " + P", hl.dsp.exec_cmd(app("wlogout")))
hl.bind(mod .. " + ALT + L", hl.dsp.exec_cmd(app("hyprlock")), { locked = true })
hl.bind(mod .. " + E", hl.dsp.exec_cmd(app("nautilus")))
hl.bind(mod .. " + CTRL + S", hl.dsp.workspace.toggle_special("rmpc"))
hl.bind(mod .. " + CTRL + T", hl.dsp.workspace.toggle_special("btop"))
hl.bind(mod .. " + CTRL + N", shell("swaync-client -t"))
hl.bind(mod .. " + ALT + V", shell("~/.config/scripts/cliphist-rofi"))
hl.bind(mod .. " + ALT + M", hl.dsp.exec_cmd(app_shell("~/.config/scripts/watch-media")))
hl.bind(mod .. " + SHIFT + C", hl.dsp.exec_cmd(app("hyprpicker -a")))
hl.bind(mod .. " + B", shell("pkill -SIGUSR1 waybar"))

hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + W", hl.dsp.group.toggle())
hl.bind(mod .. " + M", hl.dsp.layout("swapwithmaster master"))
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(mod .. " + C", hl.dsp.window.center())

local directions = {
    H = "l",
    J = "d",
    K = "u",
    L = "r",
}

for key, direction in pairs(directions) do
    hl.bind(mod .. " + " .. key, hl.dsp.focus({ direction = direction }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ direction = direction }))
    hl.bind(mod .. " + CTRL + " .. key, hl.dsp.focus({ monitor = direction }))
    hl.bind(mod .. " + CTRL + SHIFT + " .. key, hl.dsp.workspace.move({ monitor = direction }))
end

for workspace = 1, 9 do
    hl.bind(mod .. " + " .. workspace, hl.dsp.focus({ workspace = workspace }))
    hl.bind(mod .. " + SHIFT + " .. workspace, hl.dsp.window.move({ workspace = workspace }))
end

hl.bind(mod .. " + U", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + I", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })

hl.bind("Print", shell("hyprshot -m region -o ~/Pictures/Screenshots"))
hl.bind("CTRL + Print", shell("hyprshot -m output -m active -o ~/Pictures/Screenshots"))
hl.bind("ALT + Print", shell("hyprshot -m window -m active -o ~/Pictures/Screenshots"))

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume raise"), {
    locked = true,
    repeating = true,
})
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower"), {
    locked = true,
    repeating = true,
})
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), {
    locked = true,
})
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), {
    locked = true,
})
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("playerctl stop"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })

hl.window_rule({
    name = "browser-opacity",
    match = {
        class = "([fF]irefox|firefox-bin|org\\.mozilla\\.firefox|zen|app\\.zen_browser\\.zen|librewolf|io\\.gitlab\\.librewolf-community|com\\.brave\\.Browser|brave-browser|Brave-browser)",
    },
    opacity = "1.0 override 1.0 override",
})

hl.window_rule({
    name = "web-workspace",
    match = {
        class = "([fF]irefox|firefox-bin|org\\.mozilla\\.firefox|zen|app\\.zen_browser\\.zen|librewolf|io\\.gitlab\\.librewolf-community|com\\.brave\\.Browser|brave-browser|Brave-browser)",
    },
    workspace = "1 silent",
})

hl.window_rule({
    name = "discord-workspace",
    match = { class = "(discord|com\\.discordapp\\.Discord)" },
    workspace = "2 silent",
    opacity = "1.0 override 1.0 override",
})

hl.window_rule({
    name = "thunderbird-workspace",
    match = { class = "org\\.mozilla\\.Thunderbird" },
    workspace = "2 silent",
})

hl.window_rule({
    name = "steam-workspace",
    match = { class = "steam" },
    workspace = "3 silent",
})

hl.window_rule({
    name = "steam-friends-workspace",
    match = { title = "Friends List" },
    workspace = "3 silent",
    float = true,
    size = "600 700",
    center = true,
})

hl.window_rule({
    name = "nicotine-workspace",
    match = { class = "org\\.nicotine_plus\\.Nicotine" },
    workspace = "4 silent",
})

hl.window_rule({
    name = "pika-workspace",
    match = { class = "org\\.gnome\\.World\\.PikaBackup" },
    workspace = "5 silent",
})

hl.window_rule({
    name = "scratch-terminals",
    match = { class = "(scratch_rmpc|scratch_btop)" },
    float = true,
    size = "1920 1080",
    center = true,
})

hl.window_rule({
    name = "media-opacity",
    match = { class = "(mpv|steam_app_.*|bg3)" },
    opacity = "1.0 override 1.0 override",
})

hl.window_rule({
    name = "mpv-capture",
    match = { class = "(mpv|io\\.mpv\\.Mpv)" },
    opacity = "1.0 override 1.0 override",
    border_size = 0,
    rounding = 0,
    decorate = false,
    no_shadow = true,
})

hl.window_rule({
    name = "picture-in-picture",
    match = { title = "Picture-in-Picture" },
    float = true,
    pin = true,
    size = "960 540",
    move = "100%-980 40",
})

hl.window_rule({
    name = "nautilus",
    match = { class = "(org\\.gnome\\.Nautilus|nautilus)" },
    float = true,
    size = "1400 900",
    center = true,
})

hl.window_rule({
    name = "trayscale",
    match = { class = "dev\\.deedles\\.Trayscale" },
    workspace = "5 silent",
    float = true,
    size = "520 620",
    center = true,
})

hl.window_rule({
    name = "pavucontrol",
    match = { class = "org\\.pulseaudio\\.pavucontrol" },
    float = true,
    size = "900 650",
    center = true,
})

hl.window_rule({
    name = "dialogs",
    match = { modal = true },
    float = true,
    center = true,
})

hl.window_rule({
    name = "fix-xwayland-drag",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})
