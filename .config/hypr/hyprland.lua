local mod = "SUPER"

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
        layout = "dwindle",
        gaps_in = 6,
        gaps_out = 8,
        border_size = 2,
        resize_on_border = true,
        allow_tearing = false,
        col = {
            active_border = {
                colors = { "rgb(c4b28a)", "rgb(c4746e)" },
                angle = 45,
            },
            inactive_border = "rgb(090d12)",
        },
    },
    decoration = {
        rounding = 6,
        rounding_power = 2,
        active_opacity = 0.97,
        inactive_opacity = 0.94,
        shadow = {
            enabled = true,
            range = 14,
            render_power = 3,
            color = "rgba(090d12b0)",
        },
        blur = {
            enabled = true,
            size = 6,
            passes = 2,
            vibrancy = 0.12,
        },
    },
    animations = {
        enabled = true,
    },
    dwindle = {
        preserve_split = true,
        smart_split = true,
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

hl.curve("kansoOut", {
    type = "bezier",
    points = { { 0.16, 1 }, { 0.3, 1 } },
})
hl.curve("kansoLinear", {
    type = "bezier",
    points = { { 0, 0 }, { 1, 1 } },
})
hl.curve("kansoSpring", {
    type = "spring",
    mass = 1,
    stiffness = 190,
    dampening = 24,
})

hl.animation({ leaf = "global", enabled = true, speed = 9, bezier = "kansoOut" })
hl.animation({ leaf = "windows", enabled = true, speed = 5, spring = "kansoSpring" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, spring = "kansoSpring", style = "popin 92%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "kansoLinear", style = "popin 94%" })
hl.animation({ leaf = "fade", enabled = true, speed = 5, bezier = "kansoOut" })
hl.animation({ leaf = "border", enabled = true, speed = 7, bezier = "kansoOut" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, spring = "kansoSpring", style = "slidefade 12%" })
hl.animation({ leaf = "layers", enabled = true, speed = 5, bezier = "kansoOut", style = "fade" })

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd(
        "systemctl --user start "
            .. "hyprpolkitagent.service "
            .. "cliphist-store.service "
            .. "e-os-appearance.service "
            .. "mpd.service "
            .. "mpd-mpris.service "
            .. "listenbrainz-mpd.service "
            .. "mpd-discord-rpc.service "
            .. "swayosd.service"
    )
    hl.exec_cmd(app("hypridle"))
    hl.exec_cmd(app("hyprpaper"))
    hl.exec_cmd(app_shell("~/.config/scripts/hypr-waybar"))
    hl.exec_cmd(app("swaync"))
    hl.exec_cmd(app("firefox"))
    hl.exec_cmd(app("flatpak run dev.deedles.Trayscale"))
    hl.exec_cmd(app("flatpak run com.discordapp.Discord --start-minimized"))
    hl.exec_cmd(app("steam -silent"))
end)

hl.bind(mod .. " + RETURN", hl.dsp.exec_cmd(app("foot")))
hl.bind(mod .. " + SPACE", hl.dsp.exec_cmd(app("hyprlauncher")))
hl.bind(mod .. " + P", hl.dsp.exec_cmd(app("wlogout")))
hl.bind(mod .. " + ALT + L", hl.dsp.exec_cmd(app("hyprlock")), { locked = true })
hl.bind(mod .. " + E", hl.dsp.exec_cmd(app("nautilus")))
hl.bind(mod .. " + CTRL + S", shell("~/.config/scripts/hypr-scratch rmpc"))
hl.bind(mod .. " + CTRL + T", shell("~/.config/scripts/hypr-scratch btop"))
hl.bind(mod .. " + CTRL + N", shell("swaync-client -t"))
hl.bind(mod .. " + ALT + V", shell("~/.config/scripts/cliphist-rofi"))
hl.bind(mod .. " + ALT + M", shell("~/.config/scripts/watch-media"))
hl.bind(mod .. " + SHIFT + C", hl.dsp.exec_cmd(app("hyprpicker -a")))
hl.bind(mod .. " + B", shell("pkill -SIGUSR1 waybar"))

hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + W", hl.dsp.group.toggle())
hl.bind(mod .. " + F", shell("hyprctl dispatch fullscreen 1"))
hl.bind(mod .. " + SHIFT + F", shell("hyprctl dispatch fullscreen 0"))
hl.bind(mod .. " + C", shell("hyprctl dispatch centerwindow"))

local directions = {
    H = "left",
    J = "down",
    K = "up",
    L = "right",
}

for key, direction in pairs(directions) do
    hl.bind(mod .. " + " .. key, hl.dsp.focus({ direction = direction }))
    hl.bind(mod .. " + SHIFT + " .. key, shell("hyprctl dispatch movewindow " .. direction))
    hl.bind(mod .. " + CTRL + " .. key, shell("hyprctl dispatch focusmonitor " .. direction))
    hl.bind(mod .. " + CTRL + SHIFT + " .. key, shell("hyprctl dispatch movecurrentworkspacetomonitor " .. direction))
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
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

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
    name = "media-opacity",
    match = { class = "(mpv|steam_app_.*|bg3)" },
    opacity = "1.0 override 1.0 override",
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
