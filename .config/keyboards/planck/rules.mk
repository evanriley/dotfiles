# Disabled qmk features
BOOTMAGIC_ENABLE = no
CONSOLE_ENABLE = no

# Disable shift combinations which has issues when used with shift-parens
COMMAND_ENABLE = no
COMBO_ENABLE = no
AUDIO_ENABLE = no
RGBLIGHT_ENABLE = no
LEADER_ENABLE = no
MIDI_ENABLE = no
UNICODE_ENABLE = no
BLUETOOTH_ENABLE = no

# Enabled qmk features
EXTRAKEY_ENABLE = yes
NKRO_ENABLE = yes
BACKLIGHT_ENABLE = yes
MOUSEKEY_ENABLE = yes

# Decrease binary size using LTO
LTO_ENABLE = yes

