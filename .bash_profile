# /etc/skel/.bash_profile

# This file is sourced by bash for login shells.  The following line
# runs your .bashrc and is recommended by the bash info pages.
if [[ -f ~/.bashrc ]] ; then
	. ~/.bashrc
fi

export LIBVA_DRIVER_NAME=radeonsi
export VDPAU_DRIVER=radeonsi

export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=Hyprland
export XDG_SESSION_DESKTOP=Hyprland

export QT_QPA_PLATFORM="wayland;xcb"
export GDK_BACKEND=wayland,x11
export CLUTTER_BACKEND=wayland

alias hypr="dbus-run-session Hyprland"
