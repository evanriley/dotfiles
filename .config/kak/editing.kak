# Lisp structural editing. Auto-pairs stays available in other buffers.
require-module parinfer
declare-option -hidden str parinfer_saved_auto_close

define-command parinfer-on %{
    evaluate-commands %sh{
        [ -x "$kak_opt_parinfer_path" ] && exit 0
        printf "fail 'Install parinfer-rust with ./install-plugins first.'\n"
    }
    evaluate-commands %sh{
        [ "$kak_opt_parinfer_enabled" = true ] && exit 0
        printf 'set-option window parinfer_saved_auto_close %%opt{auto_close_trigger}\n'
    }
    set-option window auto_close_trigger '<a-k>(?!)<ret>'
    remove-hooks window parinfer
    remove-hooks window parinfer-try-paren
    parinfer-enable-window -smart
}
define-command parinfer-off %{
    parinfer-disable-window
    evaluate-commands %sh{
        [ -n "$kak_opt_parinfer_saved_auto_close" ] || exit 0
        printf 'set-option window auto_close_trigger %%opt{parinfer_saved_auto_close}\n'
    }
}
define-command parinfer-toggle %{
    evaluate-commands %sh{
        if [ "$kak_opt_parinfer_enabled" = true ]; then printf 'parinfer-off\n'; else printf 'parinfer-on\n'; fi
    }
}

hook global WinSetOption filetype=(clojure|lisp) %{
    parinfer-on
    # Undo should restore exactly what was undone. Re-enable with <space>v p.
    map window normal u ': parinfer-off<ret>u'
    map window normal U ': parinfer-off<ret>U'
    hook -once -always window WinSetOption filetype=.* %{
        parinfer-off
        unmap window normal u
        unmap window normal U
    }
}

# Use existing theme faces so both darkman palettes remain consistent.
set-option global rainbow_colors MatchingChar type string function keyword module
hook global WinSetOption filetype=(clojure|lisp) %{
    rainbow-enable-window
    hook -once -always window WinSetOption filetype=.* %{ try rainbow-disable-window }
}

declare-user-mode display-options
map global user v ': enter-user-mode display-options<ret>' -docstring 'display and editing toggles…'
map global display-options p ': parinfer-toggle<ret>' -docstring 'toggle Parinfer'
map global display-options r ': rainbow-enable-window<ret>' -docstring 'enable rainbow delimiters'
map global display-options R ': rainbow-disable-window<ret>' -docstring 'disable rainbow delimiters'
