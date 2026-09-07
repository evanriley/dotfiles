# nREPL evaluation uses a FIFO buffer, so long evaluations don't block editing.
# rep_namespace is an optional manual override; otherwise infer the (ns …) form.
declare-option -hidden str rep_detected_namespace

define-command -hidden nrepl-detect-namespace %{
    set-option window rep_detected_namespace user
    evaluate-commands -draft %{
        execute-keys '%'
        evaluate-commands %sh{
            python3 - <<'PY'
import os, re
text = os.environ['kak_selection']
match = re.search(r'^\s*\(ns\s+(?:\^[^\s]+\s+)?([^\s()\[\]{}]+)', text, re.M)
if match:
    print("set-option window rep_detected_namespace '" + match[1].replace("'", "''") + "'")
PY
        }
    }
}

define-command nrepl-evaluate-selection %{
    project-update-root
    nrepl-detect-namespace
    evaluate-commands %sh{
        python3 - "$kak_opt_config_support" "$kak_opt_rep_command" "$kak_opt_project_root" "$kak_buffile" "${kak_opt_rep_namespace:-$kak_opt_rep_detected_namespace}" <<'PY'
import os, shlex, sys
args = ['python3', *sys.argv[1:2], 'rep', *sys.argv[2:]]
args += [os.environ['kak_selections_desc']]
args += shlex.split(os.environ['kak_quoted_selections'])
def q(s): return "'" + s.replace("'", "''") + "'"
print('evaluate-commands -draft %{ fifo -name *rep* -- ' + ' '.join(map(q, args)) + ' }')
print("echo 'Evaluation output: <space>r o'")
PY
    }
}

define-command nrepl-evaluate-file %{
    evaluate-commands -draft %{
        execute-keys '%'
        set-option local rep_namespace user
        nrepl-evaluate-selection
    }
}
define-command nrepl-evaluate-form %{
    evaluate-commands -draft %{
        execute-keys '<a-a>('
        nrepl-evaluate-selection
    }
}

# Babashka offers an nREPL without Java. Use :bb-repl in a bb.edn project.
define-command bb-repl %{
    project-run terminal repl python3 %opt{config_support} bb-server %sh{ printf '%s/.local/bin/bb' "$HOME" }
}

define-command tmux-repl-menu %{
    evaluate-commands %sh{
        if [ -z "$TMUX" ]; then printf "fail 'Open Kakoune inside tmux to use this REPL mode.'\n"; fi
    }
    require-module tmux
    require-module repl-mode
    repl-mode-register-default-mappings
    project-update-root
    set-option window repl_mode_new_repl_command %sh{
        python3 - <<'PY'
import os, shlex
command = shlex.split(os.environ['kak_quoted_opt_repl_command'])
root = os.environ['kak_opt_project_root']
script = 'cd ' + shlex.quote(root) + ' && exec ' + shlex.join(command or ['sh'])
def q(s): return "'" + s.replace("'", "''") + "'"
print('sh -c ' + q(script))
PY
    }
    enter-user-mode repl
}

declare-user-mode nrepl
map global user r ': enter-user-mode nrepl<ret>' -docstring 'REPL…'
map global nrepl u ': project-repl<ret>' -docstring 'start project REPL'
map global nrepl b ': bb-repl<ret>' -docstring 'start Babashka nREPL'
map global nrepl e ': nrepl-evaluate-selection<ret>' -docstring 'evaluate selections'
map global nrepl a ': nrepl-evaluate-form<ret>' -docstring 'evaluate enclosing form'
map global nrepl f ': nrepl-evaluate-file<ret>' -docstring 'evaluate buffer'
map global nrepl o ': buffer *rep*<ret>' -docstring 'evaluation output'
map global nrepl n ': prompt namespace: %{ set-option buffer rep_namespace %val{text} }<ret>' -docstring 'override evaluation namespace'
map global nrepl t ': tmux-repl-menu<ret>' -docstring 'tmux REPL mode…'
