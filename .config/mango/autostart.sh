#!/usr/bin/env bash

set +e

# screen sharing
dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=wlroots >/dev/null 2>&1

# notifications
swaync -c ~/.config/swaync/config.jsonc -s ~/.config/swaync/style.css >/dev/null 2>&1 &

# night light
wlsunset -l 35.9 -L -78.8 >/dev/null 2>&1 &

# wallpaper
swaybg -i ~/Pictures/wallpapers/portal-wide.png -m "center" -c "#282828" >/dev/null 2>&1 &

# waybar
waybar -c ~/.config/waybar/config.jsonc -s ~/.config/waybar/style.css >/dev/null 2>&1 &
# hide waybar after starting it
sleep 0.5
pkill -SIGUSR1 waybar

# keep clipboard content
wl-clip-persist --clipboard regular --reconnect-tries 0 >/dev/null 2>&1 &

# clipboard content manager
wl-paste --type text --watch cliphist store >/dev/null 2>&1 &

# bluetooth
blueman-applet >/dev/null 2>&1 &

# Permission authentication
/usr/lib/xfce-polkit/xfce-polkit >/dev/null 2>&1 &

# volume control
swayosd-server >/dev/null 2>&1 &

# swayidle
swayidle -w \
    timeout 600 'hyprlock --grace 10' \
    timeout 1200 'systemctl suspend' \
    before-sleep 'hyprlock' &

# autostart some programs
firefox &
discord &
steam &
thunderbird &
vorta &
nicotine &
