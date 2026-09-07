# Project roots are shared by pickers, builds and REPL commands.
declare-option str-list project_root_files 'build.zig' 'build.zig.zon' 'dune-project' 'dune-workspace' '*.opam' 'deps.edn' 'bb.edn' 'project.clj' '.git' '.hg'
declare-option str project_root

declare-option str-list build_command
declare-option str-list test_command
declare-option str-list run_command
declare-option str-list repl_command
declare-option str-list watch_command
declare-option str-list test_file_command

define-command project-update-root %{
    set-option window project_root %sh{
        # Kakoune exports values referenced literally in this block.
        : "$kak_buffile" "$kak_quoted_opt_project_root_files"
        python3 "$kak_opt_config_support" root
    }
}

# Buffer scope keeps settings with the file. Clear every verb on re-detection.
hook global BufSetOption filetype=.* %{
    unset-option buffer indentwidth
    unset-option buffer tabstop
    unset-option buffer project_root_files
    set-option buffer build_command
    set-option buffer test_command
    set-option buffer run_command
    set-option buffer repl_command
    set-option buffer watch_command
    set-option buffer test_file_command
}

hook global BufSetOption filetype=zig %{
    set-option buffer tabstop 4
    set-option buffer indentwidth 4
    set-option buffer build_command %opt{zig_command} build
    set-option buffer test_command %opt{zig_command} build test
    set-option buffer run_command %opt{zig_command} build run
    set-option buffer test_file_command %opt{zig_command} test
}

hook global BufSetOption filetype=(ocaml|opam) %{
    evaluate-commands %sh{
        prefix=''
        command -v opam >/dev/null 2>&1 && prefix='opam exec --'
        printf '%s\n' \
            "set-option buffer build_command $prefix dune build" \
            "set-option buffer test_command $prefix dune runtest" \
            "set-option buffer watch_command $prefix dune build --watch" \
            "set-option buffer repl_command $prefix dune utop"
    }
}

# Dune files retain Lisp highlighting but get the same project commands.
hook global BufSetOption filetype=lisp %{
    evaluate-commands %sh{
        case "${kak_buffile##*/}" in dune|dune-project|dune-workspace) ;; *) exit 0;; esac
        prefix=''
        command -v opam >/dev/null 2>&1 && prefix='opam exec --'
        printf '%s\n' \
            "set-option buffer build_command $prefix dune build" \
            "set-option buffer test_command $prefix dune runtest" \
            "set-option buffer watch_command $prefix dune build --watch" \
            "set-option buffer repl_command $prefix dune utop"
    }
}

# deps.edn aliases and bb tasks are project-owned. Configure build/test/run
# explicitly instead of assuming that every checkout has a :test alias.
hook global BufSetOption filetype=clojure %{
    evaluate-commands %sh{
        : "$kak_buffile" "$kak_quoted_opt_project_root_files"
        root=$(python3 "$kak_opt_config_support" root)
        python3 - "$root" "$kak_opt_config_support" <<'PYCODE'
from pathlib import Path
import sys
root = Path(sys.argv[1])
bin_dir = Path.home() / '.local/bin'
if (root/'bb.edn').exists() and not (root/'deps.edn').exists():
    command = ['python3', sys.argv[2], 'bb-server', str(bin_dir/'bb')]
elif (root/'project.clj').exists() and not (root/'deps.edn').exists():
    command = ['lein', 'repl']
else:
    command = [str(bin_dir/'clojure'), '-Sdeps', '{:deps {nrepl/nrepl {:mvn/version "1.7.0"}}}', '-M', '-m', 'nrepl.cmdline', '--interactive']
def q(s): return "'" + s.replace("'", "''") + "'"
print('set-option buffer repl_command ' + ' '.join(map(q, command)))
PYCODE
    }
}

# Write modified files only within this project; scratch buffers are excluded.
define-command -hidden project-save -params 1 %{
    evaluate-commands -buffer * %{
        evaluate-commands %sh{
            [ "$kak_modified" = true ] && [ -n "$kak_buffile" ] || exit 0
            case "$kak_buffile" in "$1"/*) printf 'write\n';; esac
        }
    }
}

# Validate before saving. Build/test output goes through :make; interactive
# commands use terminals. The helper converts compiler locations to absolute
# paths, so jumping still works when Kakoune was launched outside the project.
define-command -hidden project-run -params 2.. %{
    project-update-root
    evaluate-commands %sh{
        [ $# -gt 2 ] && exit 0
        printf "fail 'No %s command configured; set-option buffer %s_command …'\n" "$2" "$2"
    }
    project-save %opt{project_root}
    evaluate-commands %sh{
        mode=$1
        shift 2
        python3 - "$mode" "$kak_opt_config_support" "$kak_opt_project_root" "$@" <<'PY'
import shlex, sys
mode, helper, root, *command = sys.argv[1:]
def q(s): return "'" + s.replace("'", "''") + "'"
if mode == 'build':
    shell = shlex.join(['python3', helper, 'build', root, *command])
    print('set-option local makecmd ' + q(shell))
    print('make')
else:
    command = ['sh', '-c', 'cd "$1" && shift && exec "$@"', '_', root, *command]
    print('run-in-terminal ' + ' '.join(map(q, command)))
PY
    }
}

define-command build %{ project-run build build %opt{build_command} }
define-command test %{ project-run build test %opt{test_command} }
define-command run %{ project-run terminal run %opt{run_command} }
define-command watch %{ project-run terminal watch %opt{watch_command} }
define-command project-repl %{ project-run terminal repl %opt{repl_command} }
# Keep the familiar :repl spelling without colliding with windowing modules.
alias global repl project-repl

define-command test-file %{
    evaluate-commands %sh{
        [ -n "$kak_opt_test_file_command" ] && [ -n "$kak_buffile" ] && exit 0
        printf "fail 'Set test_file_command for this project and use a file buffer.'\n"
    }
    project-run build test_file %opt{test_file_command} %val{buffile}
}

# Explicitly load project-owned task settings. This is never sourced on open.
define-command project-config %{
    project-update-root
    source "%opt{project_root}/.kakrc"
}
