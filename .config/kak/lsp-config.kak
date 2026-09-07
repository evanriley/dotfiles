# Keep the generated Kakscript and daemon on the same installed version.
set-option global lsp_cmd %sh{
    python3 - <<'PYCODE'
from pathlib import Path
import os, shlex, shutil
binary = Path.home() / '.local/bin/kak-lsp'
print(shlex.quote(str(binary) if os.access(binary, os.X_OK) else shutil.which('kak-lsp')))
PYCODE
}

# Language server configuration. Sourced from kakrc only when kak-lsp is on
# PATH, so nothing here needs its own guard.
#
# Override defaults where this setup needs a specific server or project root.

# A hook registered after kakoune-lsp's runs after it, and setting lsp_servers
# replaces the value rather than adding to it, so these win without having to
# remove the upstream hook groups.

# nvim enabled 'ruff' and not 'pylsp'. Taken from the commented-out block in
# kakoune-lsp's own output, minus the '-add' that would have kept pylsp too.
hook -group lsp-filetype-python-ruff global BufSetOption filetype=python %{
    set-option buffer lsp_servers %{
        [ruff]
        args = ["server", "--quiet"]
        root_globs = ["requirements.txt", "setup.py", "pyproject.toml", ".git", ".hg"]
        settings_section = "_"
        [ruff.settings._.globalSettings]
        organizeImports = true
        fixAll = true
    }
}

# Use the same Zig executable as builds, including desktop launches.
hook -group lsp-filetype-zig-settings global BufSetOption filetype=zig %{
    set-option buffer lsp_servers %sh{
        : "$kak_opt_zig_command"
        python3 "$kak_opt_config_support" zls
    }
}

hook -group lsp-filetype-clojure-project global BufSetOption filetype=clojure %{
    set-option buffer lsp_servers %sh{
        python3 - <<'PYCODE'
import json, os
from pathlib import Path
binary = Path.home() / '.local/bin/clojure-lsp'
print('[clojure-lsp]')
print('command = "env"')
path = str(Path.home() / '.local/bin') + ':' + os.environ['PATH']
print('args = ' + json.dumps(['PATH=' + path, str(binary) if os.access(binary, os.X_OK) else 'clojure-lsp']))
print('root_globs = ["deps.edn", "bb.edn", "project.clj", ".git", ".hg"]')
PYCODE
    }
}

# ocamllsp lives in an opam switch, whose bin directory joins PATH only for a
# shell that has evaluated 'opam env'; kakoune-lsp spawns the server from
# Kakoune's own environment, which under a niri spawn-at-startup entry has not.
# 'opam exec' resolves the switch at spawn time, project-local switches
# included. The value is computed once rather than per buffer, and degrades to a
# bare 'ocamllsp' so that a distribution-packaged server still works.
declare-option -docstring 'lsp_servers value used for OCaml buffers' \
    str ocaml_lsp_servers %sh{
        if command -v opam >/dev/null 2>&1; then
            spawn='command = "opam"
args = ["exec", "--", "ocamllsp"]'
        else
            spawn='command = "ocamllsp"'
        fi

        # kakoune-lsp's own hook also lists "dune" and "Makefile" as root
        # markers. A dune project has a 'dune' file in every directory that
        # builds anything, so the first match walking upwards is the buffer's
        # own directory and the server is rooted at a subdirectory of the
        # project. Only the markers that appear once, at the top, are kept.
        cat <<EOF
[ocamllsp]
$spawn
root_globs = ["dune-workspace", "dune-project", "*.opam", "esy.json", ".git", ".hg"]
EOF
    }

hook -group lsp-filetype-ocaml-opam global BufSetOption filetype=ocaml %{
    set-option buffer lsp_servers %opt{ocaml_lsp_servers}
}

lsp-enable

# nvim: diagnostic.config virtual_text. lsp-enable already turns on the
# underline (inline diagnostics) and the gutter flags; this adds the message
# text at the end of the line, which is the part virtual_text contributed.
lsp-inlay-diagnostics-enable global

# nvim formatted on BufWritePre through the LSP client. The filetype list is
# explicit rather than '.*' because a blocking format request against a server
# that is not installed stalls the write until it times out.
declare-option -docstring 'filetypes formatted on write (native tools for Zig, OCaml and Clojure)' \
    str lsp_format_on_save_filetypes 'c|cpp|objc|ocaml|python|zig|clojure'

# ocamllsp answers a formatting request by shelling out to ocamlformat, which
# refuses to run unless the project root holds a .ocamlformat file. A project
# without one gets an error in the status line and an otherwise normal write.

hook global WinSetOption "filetype=(%opt{lsp_format_on_save_filetypes})" %{
    hook window -group lsp-format-on-save BufWritePre .* code-format-sync
    hook -once -always window WinSetOption filetype=.* %{
        remove-hooks window lsp-format-on-save
    }
}

# nvim's LspAttach mappings. 'gd' is already bound to lsp-definition by
# kakoune-lsp's own 'goto' mode mapping, so only the leader pair is added here.
map global user f ': code-format<ret>' -docstring 'format buffer'
map global user e ': lsp-hover<ret>' -docstring 'show diagnostics for cursor'
map global user l ': enter-user-mode lsp<ret>' -docstring 'lsp…'

# Diagnostics are visible by default; type hints are opt-in per window.
declare-option bool show_inlay_diagnostics true
declare-option bool show_type_hints false
define-command toggle-inlay-diagnostics %{
    evaluate-commands %sh{
        if [ "$kak_opt_show_inlay_diagnostics" = true ]; then
            printf 'lsp-inlay-diagnostics-disable global
set-option global show_inlay_diagnostics false
'
        else
            printf 'lsp-inlay-diagnostics-enable global
set-option global show_inlay_diagnostics true
'
        fi
    }
}
define-command toggle-type-hints %{
    evaluate-commands %sh{
        if [ "$kak_opt_show_type_hints" = true ]; then
            printf 'lsp-inlay-hints-disable window
set-option window show_type_hints false
'
        else
            printf 'lsp-inlay-hints-enable window
set-option window show_type_hints true
'
        fi
    }
}
map global display-options d ': toggle-inlay-diagnostics<ret>' -docstring 'toggle diagnostic messages'
map global display-options i ': toggle-type-hints<ret>' -docstring 'toggle type hints'
map global code A ': lsp-code-actions<ret>' -docstring 'code actions'
map global code s ': lsp-selection-range<ret>' -docstring 'expand syntax selection'
map global code R ': lsp-rename-prompt<ret>' -docstring 'rename symbol'
map global code S ': lsp-goto-document-symbol<ret>' -docstring 'document symbols'
map global code D ': lsp-diagnostics<ret>' -docstring 'project diagnostics'


# Whole-buffer filters avoid Kakoune 2026.04's last-line change behavior,
# which can join lines when applying an LSP formatting edit at EOF.
define-command -hidden native-format %{
    evaluate-commands -draft -save-regs '/|"' %{
        execute-keys '%|python3 "$kak_opt_config_support" format "$kak_buffile" "$kak_opt_filetype" "$kak_opt_zig_command"<ret>'
    }
}
define-command code-format-sync %{
    evaluate-commands %sh{
        case "$kak_opt_filetype" in
            zig|ocaml|clojure) printf 'native-format\n';;
            *) printf 'lsp-formatting-sync\n';;
        esac
    }
}
define-command code-format %{
    evaluate-commands %sh{
        case "$kak_opt_filetype" in
            zig|ocaml|clojure) printf 'native-format\n';;
            *) printf 'lsp-formatting\n';;
        esac
    }
}
