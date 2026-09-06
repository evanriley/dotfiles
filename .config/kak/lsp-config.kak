# Language server configuration. Sourced from kakrc only when kak-lsp is on
# PATH, so nothing here needs its own guard.
#
# kakoune-lsp ships an 'lsp-filetype-*' hook per language with a working default
# server, so only the two places where the nvim config disagreed are overridden.
# The hooks for servers that are not installed here (rust-analyzer, lua-ls,
# clojure-lsp) are left alone: they cost nothing until the server exists, and
# removing them would mean editing this file again after an apk add.

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

# nvim set zls.enable_build_on_save. zls reads its configuration from the "zls"
# section, so that is both the settings sub-table and the section name sent at
# initialization. build.zig.zon is a root marker as well because a package
# without a build script still has one.
hook -group lsp-filetype-zig-settings global BufSetOption filetype=zig %{
    set-option buffer lsp_servers %{
        [zls]
        root_globs = ["build.zig", "build.zig.zon", ".git"]
        settings_section = "zls"
        [zls.settings.zls]
        enable_build_on_save = true
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
declare-option -docstring 'filetypes whose buffers are formatted by the language server on write' \
    str lsp_format_on_save_filetypes 'c|cpp|objc|ocaml|python|zig'

# ocamllsp answers a formatting request by shelling out to ocamlformat, which
# refuses to run unless the project root holds a .ocamlformat file. A project
# without one gets an error in the status line and an otherwise normal write.

hook global WinSetOption "filetype=(%opt{lsp_format_on_save_filetypes})" %{
    hook window -group lsp-format-on-save BufWritePre .* lsp-formatting-sync
    hook -once -always window WinSetOption filetype=.* %{
        remove-hooks window lsp-format-on-save
    }
}

# nvim's LspAttach mappings. 'gd' is already bound to lsp-definition by
# kakoune-lsp's own 'goto' mode mapping, so only the leader pair is added here.
map global user f ': lsp-formatting<ret>' -docstring 'format buffer'
map global user e ': lsp-hover<ret>' -docstring 'show diagnostics for cursor'
map global user l ': enter-user-mode lsp<ret>' -docstring 'lsp…'
