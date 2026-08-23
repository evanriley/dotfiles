# Login shells read this file instead of .bashrc; source it so that
# interactive TTY and SSH logins get the same PATH, prompt and aliases
# as a terminal started from the desktop session.
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi
