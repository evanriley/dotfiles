# Clojure evaluation over the persistent nREPL daemon that lives in support.py.
#
# The daemon owns the connection, the session and the log; this file owns
# selection, dispatch and presentation. Asynchronous results come back through
# nrepl-handle-result, whose eight-argument contract is documented at the head
# of support.py's nREPL section. Arguments 6-8 anchor the form that was
# evaluated, which is what puts the value back beside it as virtual text.
#
# Evaluation that only reports goes down the asynchronous path so a slow form
# never blocks editing. Evaluation that edits the buffer -- replace and the
# comment verbs -- has to have the value in hand before it can write anything,
# so it takes the daemon's synchronous op instead.

declare-option -hidden str nrepl_namespace
declare-option -hidden str nrepl_detected_namespace user
declare-option -hidden str nrepl_cursor
declare-option -hidden str nrepl_selection_command
declare-option -hidden str nrepl_result
declare-option -hidden str nrepl_log_path
declare-option -hidden str nrepl_log_relay_pid
# One retry slot, not a table: the fallback exists to rescue a namespace that
# was never loaded, which is a first-evaluation mistake, not a steady state.
declare-option -hidden str nrepl_retry_id
declare-option -hidden str nrepl_retry_command

# A runaway form used to hold the editor for the daemon's ten-minute request
# timeout. Ten seconds is long enough for a cold namespace load over a warm
# connection and short enough that an accidental infinite loop is a pause rather
# than a lockout; it is an option because a slow project may need more.
declare-option -docstring 'seconds a buffer-editing evaluation may block the editor' \
    int nrepl_sync_timeout 10

# Every user-facing message lands here as well as on the status line, so a
# modeline can show the last nREPL answer and a test can read it back.
declare-option -docstring 'the most recent nREPL message' \
    str nrepl_report 'nrepl: nothing evaluated yet'
declare-option -hidden str nrepl_status_detail 'nrepl: status not checked yet'

# ── Namespace ────────────────────────────────────────────────────────────────

define-command -hidden nrepl-detect-namespace %{
    set-option window nrepl_detected_namespace user
    evaluate-commands -draft %{
        execute-keys '%'
        evaluate-commands %sh{
            python3 - <<'PY'
import os, re
text = os.environ['kak_selection']
match = re.search(r'^\s*\(ns\s+(?:\^[^\s]+\s+)?([^\s()\[\]{}]+)', text, re.M)
if match:
    print("set-option window nrepl_detected_namespace '" + match[1].replace("'", "''") + "'")
PY
        }
    }
}

define-command nrepl-set-namespace -docstring 'override the namespace evaluations run in' %{
    prompt -init %opt{nrepl_namespace} 'namespace: ' %{
        set-option buffer nrepl_namespace %val{text}
    }
}

# ── Selection ────────────────────────────────────────────────────────────────

# The scanner in support.py knows Clojure lexical syntax; Kakoune's `(` object
# does not, and cannot reach a top-level vector or map literal at all. The
# result is routed through an option because the buffer text is only readable
# from a draft context, where a select would be thrown away.
define-command -hidden -params 1 nrepl-select %{
    set-option window nrepl_selection_command "fail 'nrepl: nothing selected'"
    evaluate-commands -draft %{
        set-option window nrepl_cursor "%val{cursor_line} %val{cursor_column}"
        execute-keys '%'
        evaluate-commands %sh{
            python3 - "$kak_opt_config_support" "$1" "$kak_opt_nrepl_cursor" <<'PY'
import os, subprocess, sys
support, kind, cursor = sys.argv[1:4]
line, column = cursor.split()
def q(text): return "'" + str(text).replace("'", "''") + "'"
result = subprocess.run(['python3', support, 'clojure-form', kind, line, column],
                        input=os.environ['kak_selection'], capture_output=True, text=True)
command = result.stdout.strip() or 'fail ' + q('nrepl: ' + (result.stderr.strip() or 'no form found'))
print('set-option window nrepl_selection_command ' + q(command))
PY
        }
    }
    evaluate-commands %opt{nrepl_selection_command}
}

# ── Inline results ───────────────────────────────────────────────────────────
#
# Kakoune has no virtual text. kakoune-lsp fakes it for inlay hints with a
# replace-ranges highlighter over empty ranges, and this does the same under its
# own option, face and highlighter names, so toggling either leaves the other
# alone.
#
# The range-specs timestamp cannot be relied on to say when an anchor was
# measured. Kakoune moves a non-empty range as the buffer changes, but an empty
# one it leaves exactly where it is -- while still stamping the option with the
# new timestamp. An anchor that outlived an edit therefore looks current and
# points at the wrong form. So the timestamp the buffer had when the evaluation
# was dispatched is recorded separately, a result whose buffer has moved on
# since is dropped rather than drawn in the wrong place, and any edit clears
# what is on screen. The log buffer is the complete record either way.

declare-option -docstring 'show nREPL evaluation results beside the form' \
    bool show_eval_results true
declare-option -docstring 'widest inline evaluation result, in columns' \
    int nrepl_result_width 80
declare-option -hidden range-specs nrepl_eval_results
# The anchors are kept apart from the range-specs option because Kakoune owns
# that option's timestamp and this file owns the anchors.
declare-option -hidden str-list nrepl_eval_specs
declare-option -hidden int nrepl_eval_timestamp -1
declare-option -hidden int nrepl_eval_sent_timestamp -1
declare-option -hidden int nrepl_eval_elapsed

# Aliases rather than colours, so a colorscheme that has never heard of these
# faces still themes them, and one that has can override them by name.
set-face global InlayEvalResult comment
set-face global InlayEvalError Error

define-command -hidden nrepl-nop-with-0 nop

define-command -hidden nrepl-clear-results %{
    set-option buffer nrepl_eval_specs
    set-option buffer nrepl_eval_results %val{timestamp}
    set-option buffer nrepl_eval_timestamp %val{timestamp}
}

# Kakscript cannot compare two numbers, so the difference stands in for the
# comparison: subtracting the recorded timestamp leaves zero only while the
# buffer is untouched, and nrepl-nop-with-0 is the only command of that shape
# that exists. The idiom is kakoune-lsp's lsp-if-changed-since.
define-command -hidden nrepl-clear-results-if-edited %{
    set-option buffer nrepl_eval_elapsed %val{timestamp}
    set-option -remove buffer nrepl_eval_elapsed %opt{nrepl_eval_timestamp}
    try %{
        evaluate-commands "nrepl-nop-with-%opt{nrepl_eval_elapsed}"
    } catch %{
        nrepl-clear-results
    }
}

# Armed at dispatch, not at delivery: the previous evaluation's results go now,
# and the timestamp recorded here is what a returning result is checked against.
define-command -hidden nrepl-arm-results %{
    nrepl-clear-results
    set-option buffer nrepl_eval_sent_timestamp %val{timestamp}
}

# 1 buffile, 2 line, 3 ok|error, 4 text. The buffer is addressed by name because
# a result routinely arrives for a buffer that is not the one on screen.
define-command -hidden -params 4 nrepl-render-result %{
    try %{
        evaluate-commands -buffer %arg{1} %{
            nrepl-clear-results-if-edited
            evaluate-commands -draft %{
                # `x` covers the whole line including its newline, so the end of
                # the selection is the column the virtual text anchors at, and
                # an empty line answers with its own first column.
                execute-keys "%arg{2}g" 'x'
                evaluate-commands %sh{
                    python3 - "$2" "$3" "$4" <<'PYCODE'
import os, shlex, sys
line, kind, text = sys.argv[1:4]
BRACE, CLOSE, BACKSLASH = chr(123), chr(125), chr(92)
def q(value): return "'" + str(value).replace("'", "''") + "'"
timestamp = os.environ['kak_timestamp']
# An edit between dispatch and delivery moves the form, and the anchor measured
# here would point at whatever took its place.
if timestamp != os.environ['kak_opt_nrepl_eval_sent_timestamp']:
    sys.exit(0)
end_line, _, end_column = os.environ['kak_selection_desc'].partition(',')[2].partition('.')
# A line past the end of the buffer does not fail, it clamps to the last one.
if end_line != line:
    sys.exit(0)
width = int(os.environ['kak_opt_nrepl_result_width'])
flat = ' '.join(part.strip() for part in text.split('\n')).strip() or 'nil'
overflowed = '\n' in text.strip() or len(flat) > width
body = '  ' + ('; => ' if kind == 'ok' else '; !! ') + flat[:width].rstrip()
if overflowed:
    body += ' ... (:nrepl-log-open)'
face = 'InlayEvalResult' if kind == 'ok' else 'InlayEvalError'
escaped = body.replace(BACKSLASH, BACKSLASH * 2).replace(BRACE, BACKSLASH + BRACE)
markup = BRACE + face + CLOSE + escaped
anchor = line + '.' + end_column + '+0'
# Two forms on one line share an anchor, so their values are appended rather
# than one replacing the other.
kept, spec = [], anchor + '|' + markup
for existing in shlex.split(os.environ['kak_quoted_opt_nrepl_eval_specs']):
    if existing.startswith(anchor + '|'):
        spec = existing + markup
    else:
        kept.append(existing)
specs = sorted(kept + [spec],
               key=lambda item: tuple(int(part) for part in item.split('+')[0].split('.')))
print('set-option buffer nrepl_eval_specs ' + ' '.join(map(q, specs)))
print('set-option buffer nrepl_eval_timestamp ' + timestamp)
print('set-option buffer nrepl_eval_results ' + ' '.join([timestamp] + list(map(q, specs))))
PYCODE
                }
            }
        }
    }
}

define-command -hidden nrepl-results-enable %{
    try %{ add-highlighter global/nrepl-eval-results replace-ranges nrepl_eval_results }
}

define-command -hidden nrepl-results-disable %{
    try %{ remove-highlighter global/nrepl-eval-results }
}

define-command toggle-eval-results -docstring 'toggle inline nREPL evaluation results' %{
    evaluate-commands %sh{
        if [ "$kak_opt_show_eval_results" = true ]; then
            printf 'nrepl-results-disable
set-option global show_eval_results false
'
        else
            printf 'nrepl-results-enable
set-option global show_eval_results true
'
        fi
    }
}

# Cursor movement deliberately leaves results alone -- Conjure's persist until
# they are replaced -- so nothing here reacts to a selection. InsertChar fires
# before the character lands, which is one keystroke behind; the idle hooks are
# what close that gap, and an InsertEnd hook is not used because one wedges a
# scripted `kak -ui dummy` session on exit.
hook -group nrepl-eval-results global BufSetOption filetype=clojure %{
    remove-hooks buffer nrepl-eval-results
    hook buffer -group nrepl-eval-results InsertChar .* nrepl-clear-results-if-edited
    hook buffer -group nrepl-eval-results InsertDelete .* nrepl-clear-results-if-edited
    hook buffer -group nrepl-eval-results InsertIdle .* nrepl-clear-results-if-edited
    hook buffer -group nrepl-eval-results NormalIdle .* nrepl-clear-results-if-edited
    hook buffer -group nrepl-eval-results BufReload .* nrepl-clear-results
}

nrepl-results-enable

# ── Asynchronous evaluation ──────────────────────────────────────────────────

# One request, already anchored. Kept separate from selection handling so the
# namespace fallback can replay a request whose selection is long gone.
define-command -hidden -params 5 nrepl-send-code %{
    evaluate-commands %sh{
        python3 - "$kak_opt_config_support" "$kak_session" "$kak_client" "$1" "$2" "$3" "$4" "$5" <<'PY'
import subprocess, sys
support, session, client, namespace, buffile, line, column, code = sys.argv[1:9]
def q(text): return "'" + str(text).replace("'", "''") + "'"
def report(message):
    print('set-option global nrepl_report ' + q(message))
    print('echo -- ' + q(message))
result = subprocess.run(['python3', support, 'nrepl-eval', buffile, session, client,
                         namespace, line, column, code], capture_output=True, text=True)
if result.returncode:
    print('fail ' + q('nrepl: ' + (result.stderr.strip() or 'the daemon rejected the evaluation')))
    sys.exit(0)
request = result.stdout.strip()
# Retrying in user is only a rescue for an unloaded namespace, so a request
# that already ran in user has nothing left to fall back to.
retry = '' if namespace == 'user' else 'nrepl-send-code ' + ' '.join(
    map(q, ['user', buffile, line, column, code]))
print('set-option global nrepl_retry_id ' + q(request if retry else ''))
print('set-option global nrepl_retry_command ' + q(retry))
report('nrepl: ' + request + ' sent')
PY
    }
}

define-command -hidden -params 0..1 nrepl-send-selection %{
    nrepl-detect-namespace
    nrepl-arm-results
    evaluate-commands %sh{
        python3 - "${1:-${kak_opt_nrepl_namespace:-$kak_opt_nrepl_detected_namespace}}" "$kak_buffile" <<'PY'
import os, re, shlex, sys
namespace, buffile = sys.argv[1:3]
def q(text): return "'" + str(text).replace("'", "''") + "'"
if not buffile:
    print('fail ' + q('nrepl: this buffer has no file; expected a saved Clojure file. write it first'))
    sys.exit(0)
# Selection text arrives in document order; the descriptors put the main
# selection first, so they are sorted back into agreement before pairing.
locations = sorted(os.environ['kak_selections_desc'].split(), key=lambda desc: min(
    tuple(map(int, point.split('.'))) for point in desc.split(',')))
commands = []
for code, desc in zip(shlex.split(os.environ['kak_quoted_selections']), locations):
    if not code.strip():
        continue
    line, column = min(tuple(map(int, point.split('.'))) for point in desc.split(','))
    # An (ns ...) form defines the namespace it names, so it cannot be
    # evaluated inside it.
    scope = 'user' if re.match(r'\s*\(ns\s', code) else namespace
    commands.append('nrepl-send-code ' + ' '.join(map(q, [scope, buffile, line, column, code])))
print('\n'.join(commands) or 'fail ' + q('nrepl: the selection is empty; expected code to evaluate'))
PY
    }
}

define-command -hidden -params 8 nrepl-handle-result %{
    evaluate-commands %sh{
        python3 - "$1" "$2" "$3" "$4" "$5" "$kak_opt_nrepl_retry_id" "$kak_opt_nrepl_retry_command" "$6" "$7" <<'PY'
import re, sys
request, status, namespace, values, error, retry_id, retry_command, buffile, line = sys.argv[1:10]
BRACE = chr(123)
def q(text): return "'" + str(text).replace("'", "''") + "'"
def one_line(text): return ' '.join(text.split('\n')).strip()
def report(message):
    print('set-option global nrepl_report ' + q(message))
    print('echo -- ' + q(message))

# The daemon echoes the origin back untouched, so a value can be drawn beside
# the form it came from even though the editor has moved on since.
def render(kind, text):
    if buffile and line.isdigit():
        print('nrepl-render-result ' + ' '.join(map(q, [buffile, line, kind, text])))

# A missing namespace reaches the editor two ways. Babashka names it in the
# error text; nREPL 1.7 with cider-nrepl reports the status namespace-not-found
# and no text at all, which the daemon's contract flattens to a bare error. An
# error with nothing to show is useless to the user either way, so both are
# retried once in user, and only for a request that did not already run there.
def unloaded_namespace():
    return not error.strip() or re.search(r'No namespace: \S+ found', error)

if status == 'error' and request and request == retry_id and unloaded_namespace():
    print("set-option global nrepl_retry_id ''")
    print("set-option global nrepl_retry_command ''")
    report('nrepl: namespace not loaded; retrying in user')
    print(retry_command)
    sys.exit(0)
print("set-option global nrepl_retry_id ''")
print("set-option global nrepl_retry_command ''")
if status == 'ok':
    reported = one_line(values) or 'nil'
    if '\n' in values.strip():
        reported += '  (:nrepl-log-open for the rest)'
    report((namespace or 'nrepl') + '=> ' + reported)
    render('ok', values)
elif status == 'interrupted':
    report('nrepl: interrupted')
else:
    detail = 'nrepl ' + status + ': ' + (one_line(error) or status)
    print('set-option global nrepl_report ' + q(detail))
    markup = ('Error' + chr(125)) + detail.replace(BRACE, '\\' + BRACE)
    print('echo -markup ' + q(BRACE + markup))
    render('error', error or status)
PY
    }
}

define-command nrepl-eval-selection -docstring 'evaluate the current selections' %{
    nrepl-send-selection
}

define-command nrepl-eval-form -docstring 'evaluate the innermost enclosing form' %{
    evaluate-commands -draft %{ nrepl-select form; nrepl-send-selection }
}

define-command nrepl-eval-root-form -docstring 'evaluate the outermost (root) form' %{
    evaluate-commands -draft %{ nrepl-select root; nrepl-send-selection }
}

define-command nrepl-eval-word -docstring 'evaluate the word under the cursor' %{
    evaluate-commands -draft %{ nrepl-select word; nrepl-send-selection }
}

# The buffer carries its own (ns ...) form, so it is loaded from user rather
# than from the namespace it is about to define.
define-command nrepl-eval-buffer -docstring 'evaluate the whole buffer' %{
    evaluate-commands -draft %{ execute-keys '%'; nrepl-send-selection user }
}

define-command nrepl-eval-file -docstring 'evaluate the file as it is on disk' %{
    nrepl-arm-results
    evaluate-commands %sh{
        python3 - "$kak_buffile" <<'PY'
import json, sys
buffile = sys.argv[1]
def q(text): return "'" + str(text).replace("'", "''") + "'"
if not buffile:
    print('fail ' + q('nrepl: this buffer has no file; expected a saved Clojure file. write it first'))
else:
    code = '(load-file ' + json.dumps(buffile) + ')'
    print('nrepl-send-code ' + ' '.join(map(q, ['user', buffile, '1', '1', code])))
PY
    }
}

define-command nrepl-interrupt -docstring 'interrupt the running evaluation' %{
    evaluate-commands %sh{
        python3 - "$kak_opt_config_support" "$kak_buffile" <<'PY'
import json, subprocess, sys
support, buffile = sys.argv[1:3]
def q(text): return "'" + str(text).replace("'", "''") + "'"
def announce(message):
    print('set-option global nrepl_report ' + q(message))
    print('echo -- ' + q(message))
result = subprocess.run(['python3', support, 'nrepl-interrupt', buffile],
                        capture_output=True, text=True)
if result.returncode:
    print('fail ' + q('nrepl: ' + (result.stderr.strip() or 'the interrupt failed')))
    sys.exit(0)
reply = json.loads(result.stdout or 'null') or dict()
statuses = [state for message in reply.get('messages') or []
            for state in message.get('status') or []]
targets = reply.get('interrupted') or []
# Babashka's nREPL has no interrupt op and answers unknown-op. That is a
# capability the user needs told about, not an editor error.
if 'unknown-op' in statuses:
    outcome = 'nrepl: this server has no interrupt op; stop the evaluation at the server itself'
elif not targets:
    outcome = 'nrepl: nothing is running'
else:
    outcome = 'nrepl: interrupted ' + ', '.join(targets)
announce(outcome)
PY
    }
}

# ── Synchronous evaluation, for the verbs that edit the buffer ───────────────

define-command -hidden nrepl-evaluate-selection-synchronously %{
    nrepl-detect-namespace
    evaluate-commands %sh{
        python3 - "$kak_opt_config_support" "${kak_opt_nrepl_namespace:-$kak_opt_nrepl_detected_namespace}" "$kak_buffile" "$kak_opt_nrepl_sync_timeout" <<'PY'
import json, os, re, subprocess, sys
support, namespace, buffile, timeout = sys.argv[1:5]
code = os.environ['kak_selection']
def q(text): return "'" + str(text).replace("'", "''") + "'"
if not buffile:
    print('fail ' + q('nrepl: this buffer has no file; expected a saved Clojure file. write it first'))
    sys.exit(0)
if not code.strip():
    print('fail ' + q('nrepl: the selection is empty; expected code to evaluate'))
    sys.exit(0)
line, column = min(tuple(map(int, point.split('.')))
                   for point in os.environ['kak_selection_desc'].split(','))
if re.match(r'\s*\(ns\s', code):
    namespace = 'user'

def evaluate(scope):
    result = subprocess.run(['python3', support, 'nrepl-op', buffile, 'eval', 'code=' + code,
                             'ns=' + scope, 'file=' + buffile, 'line=' + str(line),
                             'column=' + str(column), 'timeout=' + timeout],
                            capture_output=True, text=True)
    if result.returncode:
        return None, result.stderr.strip() or 'the daemon rejected the evaluation'
    messages = json.loads(result.stdout or '[]')
    statuses = [state for message in messages for state in message.get('status') or []]
    if 'eval-error' in statuses or 'error' in statuses:
        failure = ''.join(message.get('ex', '') + message.get('err', '') for message in messages)
        return None, failure.strip() or 'the evaluation failed: ' + ', '.join(statuses)
    return '\n'.join(message['value'] for message in messages if 'value' in message), None

value, failure = evaluate(namespace)
# nREPL 1.7 answers namespace-not-found; Babashka names the namespace in its
# error text. Both mean the same thing: load the buffer, or run in user.
if failure and namespace != 'user' and ('namespace-not-found' in failure
                                        or re.search(r'No namespace: \S+ found', failure)):
    value, failure = evaluate('user')
if failure:
    print('fail ' + q('nrepl: ' + ' '.join(failure.split('\n')).strip()))
else:
    print('set-option window nrepl_result ' + q(value))
PY
    }
}

define-command nrepl-eval-replace-form \
    -docstring 'evaluate the enclosing form and replace it with the result' %{
    nrepl-select form
    nrepl-evaluate-selection-synchronously
    evaluate-commands -save-regs c %{
        set-register c %opt{nrepl_result}
        execute-keys '"cR'
    }
}

# Kept in a draft so the cursor comes back to the form: the comment is written
# below it, so the form's own position is untouched by the insertion.
define-command -hidden -params 1 nrepl-eval-comment %{
    evaluate-commands -draft %{
        nrepl-select %arg{1}
        nrepl-evaluate-selection-synchronously
        evaluate-commands -save-regs c %{
            evaluate-commands %sh{
                python3 - "$kak_opt_nrepl_result" <<'PY'
import os, sys
value = sys.argv[1]
def q(text): return "'" + str(text).replace("'", "''") + "'"
column = min(int(point.split('.')[1]) for point in os.environ['kak_selection_desc'].split(','))
indent = ' ' * (column - 1)
lines = value.split('\n')
print('set-register c ' + q('\n'.join(
    indent + (';; => ' if index == 0 else ';;    ') + line
    for index, line in enumerate(lines))))
PY
            }
            execute-keys ';' 'o<esc>' '"cP'
        }
    }
}

define-command nrepl-eval-comment-form \
    -docstring 'evaluate the enclosing form and append the result as a comment' %{
    nrepl-eval-comment form
}

define-command nrepl-eval-comment-root-form \
    -docstring 'evaluate the root form and append the result as a comment' %{
    nrepl-eval-comment root
}

define-command nrepl-eval-comment-word \
    -docstring 'evaluate the word under the cursor and append the result as a comment' %{
    nrepl-eval-comment word
}

# ── Connection ───────────────────────────────────────────────────────────────

define-command -hidden nrepl-report-status %{
    evaluate-commands %sh{
        python3 - "$kak_opt_config_support" "$kak_buffile" <<'PY'
import json, subprocess, sys
support, buffile = sys.argv[1:3]
def q(text): return "'" + str(text).replace("'", "''") + "'"
result = subprocess.run(['python3', support, 'nrepl-status', buffile],
                        capture_output=True, text=True)
log = ''
if result.returncode:
    summary = detail = 'nrepl: ' + (result.stderr.strip() or 'the daemon did not answer')
else:
    status = json.loads(result.stdout)
    ops = status.get('ops') or []
    log = status.get('log') or ''
    # The op spellings cider uses are known to support.py, which reports the
    # capability names the editor gates on rather than the raw op set.
    capabilities = status.get('capabilities') or []
    if status.get('connected'):
        summary = ('nrepl: connected 127.0.0.1:' + str(status.get('port')) +
                   ' | ' + str(len(ops)) + ' ops' +
                   ' | tests ' + ('yes' if 'test' in capabilities else 'no') +
                   ' | refresh ' + ('yes' if 'refresh' in capabilities else 'no'))
    else:
        summary = 'nrepl: not connected: ' + str(status.get('error') or 'reason unknown')
    detail = '\n'.join([summary,
                        'capabilities: ' + (', '.join(capabilities) or 'none'),
                        'root: ' + str(status.get('root')),
                        'session: ' + str(status.get('session')),
                        'pending: ' + (', '.join(status.get('pending') or []) or 'none'),
                        'socket: ' + str(status.get('socket')),
                        'log: ' + str(log),
                        'ops: ' + (', '.join(ops) or 'none')])
print('set-option global nrepl_report ' + q(summary))
print('set-option global nrepl_status_detail ' + q(detail))
print('set-option global nrepl_log_path ' + q(log))
PY
    }
}

define-command nrepl-connect -docstring 'connect to the project nREPL' %{
    nrepl-report-status
    echo -- %opt{nrepl_report}
}

# The daemon has no idle timeout and deliberately outlives the editor: the
# session state is the point. Disconnecting is therefore explicit, never a
# teardown hook.
define-command nrepl-disconnect -docstring 'stop the project nREPL daemon' %{
    evaluate-commands %sh{
        python3 - "$kak_opt_config_support" "$kak_buffile" <<'PY'
import subprocess, sys
support, buffile = sys.argv[1:3]
def q(text): return "'" + str(text).replace("'", "''") + "'"
def report(message):
    print('set-option global nrepl_report ' + q(message))
    print('echo -- ' + q(message))
result = subprocess.run(['python3', support, 'nrepl-shutdown', buffile],
                        capture_output=True, text=True)
outcome = 'daemon stopped' if not result.returncode else (
    result.stderr.strip() or 'no daemon was running')
report('nrepl: ' + outcome)
PY
    }
}

define-command nrepl-status -docstring 'report the nREPL connection and the server op set' %{
    nrepl-report-status
    info -title nREPL -- %opt{nrepl_status_detail}
    echo -- %opt{nrepl_report}
}

# ── Tests ────────────────────────────────────────────────────────────────────
#
# Conjure's four verbs, over cider-nrepl's test-var-query and retest.
#
# Failures land in the *make* buffer in this config's error format, so <ret> on
# one opens the source and Space c n walks them, exactly as a build error does.
# The run is not sent from the editor: :make already spawns a background process
# whose output streams into that buffer through a fifo, and the daemon op behind
# a test run is synchronous, so a project-wide run would otherwise hold the
# editor for as long as the suite takes. The summary is pushed back to the
# status line from that process; the expected-versus-actual detail goes to the
# log, where Conjure puts it.
#
# The gate on the server's op set happens before :make runs, so a server without
# the test middleware says so on the status line instead of opening a buffer
# holding one error.

declare-option -hidden str nrepl_test_command

define-command -hidden -params 1 nrepl-announce %{
    set-option global nrepl_report %arg{1}
    echo -- %arg{1}
}

define-command -hidden -params 1.. nrepl-run-tests %{
    evaluate-commands %sh{
        python3 "$kak_opt_config_support" nrepl-test-command \
            "$kak_buffile" "$kak_session" "$kak_client" "$@"
    }
}

define-command nrepl-test-under-cursor -docstring 'run the test the cursor is in' %{
    nrepl-detect-namespace
    set-option window nrepl_test_command \
        "fail 'nrepl: no test at the cursor; expected a deftest form. move onto one'"
    evaluate-commands -draft %{
        nrepl-select root
        evaluate-commands %sh{
            python3 - "$kak_opt_config_support" "${kak_opt_nrepl_namespace:-$kak_opt_nrepl_detected_namespace}" <<'PY'
import os, subprocess, sys
support, namespace = sys.argv[1:3]
def q(text): return "'" + str(text).replace("'", "''") + "'"
result = subprocess.run(['python3', support, 'clojure-test-var'],
                        input=os.environ['kak_selection'], capture_output=True, text=True)
name = result.stdout.strip()
if name:
    command = 'nrepl-run-tests var ' + q(namespace + '/' + name)
else:
    command = 'fail ' + q('nrepl: no deftest at the cursor; expected the cursor inside a '
                          'deftest or defspec. use :nrepl-test-namespace for the whole namespace')
print('set-option window nrepl_test_command ' + q(command))
PY
        }
    }
    evaluate-commands %opt{nrepl_test_command}
}

# A source namespace keeps its tests in the -test sibling by convention, and
# both are offered so the verb works from either file.
define-command nrepl-test-namespace -docstring 'run the tests of the current namespace' %{
    nrepl-detect-namespace
    evaluate-commands %sh{
        python3 - "${kak_opt_nrepl_namespace:-$kak_opt_nrepl_detected_namespace}" <<'PY'
import sys
namespace = sys.argv[1]
def q(text): return "'" + str(text).replace("'", "''") + "'"
targets = [namespace] if namespace.endswith('-test') else [namespace, namespace + '-test']
print('nrepl-run-tests namespace ' + ' '.join(map(q, targets)))
PY
    }
}

define-command nrepl-test-all -docstring 'run every test in the project' %{
    nrepl-run-tests all
}

define-command nrepl-test-rerun -docstring 'rerun the tests that failed last time' %{
    nrepl-run-tests rerun
}

# ── Doc and source lookup ────────────────────────────────────────────────────
#
# The static path is untouched and stays primary: Space e is lsp-hover and
# Space l opens the clojure-lsp menu. These two answer from the running image
# instead, which is what reaches a var that was only ever def'd at the REPL.
#
# Both rest on the info op, which Babashka advertises as readily as a JVM server
# carrying cider-nrepl, so neither is gated on middleware.

declare-option -hidden str nrepl_symbol

# The symbol is read inside a draft and the reply rendered outside it: an info
# box drawn in a draft context is invisible.
define-command -hidden nrepl-select-symbol %{
    nrepl-detect-namespace
    evaluate-commands -draft %{
        nrepl-select word
        set-option window nrepl_symbol %val{selection}
    }
}

define-command nrepl-doc-word -docstring 'doc for the word under the cursor' %{
    nrepl-select-symbol
    evaluate-commands %sh{
        python3 "$kak_opt_config_support" nrepl-doc "$kak_buffile" \
            "${kak_opt_nrepl_namespace:-$kak_opt_nrepl_detected_namespace}" \
            "$kak_cursor_line" "$kak_cursor_column" "$kak_opt_nrepl_symbol"
    }
}

define-command nrepl-goto-definition \
    -docstring 'jump to where the running REPL says the word is defined' %{
    nrepl-select-symbol
    evaluate-commands %sh{
        python3 "$kak_opt_config_support" nrepl-source "$kak_buffile" \
            "${kak_opt_nrepl_namespace:-$kak_opt_nrepl_detected_namespace}" \
            "$kak_opt_nrepl_symbol"
    }
}

# ── Refresh ──────────────────────────────────────────────────────────────────
#
# cider-nrepl's three refresh ops. The reload itself runs detached, because a
# project-wide reload takes far longer than the editor may be held for; the
# summary is pushed back to the status line when it finishes and the causes of
# a failed reload go to the log, exactly as a test run reports.
#
# The gate on the op set happens before the reload is dispatched, so a Babashka
# server says which op it lacks instead of reporting a failure minutes later.

define-command -hidden -params 1 nrepl-refresh-dispatch %{
    evaluate-commands %sh{
        python3 "$kak_opt_config_support" nrepl-refresh-command \
            "$kak_buffile" "$kak_session" "$kak_client" "$1"
    }
}

define-command nrepl-refresh-changed -docstring 'reload the namespaces that changed' %{
    nrepl-refresh-dispatch changed
}

define-command nrepl-refresh-all -docstring 'reload every namespace' %{
    nrepl-refresh-dispatch all
}

define-command nrepl-refresh-clear -docstring 'clear the refresh cache' %{
    nrepl-refresh-dispatch clear
}

# ── Runtime completion ───────────────────────────────────────────────────────
#
# clojure-lsp answers from static analysis and is the right source for anything
# written down. This answers for what is only in the running image -- a var
# def'd at the REPL, a namespace required there, a macro-generated name -- which
# is the gap static analysis cannot fill.
#
# Kakoune tries completers in order and stops at the first that produces
# candidates, so this sits behind clojure-lsp and ahead of word=all: the two
# sources can never duplicate or contradict each other, because only one of them
# ever fills the menu. clojure-lsp wins wherever it knows the name.
#
# Candidates are computed in a detached process that pushes the option back when
# it has an answer, so typing never waits on the server. That process never
# starts a daemon: a project with no REPL running must not spawn one from an
# idle keystroke.

declare-option -hidden completions nrepl_completions
declare-option -hidden str nrepl_completion_cursor
declare-option -docstring 'most runtime completion candidates offered at once' \
    int nrepl_completion_limit 40

define-command -hidden nrepl-completion-enable %{
    evaluate-commands %sh{
        python3 - "$kak_quoted_opt_completers" <<'PY'
import shlex, sys
completers = shlex.split(sys.argv[1])
def q(text): return "'" + str(text).replace("'", "''") + "'"
if 'option=nrepl_completions' not in completers:
    last_option = max((index for index, name in enumerate(completers)
                       if name.startswith('option=')), default=-1)
    completers.insert(last_option + 1, 'option=nrepl_completions')
print('set-option window completers ' + ' '.join(map(q, completers)))
PY
    }
}

define-command -hidden nrepl-complete %{
    evaluate-commands -draft %{
        set-option window nrepl_completion_cursor "%val{cursor_line} %val{cursor_column}"
        execute-keys 'x'
        nop %sh{
            # The cursor option is deliberately unquoted: it holds the line and
            # the column, and they are two arguments.
            (python3 "$kak_opt_config_support" nrepl-complete "$kak_buffile" "$kak_bufname" \
                "$kak_session" "${kak_opt_nrepl_namespace:-$kak_opt_nrepl_detected_namespace}" \
                ${kak_opt_nrepl_completion_cursor} "$kak_timestamp" \
                "$kak_opt_nrepl_completion_limit" "$kak_selection" \
                < /dev/null > /dev/null 2>&1 &) &
        }
    }
}

hook -group nrepl-completion global WinSetOption filetype=clojure %{
    nrepl-detect-namespace
    nrepl-completion-enable
    hook window -group nrepl-completion InsertIdle .* nrepl-complete
    hook window -group nrepl-completion BufWritePost .* nrepl-detect-namespace
    hook -once -always window WinSetOption filetype=.* %{
        remove-hooks window nrepl-completion
        try %{ set-option -remove window completers option=nrepl_completions }
    }
}

# ── Log ──────────────────────────────────────────────────────────────────────

define-command nrepl-log-open -docstring 'open the nREPL log in this window' %{
    nrepl-report-status
    evaluate-commands %sh{
        python3 "$kak_opt_config_support" nrepl-log-relay open "$kak_opt_nrepl_log_path" \
            "$kak_session" "$kak_opt_nrepl_log_relay_pid" "$kak_quoted_buflist"
    }
}

define-command -hidden nrepl-log-relay-stop %{
    evaluate-commands %sh{
        if [ -n "$kak_opt_nrepl_log_relay_pid" ]; then
            python3 "$kak_opt_config_support" nrepl-log-relay stop "$kak_opt_nrepl_log_path" \
                "$kak_session" "$kak_opt_nrepl_log_relay_pid"
        fi
    }
}

hook global BufClose \*nrepl-log\* nrepl-log-relay-stop
hook global KakEnd .* nrepl-log-relay-stop

define-command nrepl-log-open-in-client -docstring 'open the nREPL log in a new client' %{
    evaluate-commands -save-regs b %{
        set-register b %val{bufname}
        nrepl-log-open
        try %{ new buffer *nrepl-log* } catch %{
            echo -markup '{Error}nrepl: no windowing module for a new client; use :nrepl-log-open'
        }
        buffer %reg{b}
    }
}

define-command nrepl-log-close -docstring 'close the nREPL log buffer' %{
    try %{ delete-buffer! *nrepl-log* } catch %{ echo -- 'nrepl: the log is not open' }
}

define-command -hidden nrepl-truncate-log %{
    evaluate-commands %sh{
        if [ -n "$kak_opt_nrepl_log_path" ]; then : > "$kak_opt_nrepl_log_path"; fi
    }
}

define-command nrepl-log-reset -docstring 'clear the nREPL log' %{
    nrepl-report-status
    nrepl-log-close
    nrepl-truncate-log
    nrepl-log-open
}

define-command nrepl-log-reset-hard -docstring 'clear the nREPL log and reconnect' %{
    nrepl-report-status
    nrepl-log-close
    nrepl-truncate-log
    nrepl-disconnect
    nrepl-log-open
}

# ── Servers ──────────────────────────────────────────────────────────────────

# Babashka offers an nREPL without Java. Use :bb-repl in a bb.edn project.
define-command bb-repl -docstring 'start a Babashka nREPL for this project' %{
    project-run terminal repl python3 %opt{config_support} bb-server %sh{ printf '%s/.local/bin/bb' "$HOME" }
}

define-command tmux-repl-menu -docstring 'send text to an attached tmux REPL pane' %{
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
def q(text): return "'" + str(text).replace("'", "''") + "'"
print('sh -c ' + q(script))
PY
    }
    enter-user-mode repl
}

# ── Mappings ─────────────────────────────────────────────────────────────────
#
# Conjure's localleader grammar, verb for verb. The localleader lives in window
# scope under the Clojure filetype hook, the way Conjure scopes it to
# conjure#filetypes: everywhere else ',' keeps its native "keep only the main
# selection" meaning. Inside a Clojure window that native action moves to
# '<space>,', spelled as a select of the main selection's own descriptor
# because a mapping whose right-hand side is ',' would re-enter this mode.
#
# 'Space r' is an alias into the same mode, so the entry point already in the
# fingers keeps working.

declare-user-mode nrepl
declare-user-mode nrepl-eval
declare-user-mode nrepl-eval-comment
declare-user-mode nrepl-log
declare-user-mode nrepl-connect
declare-user-mode nrepl-test
declare-user-mode nrepl-refresh
declare-user-mode nrepl-goto

map global user r ': enter-user-mode nrepl<ret>' -docstring 'REPL…'

map global nrepl E ': nrepl-eval-selection<ret>' -docstring 'evaluate selections'
map global nrepl e ': enter-user-mode nrepl-eval<ret>' -docstring 'evaluate…'
map global nrepl l ': enter-user-mode nrepl-log<ret>' -docstring 'log…'
map global nrepl c ': enter-user-mode nrepl-connect<ret>' -docstring 'connection…'
map global nrepl t ': enter-user-mode nrepl-test<ret>' -docstring 'tests…'
map global nrepl r ': enter-user-mode nrepl-refresh<ret>' -docstring 'refresh…'
map global nrepl g ': enter-user-mode nrepl-goto<ret>' -docstring 'goto…'
map global nrepl K ': nrepl-doc-word<ret>' -docstring 'doc for the word under the cursor'

map global nrepl-eval e ': nrepl-eval-form<ret>' -docstring 'evaluate the innermost enclosing form'
map global nrepl-eval r ': nrepl-eval-root-form<ret>' -docstring 'evaluate the outermost (root) form'
map global nrepl-eval w ': nrepl-eval-word<ret>' -docstring 'evaluate the word under the cursor'
map global nrepl-eval b ': nrepl-eval-buffer<ret>' -docstring 'evaluate the whole buffer'
map global nrepl-eval f ': nrepl-eval-file<ret>' -docstring 'evaluate the file as it is on disk'
map global nrepl-eval '!' ': nrepl-eval-replace-form<ret>' -docstring 'evaluate the enclosing form and replace it with the result'
map global nrepl-eval i ': nrepl-interrupt<ret>' -docstring 'interrupt the running evaluation'
map global nrepl-eval c ': enter-user-mode nrepl-eval-comment<ret>' -docstring 'evaluate and comment…'

map global nrepl-eval-comment e ': nrepl-eval-comment-form<ret>' -docstring 'evaluate the enclosing form and append the result as a comment'
map global nrepl-eval-comment r ': nrepl-eval-comment-root-form<ret>' -docstring 'evaluate the root form and append the result as a comment'
map global nrepl-eval-comment w ': nrepl-eval-comment-word<ret>' -docstring 'evaluate the word under the cursor and append the result as a comment'

map global nrepl-log o ': nrepl-log-open<ret>' -docstring 'open the log in this window'
map global nrepl-log v ': nrepl-log-open-in-client<ret>' -docstring 'open the log in a new client'
map global nrepl-log q ': nrepl-log-close<ret>' -docstring 'close the log'
map global nrepl-log r ': nrepl-log-reset<ret>' -docstring 'clear the log'
map global nrepl-log R ': nrepl-log-reset-hard<ret>' -docstring 'clear the log and reconnect'

map global nrepl-connect c ': nrepl-connect<ret>' -docstring 'connect to the project nREPL'
map global nrepl-connect q ': nrepl-disconnect<ret>' -docstring 'stop the project nREPL daemon'
map global nrepl-connect s ': nrepl-status<ret>' -docstring 'report the connection and the server op set'
map global nrepl-connect b ': bb-repl<ret>' -docstring 'start a Babashka nREPL'
map global nrepl-connect u ': project-repl<ret>' -docstring 'start the project REPL'
map global nrepl-connect n ': nrepl-set-namespace<ret>' -docstring 'override the evaluation namespace'
map global nrepl-connect t ': tmux-repl-menu<ret>' -docstring 'tmux REPL mode…'

map global nrepl-test c ': nrepl-test-under-cursor<ret>' -docstring 'run the test the cursor is in'
map global nrepl-test n ': nrepl-test-namespace<ret>' -docstring 'run the tests of the current namespace'
map global nrepl-test a ': nrepl-test-all<ret>' -docstring 'run every test in the project'
map global nrepl-test s ': nrepl-test-rerun<ret>' -docstring 'rerun the tests that failed last time'

map global nrepl-refresh r ': nrepl-refresh-changed<ret>' -docstring 'reload the namespaces that changed'
map global nrepl-refresh a ': nrepl-refresh-all<ret>' -docstring 'reload every namespace'
map global nrepl-refresh c ': nrepl-refresh-clear<ret>' -docstring 'clear the refresh cache'

map global nrepl-goto d ': nrepl-goto-definition<ret>' -docstring 'jump to where the running REPL says the word is defined'

hook -group nrepl-localleader global WinSetOption filetype=(clojure|lisp) %{
    map window normal , ': enter-user-mode nrepl<ret>' -docstring 'REPL…'
    map window user , ': select %val{selection_desc}<ret>' -docstring 'keep only the main selection'
    hook -once -always window WinSetOption filetype=.* %{
        unmap window normal ,
        unmap window user ,
    }
}

map global display-options e ': toggle-eval-results<ret>' \
    -docstring 'toggle evaluation results'
