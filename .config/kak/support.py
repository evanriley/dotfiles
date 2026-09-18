#!/usr/bin/env python3
"""Small, independently testable helpers for the Kakoune configuration."""
import errno
import fcntl
import glob
import hashlib
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import signal
import socket
import subprocess
import sys
import tempfile
import threading
import time
import urllib.parse
import urllib.request


def quote(text):
    return "'" + str(text).replace("'", "''") + "'"


def root_for(filename, markers):
    start = Path(filename).absolute().parent if filename else Path.cwd()
    for directory in (start, *start.parents):
        if any(glob.glob(str(directory / marker)) for marker in markers):
            return directory
    return start


def project_root():
    return root_for(os.environ.get('kak_buffile', ''),
                    shlex.split(os.environ['kak_quoted_opt_project_root_files']))


def line_plan(descriptions, count, direction):
    selections = [[list(map(int, end.split('.'))) for end in desc.split(',')]
                  for desc in descriptions.split()]
    ranges = sorted((min(a[0], b[0]), max(a[0], b[0])) for a, b in selections)
    blocks = []
    for start, end in ranges:
        if blocks and start <= blocks[-1][1] + 1:
            blocks[-1][1] = max(end, blocks[-1][1])
        else:
            blocks.append([start, end])
    movable = [(a, b) for a, b in blocks if (a > 1 if direction < 0 else b < count)]
    for selection in selections:
        if any(a <= selection[0][0] <= b for a, b in movable):
            for endpoint in selection:
                endpoint[0] += direction
    return movable, selections


def move_lines(direction, descriptions, count, output):
    blocks, selections = line_plan(descriptions, count, direction)
    if output == 'select':
        print('select ' + ' '.join(','.join(f'{a}.{b}' for a, b in s) for s in selections))
        return
    data = sys.stdin.buffer.read()
    parts = data.split(b'\n')
    lines = [line + b'\n' for line in parts[:-1]]
    if parts[-1]:
        lines.append(parts[-1])
    for start, end in (blocks if direction < 0 else reversed(blocks)):
        if direction < 0:
            lines[start-2:end] = lines[start-1:end] + lines[start-2:start-1]
        else:
            lines[start-1:end+1] = lines[end:end+1] + lines[start-1:end]
    sys.stdout.buffer.write(b''.join(lines))


def recent(path, filename, limit):
    if not filename or not Path(filename).is_file():
        return
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(str(path) + '.lock', 'a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        old = path.read_text().splitlines() if path.exists() else []
        entries = list(dict.fromkeys([filename, *old]))[:max(1, limit)]
        fd, temporary = tempfile.mkstemp(prefix=path.name + '.', dir=path.parent)
        try:
            with os.fdopen(fd, 'w') as stream:
                stream.write('\n'.join(entries) + '\n')
                stream.flush()
                os.fsync(stream.fileno())
            os.replace(temporary, path)
        finally:
            if os.path.exists(temporary):
                os.unlink(temporary)


ANSI = re.compile(r'\x1b\[[0-9;]*[A-Za-z]')
OCAML = re.compile(r'^File "([^"]+)", lines? (\d+)(?:-\d+)?, characters (\d+)-\d+:')
LOCATION = re.compile(r'^(.+?):(\d+):(?:(\d+):)?\s+(.*)')


def normalize(line, root):
    line = ANSI.sub('', line)
    match = OCAML.match(line)
    if match:
        filename, row, col = match.groups()
        return f'{(Path(root) / filename).resolve()}:{row}:{int(col)+1}: error: OCaml diagnostic\n'
    match = LOCATION.match(line)
    if match:
        filename, row, col, message = match.groups()
        return f'{(Path(root) / filename).resolve()}:{row}:{col or 1}: {message}\n'
    return line


def build(root, command):
    print('$ ' + shlex.join(command), flush=True)
    env = dict(os.environ, NO_COLOR='1', TERM='dumb')
    process = subprocess.Popen(command, cwd=root, env=env, stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT, text=True, errors='replace')
    for line in process.stdout:
        print(normalize(line, root), end='', flush=True)
    status = process.wait()
    print(f'\n[exit {status}]', flush=True)
    return status


def bb_server(binary):
    """Publish Babashka's ephemeral port, then remove our port file."""
    port_file = Path('.nrepl-port')
    if port_file.exists():
        raise ValueError('.nrepl-port already exists; stop that REPL and remove its stale port file first.')
    process = subprocess.Popen([binary, '--nrepl-server', '127.0.0.1:0'],
                               stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    port = None
    def stop(signum, frame):
        process.terminate()
    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    try:
        for line in process.stdout:
            print(line, end='', flush=True)
            match = re.search(r'Started nREPL server at 127\.0\.0\.1:(\d+)', line)
            if match:
                port = match[1] + '\n'
                with port_file.open('x') as stream:
                    stream.write(port)
        return process.wait()
    finally:
        if process.poll() is None:
            process.terminate()
            process.wait()
        if port and port_file.exists() and port_file.read_text() == port:
            port_file.unlink()


def format_code(filename, filetype, zig):
    """Use whole-buffer replacement to avoid Kakoune's last-line c behavior."""
    original = sys.stdin.buffer.read()
    root = Path(filename).absolute().parent if filename else Path.cwd()
    if filetype == 'gleam':
        command = ['gleam', 'format', '--stdin']
    elif filetype == 'zig':
        command = [zig, 'fmt', '--stdin']
    elif filetype == 'ocaml':
        command = ['ocamlformat', '--name', filename or 'stdin.ml', '-']
        if shutil.which('opam'):
            command = ['opam', 'exec', '--', *command]
    else:
        command = [str(Path.home() / '.local/bin/cljfmt'), '--quiet', 'fix', '-']
    try:
        result = subprocess.run(command, input=original, cwd=root, capture_output=True)
    except OSError:
        sys.stdout.buffer.write(original)
        raise
    # Preserve the source even if a formatter is missing or the syntax is invalid.
    sys.stdout.buffer.write(result.stdout if result.returncode == 0 else original)
    if result.returncode:
        sys.stderr.buffer.write(result.stderr)
    return result.returncode


# --- Clojure form selection ----------------------------------------------

# Kakoune's `(` object counts brackets without knowing Clojure lexical syntax,
# so it opens forms on brackets inside strings, comments and character
# literals, and cannot see `[` or `{` at the top level. The editor commands
# select through this scanner instead.
CLOJURE_OPENERS = b'([{'
CLOJURE_CLOSERS = b')]}'
# A symbol ends at whitespace or at any character that starts another form.
CLOJURE_SYMBOL_BREAK = frozenset(b' \t\r\n\f()[]{}",;`~@^\\')
# `#` and a leading `'` are reader syntax around a name, not part of it.
CLOJURE_SYMBOL_PREFIX = b"#'"


def clojure_bracket_ranges(data):
    """Byte ranges of every bracketed form, outermost closing last."""
    ranges, stack, index, size = [], [], 0, len(data)
    while index < size:
        byte = data[index:index + 1]
        if byte == b'\\':
            index += 2
        elif byte == b'"':
            index += 1
            while index < size:
                if data[index:index + 1] == b'\\':
                    index += 2
                    continue
                index += 1
                if data[index - 1:index] == b'"':
                    break
        elif byte == b';':
            newline = data.find(b'\n', index)
            index = size if newline < 0 else newline
        elif byte in CLOJURE_OPENERS:
            stack.append(index)
            index += 1
        elif byte in CLOJURE_CLOSERS:
            if stack:
                ranges.append((stack.pop(), index))
            index += 1
        else:
            index += 1
    # An unclosed form is what a half-typed buffer looks like; treat it as
    # running to the end rather than refusing to select anything.
    ranges.extend((start, size - 1) for start in stack)
    return ranges


def clojure_form_range(data, offset, outermost):
    enclosing = [span for span in clojure_bracket_ranges(data) if span[0] <= offset <= span[1]]
    if not enclosing:
        return None
    return min(enclosing) if outermost else max(enclosing)


def clojure_word_range(data, offset):
    if offset >= len(data) or data[offset] in CLOJURE_SYMBOL_BREAK:
        return None
    start, end = offset, offset
    while start > 0 and data[start - 1] not in CLOJURE_SYMBOL_BREAK:
        start -= 1
    while end + 1 < len(data) and data[end + 1] not in CLOJURE_SYMBOL_BREAK:
        end += 1
    while start < end and data[start] in CLOJURE_SYMBOL_PREFIX:
        start += 1
    return start, end


# clojure.test names a test with the form that defines it, and the editor needs
# that name to ask the server for one test rather than a whole namespace.
CLOJURE_TEST_DEFINER = re.compile(
    r'\s*\(\s*(?:[^\s()\[\]{}/]+/)?(?:deftest|defspec)\s+(?:\^\S+\s+)*([^\s()\[\]{},"]+)')


def clojure_test_var(text):
    """Name the test a top-level form defines, or None when it defines none."""
    match = CLOJURE_TEST_DEFINER.match(text)
    return match[1] if match else None


def byte_offset(data, line, column):
    start = 0
    for _ in range(line - 1):
        newline = data.find(b'\n', start)
        if newline < 0:
            break
        start = newline + 1
    return min(start + column - 1, max(len(data) - 1, 0))


def line_column(data, offset):
    return data.count(b'\n', 0, offset) + 1, offset - (data.rfind(b'\n', 0, offset) + 1) + 1


def clojure_form(kind, line, column):
    """Print the Kakoune `select` covering the form or symbol at a cursor."""
    data = sys.stdin.buffer.read()
    offset = byte_offset(data, int(line), int(column))
    if kind == 'word':
        span = clojure_word_range(data, offset)
        missing = 'no Clojure symbol under the cursor'
    else:
        span = clojure_form_range(data, offset, kind == 'root')
        missing = f'no enclosing {kind} at the cursor'
    if span is None:
        print('fail ' + quote(f'nrepl: {missing}; expected the cursor on code. '
                              f'move onto a form and evaluate again'))
        return 0
    (first_line, first_column), (last_line, last_column) = line_column(data, span[0]), line_column(data, span[1])
    print(f'select {first_line}.{first_column},{last_line}.{last_column}')
    return 0


# --- Persistent nREPL client -------------------------------------------------
#
# A fresh nREPL session per invocation cannot support *1, in-ns, dynamic
# bindings, streamed stdout or interrupt. These commands run one daemon per
# project root instead: a single connection, a single cloned session held for
# the daemon's lifetime, and a unix socket the editor reconnects to.
#
# Contract with repl.kak
# ----------------------
# Every asynchronous evaluation is delivered back to the editor by running
#     kak -p <session>
# with the payload
#     evaluate-commands -try-client <client> 'nrepl-handle-result <8 arguments>'
# The client name and the inner command are Kakoune single-quoted strings, so
# results containing braces, quotes or newlines survive the round trip.
#
# nrepl-handle-result takes eight positional arguments. All are always present,
# possibly empty, in this order:
#     1 id         daemon request id, as printed by nrepl-eval
#     2 status     ok | error | interrupted | disconnected
#     3 namespace  namespace the evaluation ended in, empty when unknown
#     4 values     printed results, newline separated, empty when none
#     5 error      exception text, empty when status is ok
#     6 buffile    buffer the code came from
#     7 line       1-based line of the start of the evaluated form
#     8 column     1-based column of the start of the evaluated form
# Arguments 6-8 are echoed back untouched so the caller can anchor inline
# virtual text at the form it evaluated.
#
# Two further daemon request kinds exist alongside eval, op, interrupt, status
# and shutdown, and neither of them touches the eight-argument shape above:
#     log    append text to the log and the fifo, so a report produced outside
#            the daemon -- a test run, say -- reaches the log buffer in order
#            with everything else. Never connects, and answers {'logged': True}.
#     op     already existed, and is what the test and completion commands send.
#            Both call it from a background process rather than from the editor,
#            because it is synchronous and a project-wide test run takes minutes.
#
# Everything the session produces is also appended to a log file in Conjure's
# shape and mirrored into a fifo meant for `edit -fifo`. The daemon holds the
# fifo open for its whole lifetime, so the buffer streams instead of closing
# after one evaluation. Both paths, plus the op set the server advertises, come
# from nrepl-status. Mirroring is best-effort: a fifo with no reader holds one
# pipe buffer, and further lines are dropped from the fifo only. The log file is
# the complete record.
NREPL_ROOT_MARKERS = ['.nrepl-port', 'deps.edn', 'bb.edn', 'shadow-cljs.edn', 'project.clj', '.git']
NREPL_INTEGER_KEYS = ['line', 'column', 'limit']
# cider middleware advertises an op bare, under cider/, and for clj-reload under
# its own namespace. The bare name is what the editor gates on; a missing bare
# name does not prove the op is absent, so every spelling is accepted.
NREPL_CAPABILITIES = {'test': ['test-var-query'], 'rerun': ['retest'],
                      'refresh': ['refresh', 'reload'], 'complete': ['complete'],
                      'interrupt': ['interrupt']}
NREPL_NO_TEST_OPS = ('nrepl: this server has no {op} op; expected a JVM REPL with cider-nrepl. '
                     "Babashka's nREPL carries no test middleware, so start the project REPL "
                     'with :project-repl, or run the tests with :test')
NREPL_CONNECT_TIMEOUT = 5.0
DAEMON_START_TIMEOUT = 15.0
DAEMON_REQUEST_TIMEOUT = 600.0
# The daemon reports its own timeout with the request id and advice attached, so
# the client waits a little longer than the daemon and lets that message win.
DAEMON_REPLY_MARGIN = 5.0
LOG_SEPARATOR = '; ' + '-' * 60


class BencodeIncomplete(Exception):
    """A frame was split across socket reads; more bytes are needed."""


def bencode(value):
    if isinstance(value, bool):
        raise ValueError('cannot bencode a boolean; expected an int, str, bytes, list or dict')
    if isinstance(value, int):
        return b'i' + str(value).encode() + b'e'
    if isinstance(value, str):
        value = value.encode()
    if isinstance(value, (bytes, bytearray)):
        return str(len(value)).encode() + b':' + bytes(value)
    if isinstance(value, (list, tuple)):
        return b'l' + b''.join(map(bencode, value)) + b'e'
    if isinstance(value, dict):
        items = sorted(value.items(), key=lambda item: str(item[0]))
        return b'd' + b''.join(bencode(str(k)) + bencode(v) for k, v in items) + b'e'
    raise ValueError(f'cannot bencode {type(value).__name__}; expected an int, str, bytes, list or dict')


def bdecode_value(data, position):
    marker = data[position:position + 1]
    if not marker:
        raise BencodeIncomplete()
    if marker == b'i':
        end = data.find(b'e', position)
        if end < 0:
            raise BencodeIncomplete()
        return int(data[position + 1:end]), end + 1
    if marker in (b'l', b'd'):
        items, position = [], position + 1
        while True:
            head = data[position:position + 1]
            if not head:
                raise BencodeIncomplete()
            if head == b'e':
                position += 1
                break
            item, position = bdecode_value(data, position)
            items.append(item)
        if marker == b'l':
            return items, position
        if len(items) % 2:
            raise ValueError('bencode dictionary has an odd number of elements; expected alternating keys and values')
        return dict(zip(items[::2], items[1::2])), position
    if marker.isdigit():
        colon = data.find(b':', position)
        if colon < 0:
            raise BencodeIncomplete()
        end = colon + 1 + int(data[position:colon])
        if len(data) < end:
            raise BencodeIncomplete()
        return data[colon + 1:end].decode('utf-8', 'replace'), end
    raise ValueError(f'invalid bencode marker {marker!r} at offset {position}; expected i, l, d or a length')


def bdecode(data):
    """Decode whole frames, returning them with the undecodable remainder."""
    values, position = [], 0
    while position < len(data):
        try:
            value, position = bdecode_value(data, position)
        except BencodeIncomplete:
            break
        values.append(value)
    return values, data[position:]


def nrepl_root(filename):
    return root_for(filename, NREPL_ROOT_MARKERS)


def nrepl_port_file(filename):
    candidate = root_for(filename, ['.nrepl-port']) / '.nrepl-port'
    return candidate if candidate.is_file() else None


def runtime_directory():
    base = os.environ.get('XDG_RUNTIME_DIR') or os.environ.get('TMPDIR') or '/tmp'
    directory = Path(base) / f'kak-nrepl-{os.getuid()}'
    directory.mkdir(parents=True, exist_ok=True, mode=0o700)
    return directory


def nrepl_paths(root):
    """One daemon per project root, at a stable path both sides can derive."""
    digest = hashlib.sha1(str(root).encode()).hexdigest()[:12]
    name = re.sub(r'[^A-Za-z0-9._-]', '_', Path(root).name) or 'root'
    base = str(runtime_directory() / f'{name}-{digest}')
    return {'socket': base + '.sock', 'log': base + '.log', 'fifo': base + '.fifo',
            'lock': base + '.lock', 'stderr': base + '.stderr'}


NREPL_LOG_BUFFER = '*nrepl-log*'


def nrepl_log_relay_path(log, session):
    """One relay per editor session, so two sessions never share a fifo."""
    return log + '-' + session + '.fifo'


def nrepl_log_relay_stop(log, session, pid):
    """Signal the relay of `session` and drop its fifo.

    A pid the editor remembers may have been recycled by an unrelated
    process, so it is signalled only while it still names the log it streams.
    """
    try:
        command = Path(f'/proc/{pid}/cmdline').read_bytes().decode().split('\0')
    except (OSError, UnicodeDecodeError):
        command = []
    if log and log in command:
        try:
            os.kill(int(pid), signal.SIGTERM)
        except (OSError, ValueError):
            pass
    if log:
        Path(nrepl_log_relay_path(log, session)).unlink(missing_ok=True)


def nrepl_log_relay(action, args):
    """Open or close the `tail -f` that fills the log buffer.

    The daemon's own fifo mirrors only what is written while a reader is
    attached and replays undrained data as duplicates, so the buffer is fed
    from the log file instead: `tail -f -n +1` replays the whole record and
    then streams. That process does not end on its own -- it neither notices
    the editor quitting nor writes often enough to take a timely SIGPIPE --
    and an orphan of it stalls any supervisor that waits on reparented
    children. Every path that drops the buffer therefore stops it here.
    """
    log, session, pid = args[0], args[1], args[2]
    if action == 'stop':
        nrepl_log_relay_stop(log, session, pid)
        print("set-option global nrepl_log_relay_pid ''")
        return
    if not log:
        print('fail ' + quote('nrepl: the daemon reported no log file; check :nrepl-status'))
        return
    if NREPL_LOG_BUFFER in shlex.split(args[3]):
        print('buffer ' + NREPL_LOG_BUFFER)
        return
    nrepl_log_relay_stop(log, session, pid)
    relay = nrepl_log_relay_path(log, session)
    os.mkfifo(relay, 0o600)
    Path(log).touch()
    process = subprocess.Popen(
        ['sh', '-c', 'exec tail -f -n +1 "$1" > "$2"', 'nrepl-log-relay', log, relay],
        stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        start_new_session=True, close_fds=True)
    print('set-option global nrepl_log_relay_pid ' + str(process.pid))
    print('edit -fifo ' + quote(relay) + ' -scroll ' + NREPL_LOG_BUFFER)


def socket_answers(path):
    client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        client.connect(path)
        return True
    except OSError:
        return False
    finally:
        client.close()


def spawn_daemon(root, paths):
    with open(paths['lock'], 'a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        if socket_answers(paths['socket']):
            return
        with open(paths['stderr'], 'a') as errors:
            subprocess.Popen([sys.executable, os.path.abspath(__file__), 'nrepl-daemon', str(root)],
                             cwd=str(root), stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                             stderr=errors, start_new_session=True, close_fds=True)


def daemon_socket(root, autostart):
    paths = nrepl_paths(root)
    deadline = time.monotonic() + DAEMON_START_TIMEOUT
    spawned = False
    while True:
        client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        try:
            client.connect(paths['socket'])
            return client
        except OSError as error:
            client.close()
            if error.errno not in (errno.ENOENT, errno.ECONNREFUSED):
                raise
            if not autostart:
                raise ValueError(f'no nREPL daemon for {root}; expected one listening on '
                                 f'{paths["socket"]}. evaluate a form to start one')
            if not spawned:
                spawn_daemon(root, paths)
                spawned = True
            elif time.monotonic() > deadline:
                raise ValueError(f'the nREPL daemon for {root} did not answer on {paths["socket"]} '
                                 f'within {DAEMON_START_TIMEOUT:g}s; expected it to bind that socket. '
                                 f'check {paths["stderr"]}')
            time.sleep(0.05)


def daemon_request(filename, request, autostart=True, timeout=DAEMON_REQUEST_TIMEOUT):
    root = nrepl_root(filename)
    client = daemon_socket(root, autostart)
    try:
        client.settimeout(timeout)
        client.sendall(json.dumps(request).encode() + b'\n')
        buffer = b''
        while b'\n' not in buffer:
            chunk = client.recv(65536)
            if not chunk:
                raise ValueError(f'the nREPL daemon for {root} closed the connection before replying; '
                                 f'expected one reply line. check {nrepl_paths(root)["stderr"]}')
            buffer += chunk
        return json.loads(buffer.split(b'\n', 1)[0])
    finally:
        client.close()


def nrepl_timeout(pairs):
    """Split an optional timeout=<seconds> out of the key=value op arguments."""
    kept, timeout = [], DAEMON_REQUEST_TIMEOUT
    for pair in pairs:
        key, separator, value = pair.partition('=')
        if not separator or key != 'timeout':
            kept.append(pair)
            continue
        try:
            timeout = float(value)
        except ValueError:
            raise ValueError(f'malformed nREPL timeout {value!r}; expected a number of seconds')
        if timeout <= 0:
            raise ValueError(f'nREPL timeout {value!r} is not positive; expected seconds above zero')
    return kept, timeout


def nrepl_advertises(ops, *names):
    """Whether the server offers an op under any of the spellings cider uses."""
    return any(op == name or op.endswith('/' + name) for op in ops for name in names)


def nrepl_capabilities(ops):
    """The editor-facing capability names an op set supports."""
    return sorted(name for name, spellings in NREPL_CAPABILITIES.items()
                  if nrepl_advertises(ops, *spellings))


def nrepl_message(op, pairs):
    """Turn key=value command-line arguments into one nREPL message."""
    message = {'op': op}
    for pair in pairs:
        key, separator, value = pair.partition('=')
        if not separator:
            raise ValueError(f'malformed nREPL argument {pair!r}; expected key=value')
        message[key] = int(value) if key in NREPL_INTEGER_KEYS and value else value
    return message


class NreplDaemon:
    """One nREPL connection and session, shared by every editor client."""

    def __init__(self, root):
        self.root = Path(root)
        self.paths = nrepl_paths(self.root)
        self.state = threading.RLock()
        self.connecting = threading.Lock()
        self.output = threading.Lock()
        self.pending = {}
        self.counter = 0
        self.connection = None
        self.session = None
        self.ops = []
        self.port = None
        self.error = 'not connected yet'
        self.running = True
        self.log = open(self.paths['log'], 'a', buffering=1, errors='replace')
        self.fifo = self.open_fifo()

    def open_fifo(self):
        path = Path(self.paths['fifo'])
        if path.exists() and not path.is_fifo():
            path.unlink()
        if not path.exists():
            os.mkfifo(path, 0o600)
        # O_RDWR keeps the write end valid while no editor buffer is attached.
        return os.open(path, os.O_RDWR | os.O_NONBLOCK)

    def write_log(self, text):
        with self.output:
            self.log.write(text)
            try:
                os.write(self.fifo, text.encode())
            except (BlockingIOError, OSError):
                pass

    def write_stream(self, prefix, text):
        self.write_log(''.join(f'{prefix}{line}\n' for line in text.split('\n')))

    def next_id(self):
        with self.state:
            self.counter += 1
            return f'kak-{self.counter}'

    def port_from_file(self):
        port_file = nrepl_port_file(self.root / '.nrepl-port')
        if not port_file:
            return None, (f'no .nrepl-port under {self.root} or its ancestors; expected a running '
                          f'nREPL server. start one with :project-repl or :bb-repl')
        text = port_file.read_text().strip()
        if not text.isdigit():
            return None, (f'{port_file} contains {text!r}; expected a port number. '
                          f'remove the stale file and start an nREPL server')
        return int(text), None

    def ensure_connection(self):
        with self.connecting:
            with self.state:
                if self.connection:
                    return True
            port, failure = self.port_from_file()
            if failure:
                with self.state:
                    self.error = failure
                return False
            try:
                connection = socket.create_connection(('127.0.0.1', port), NREPL_CONNECT_TIMEOUT)
            except OSError as error:
                with self.state:
                    self.error = (f'no nREPL server answering on 127.0.0.1:{port} ({error}); expected '
                                  f'the server named by {self.root}/.nrepl-port. remove the stale port '
                                  f'file and start an nREPL server')
                return False
            connection.settimeout(None)
            with self.state:
                self.connection = connection
                self.port = port
                self.error = None
            threading.Thread(target=self.read_loop, args=(connection,), daemon=True).start()
            return self.handshake()

    def handshake(self):
        clone = self.request_sync({'op': 'clone'}, NREPL_CONNECT_TIMEOUT * 4)['messages']
        session = next((m['new-session'] for m in clone if 'new-session' in m), None)
        if not session:
            self.disconnect(f'the nREPL server on port {self.port} did not answer clone with a '
                            f'session; expected new-session. check the server log')
            return False
        with self.state:
            self.session = session
        describe = self.request_sync({'op': 'describe', 'session': session},
                                     NREPL_CONNECT_TIMEOUT * 4)['messages']
        ops = {}
        for message in describe:
            ops.update(message.get('ops') or {})
        with self.state:
            self.ops = sorted(ops)
        self.write_log(f'{LOG_SEPARATOR}\n; nrepl: connected to 127.0.0.1:{self.port} '
                       f'session {session} ({len(self.ops)} ops)\n')
        return True

    def send(self, message):
        with self.state:
            connection = self.connection
        if not connection:
            raise ValueError('the nREPL connection is gone; expected a live connection')
        connection.sendall(bencode(message))

    def register(self, message, kak=None, origin=None):
        record = {'id': message['id'], 'messages': [], 'done': threading.Event(),
                  'kak': kak, 'origin': origin or ['', '', ''], 'values': [], 'forced': None,
                  'namespace': '', 'errors': [], 'statuses': [], 'streams': {}}
        with self.state:
            self.pending[record['id']] = record
        return record

    def request_sync(self, message, timeout):
        message = dict(message, id=self.next_id())
        record = self.register(message)
        try:
            self.send(message)
        except (OSError, ValueError):
            self.finish(record, 'disconnected')
        record['done'].wait(timeout)
        # A request that timed out is still running at the server. Leaving it
        # registered is what keeps it reachable from nrepl-interrupt; finish
        # drops it when the server eventually answers, or when the connection
        # goes away.
        if record['done'].is_set():
            with self.state:
                self.pending.pop(record['id'], None)
        return record

    def read_loop(self, connection):
        buffer = b''
        try:
            while True:
                chunk = connection.recv(65536)
                if not chunk:
                    break
                messages, buffer = bdecode(buffer + chunk)
                for message in messages:
                    self.dispatch(message)
        except (OSError, ValueError):
            pass
        finally:
            self.disconnect(f'the nREPL server on port {self.port} closed the connection; '
                            f'expected it to stay up. restart it, then evaluate again')

    def dispatch(self, message):
        with self.state:
            record = self.pending.get(message.get('id'))
        if not record:
            return
        record['messages'].append(message)
        self.record_message(record, message)
        if 'done' in (message.get('status') or []):
            self.finish(record, None)

    def record_message(self, record, message):
        for stream, prefix in [('out', '; (out) '), ('err', '; (err) ')]:
            if stream in message:
                self.flush_streams(record, keep=stream)
                buffered = record['streams'].get(stream, '') + message[stream]
                complete, _, remainder = buffered.rpartition('\n')
                record['streams'][stream] = remainder
                if complete:
                    self.write_stream(prefix, complete)
                if stream == 'err':
                    record['errors'].append(message[stream])
        if 'ns' in message:
            record['namespace'] = message['ns']
        if 'value' in message:
            self.flush_streams(record)
            record['values'].append(message['value'])
            self.write_log(message['value'] + '\n')
        if 'ex' in message:
            record['errors'].append(message['ex'])
        record['statuses'].extend(message.get('status') or [])

    def flush_streams(self, record, keep=None):
        """Keep partial lines chronological with whatever is written next."""
        for stream, prefix in [('out', '; (out) '), ('err', '; (err) ')]:
            partial = record['streams'].get(stream)
            if partial and stream != keep:
                record['streams'][stream] = ''
                self.write_stream(prefix, partial)

    def finish(self, record, forced_status):
        with self.state:
            if record['id'] not in self.pending and record['done'].is_set():
                return
            self.pending.pop(record['id'], None)
        self.flush_streams(record)
        record['forced'] = forced_status
        record['done'].set()
        status = forced_status or self.outcome(record)
        if status == 'disconnected':
            record['errors'].append(self.error or 'the nREPL connection was lost')
            self.write_stream('; (err) ', self.error or 'the nREPL connection was lost')
        elif status == 'interrupted':
            self.write_log('; nrepl: interrupted\n')
        if not record['kak']:
            return
        session, client = record['kak']
        # Ordinary stderr output is not an exception, so a successful evaluation
        # reports no error text even when it printed to *err*.
        failure = '' if status == 'ok' else ''.join(record['errors']).strip()
        push_to_kakoune(session, client, [
            record['id'], status, record['namespace'], '\n'.join(record['values']),
            failure, *record['origin']])

    def outcome(self, record):
        if 'eval-error' in record['statuses'] or 'error' in record['statuses']:
            return 'error'
        return 'interrupted' if 'interrupted' in record['statuses'] else 'ok'

    def disconnect(self, reason):
        with self.state:
            if self.connection:
                try:
                    self.connection.close()
                except OSError:
                    pass
                self.write_log(f'; nrepl: {reason}\n')
            self.connection = None
            self.session = None
            self.ops = []
            self.error = reason
            records = list(self.pending.values())
        for record in records:
            self.finish(record, 'disconnected')

    def status(self):
        with self.state:
            return {'root': str(self.root), 'connected': bool(self.connection), 'port': self.port,
                    'session': self.session, 'ops': list(self.ops), 'error': self.error,
                    'pending': sorted(self.pending), 'socket': self.paths['socket'],
                    'log': self.paths['log'], 'fifo': self.paths['fifo']}

    def start_evaluation(self, request):
        origin = [request.get('file', ''), request.get('line', ''), request.get('column', '')]
        kak = [request.get('kak-session', ''), request.get('kak-client', '')]
        message = {'op': 'eval', 'code': request['code'], 'id': self.next_id()}
        for key in ['ns', 'file']:
            if request.get(key):
                message[key] = request[key]
        for key in ['line', 'column']:
            if str(request.get(key, '')).isdigit():
                message[key] = int(request[key])
        record = self.register(message, kak=kak if kak[0] else None, origin=[str(part) for part in origin])
        self.write_evaluation_header(request, request['code'])
        with self.state:
            message['session'] = self.session
        self.send(message)
        return {'id': record['id']}

    def synchronous_reply(self, record, timeout):
        if record['forced'] == 'disconnected':
            return {'error': self.error or 'the nREPL connection was lost'}
        if not record['done'].is_set():
            return {'error': f'the nREPL server did not finish request {record["id"]} within '
                             f'{timeout:g}s; expected a done status. interrupt it or restart the server'}
        return {'messages': record['messages']}

    def write_evaluation_header(self, request, code):
        where = ''
        if request.get('file'):
            where = f' ({request["file"]}:{request.get("line", "")}:{request.get("column", "")})'
        header = f'; eval{where} {request.get("ns") or ""}'.rstrip()
        self.write_log(f'{LOG_SEPARATOR}\n{header}\n{code}\n')

    def handle(self, request):
        kind = request.get('kind')
        if kind == 'status':
            self.ensure_connection()
            return self.status()
        if kind == 'shutdown':
            self.running = False
            return {'stopped': True}
        # Logging never needs the server, so it is answered before connecting:
        # a test run that could not connect still says so in the log buffer.
        if kind == 'log':
            self.write_log(request.get('text', ''))
            return {'logged': True}
        if not self.ensure_connection():
            if kind == 'eval' and request.get('kak-session'):
                push_to_kakoune(request['kak-session'], request.get('kak-client', ''),
                                [ '', 'disconnected', '', '', self.error,
                                 request.get('file', ''), request.get('line', ''), request.get('column', '')])
            return {'error': self.error}
        if kind == 'eval':
            return self.start_evaluation(request)
        if kind == 'op':
            message = dict(request['message'])
            message.setdefault('session', self.session)
            timeout = request.get('timeout', DAEMON_REQUEST_TIMEOUT)
            if message.get('op') == 'eval':
                self.write_evaluation_header(request, message.get('code', ''))
            return self.synchronous_reply(self.request_sync(message, timeout), timeout)
        if kind == 'interrupt':
            with self.state:
                targets = request.get('ids') or sorted(self.pending)
            replies = []
            for target in targets:
                replies.extend(self.request_sync(
                    {'op': 'interrupt', 'session': self.session, 'interrupt-id': target},
                    NREPL_CONNECT_TIMEOUT * 4)['messages'])
            return {'messages': replies, 'interrupted': targets}
        raise ValueError(f'unknown daemon request {kind!r}; expected status, eval, op, log, interrupt or shutdown')

    def serve_client(self, connection):
        try:
            connection.settimeout(DAEMON_REQUEST_TIMEOUT)
            buffer = b''
            while b'\n' not in buffer:
                chunk = connection.recv(65536)
                if not chunk:
                    return
                buffer += chunk
            try:
                reply = self.handle(json.loads(buffer.split(b'\n', 1)[0]))
            except (OSError, ValueError) as error:
                reply = {'error': str(error)}
            connection.sendall(json.dumps(reply).encode() + b'\n')
        except OSError:
            pass
        finally:
            connection.close()
            if not self.running:
                socket_answers(self.paths['socket'])

    def serve(self):
        with open(self.paths['lock'], 'a') as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            if socket_answers(self.paths['socket']):
                return 0
            Path(self.paths['socket']).unlink(missing_ok=True)
            listener = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            listener.bind(self.paths['socket'])
            os.chmod(self.paths['socket'], 0o600)
            listener.listen(16)
        self.ensure_connection()
        try:
            while self.running:
                connection, _ = listener.accept()
                threading.Thread(target=self.serve_client, args=(connection,), daemon=True).start()
        finally:
            listener.close()
            Path(self.paths['socket']).unlink(missing_ok=True)
        return 0


# --- Test runner -------------------------------------------------------------
#
# cider-nrepl answers a test run with a map of namespace to var to results.
# clojure.test records a failure at the assertion that failed, but an error at
# whatever threw, which is routinely inside the JDK -- so both are resolved
# against the test var's own definition, and the assertion line is kept only
# when it was reported against that same file. Every line printed here is
# therefore a location the *make* buffer can open.
#
# The one-line report is what :make reads. The full expected-versus-actual text
# goes to the nREPL log instead, where Conjure puts it.

NREPL_TEST_TIMEOUT = 900.0
NREPL_QUERY_TIMEOUT = 60.0
# Completion runs on every idle keystroke, so it gives up rather than queue.
NREPL_COMPLETE_TIMEOUT = 2.0
TEST_LABELS = {'fail': 'FAIL', 'error': 'ERROR'}


def test_text(value):
    """cider-nrepl sends an absent string as an empty list; flatten either."""
    if isinstance(value, (list, tuple)):
        value = ' '.join(map(str, value))
    return ' '.join(str('' if value is None else value).split())


def test_failures(results):
    """Every failing result, ordered the way a reader scans a file listing."""
    for namespace in sorted(results):
        for var in sorted(results[namespace]):
            for entry in results[namespace][var]:
                if entry.get('type') in TEST_LABELS:
                    yield entry


def test_result_location(entry, path, definition_line):
    """Where the editor should land: the assertion, or the test that threw."""
    if not path:
        return '', None
    reported = str(entry.get('file') or '')
    line = entry.get('line')
    if line and reported and os.path.basename(reported) == os.path.basename(path):
        return path, line
    return path, definition_line


def test_failure_detail(entry):
    parts = [test_text(entry.get('context')), test_text(entry.get('message'))]
    if entry.get('type') == 'error':
        parts.append(test_text(entry.get('error')))
    else:
        parts.append('expected ' + (test_text(entry.get('expected')) or 'nothing') +
                     ', actual ' + (test_text(entry.get('actual')) or 'nothing'))
    return '; '.join(part for part in parts if part)


def test_failure_line(entry, location):
    """One line in the shape Kakoune's make_error_pattern selects."""
    label = TEST_LABELS.get(entry.get('type'), 'FAIL')
    detail = f'{label} {entry.get("ns")}/{entry.get("var")}: {test_failure_detail(entry)}'
    path, line = location
    if not path:
        return f'; {detail} (no source location; :nrepl-log-open for the detail)'
    return f'{path}:{line or 1}:1: error: {detail}'


def test_failure_log(entry, location):
    """The detail the one-line report had to drop, in the log's comment shape."""
    path, line = location
    where = f'{path}:{line}' if path else 'no source location'
    body = [f'; {TEST_LABELS.get(entry.get("type"), "FAIL")} '
            f'{entry.get("ns")}/{entry.get("var")} ({where})']
    for field in ['context', 'message', 'expected', 'actual', 'error']:
        value = entry.get(field)
        if isinstance(value, (list, tuple)):
            value = ' '.join(map(str, value))
        value = str('' if value is None else value).rstrip('\n')
        if not value:
            continue
        for index, part in enumerate(value.split('\n')):
            label = (field + ':') if index == 0 else ''
            body.append(f';   {label:<10}{part}')
    return '\n'.join(body) + '\n'


def test_summary_text(summary):
    def count(key):
        return int(summary.get(key) or 0)
    total = count('test')
    if not total:
        return 'nrepl: no tests were found to run'
    return (f'nrepl: {total} test{"" if total == 1 else "s"}, {count("pass")} passed, '
            f'{count("fail")} failed, {count("error")} errored')


def nrepl_op(filename, message, timeout, autostart=True):
    reply = daemon_request(filename, {'kind': 'op', 'timeout': timeout, 'message': message},
                           autostart=autostart, timeout=timeout + DAEMON_REPLY_MARGIN)
    if reply.get('error'):
        raise ValueError(reply['error'])
    return reply['messages']


def nrepl_statuses(messages):
    return [state for message in messages for state in message.get('status') or []]


def local_file_path(url):
    """cider-nrepl answers with a URL; only a plain local file is jumpable."""
    if url.startswith('file:'):
        url = urllib.request.url2pathname(urllib.parse.urlparse(url).path)
    return url if os.path.isabs(url) else ''


def nrepl_var_location(filename, namespace, var):
    """Where a var is defined, as an absolute path and line, or neither."""
    try:
        messages = nrepl_op(filename, {'op': 'info', 'ns': namespace, 'sym': var},
                            NREPL_QUERY_TIMEOUT)
    except (OSError, ValueError):
        return '', None
    for message in messages:
        path = local_file_path(str(message.get('file') or ''))
        if path:
            return path, message.get('line')
    return '', None


def nrepl_load_namespaces(filename, namespaces):
    """Require each namespace, reporting which ones the server could not load."""
    loaded, refused = [], []
    for namespace in namespaces:
        messages = nrepl_op(filename, {'op': 'eval', 'ns': 'user',
                                       'code': "(require '" + namespace + ")"},
                            NREPL_QUERY_TIMEOUT)
        statuses = nrepl_statuses(messages)
        if 'eval-error' in statuses or 'error' in statuses:
            reason = ''.join(message.get('ex', '') for message in messages)
            refused.append((namespace, test_text(reason)))
        else:
            loaded.append(namespace)
    return loaded, refused


def nrepl_test_message(verb, targets):
    """The var-query cider-nrepl expects for each of Conjure's four verbs."""
    if verb == 'rerun':
        return {'op': 'retest'}
    if verb == 'all':
        return {'op': 'test-var-query',
                'var-query': {'ns-query': {'project?': 'true', 'load-project-ns?': 'true'}}}
    if verb == 'namespace':
        return {'op': 'test-var-query', 'var-query': {'ns-query': {'exactly': list(targets)}}}
    if verb == 'var':
        return {'op': 'test-var-query',
                'var-query': {'ns-query': {'exactly': [targets[0].partition('/')[0]]},
                              'exactly': list(targets)}}
    raise ValueError(f'unknown test verb {verb!r}; expected var, namespace, all or rerun')


def nrepl_log_append(filename, text):
    """Best-effort: the log is a record, never a reason to fail a test run."""
    try:
        daemon_request(filename, {'kind': 'log', 'text': text}, autostart=False,
                       timeout=DAEMON_START_TIMEOUT)
    except (OSError, ValueError):
        pass


def nrepl_announce(session, client, message):
    print(message, flush=True)
    if session:
        push_command(session, client, 'nrepl-announce ' + quote(message))


def nrepl_test_report(filename, verb, session, client, targets):
    description = {'all': 'every namespace in the project',
                   'rerun': 'the previous failures'}.get(verb, ', '.join(targets))
    print('$ nrepl test ' + description, flush=True)
    if verb in ('var', 'namespace'):
        wanted = sorted({target.partition('/')[0] for target in targets})
        loaded, refused = nrepl_load_namespaces(filename, wanted)
        for namespace, reason in refused:
            print(f'; {namespace} did not load: {reason or "no reason given"}', flush=True)
        if not loaded:
            nrepl_announce(session, client,
                           f'nrepl: none of {", ".join(wanted)} could be loaded; expected a '
                           f'namespace on the classpath. evaluate the buffer first')
            return 1
        if verb == 'namespace':
            targets = loaded
    messages = nrepl_op(filename, nrepl_test_message(verb, targets), NREPL_TEST_TIMEOUT)
    statuses = nrepl_statuses(messages)
    if 'unknown-op' in statuses:
        nrepl_announce(session, client, NREPL_NO_TEST_OPS)
        return 1
    if 'namespace-not-found' in statuses:
        nrepl_announce(session, client,
                       f'nrepl: the server found no tests in {description}; expected a loaded '
                       f'test namespace. evaluate the buffer first')
        return 1
    results, summary = {}, {}
    for message in messages:
        results.update(message.get('results') or {})
        summary.update(message.get('summary') or {})
    locations, detail = {}, []
    for entry in test_failures(results):
        key = (entry.get('ns'), entry.get('var'))
        if key not in locations:
            locations[key] = nrepl_var_location(filename, *key)
        location = test_result_location(entry, *locations[key])
        print(test_failure_line(entry, location), flush=True)
        detail.append(test_failure_log(entry, location))
    text = test_summary_text(summary)
    nrepl_log_append(filename, LOG_SEPARATOR + '\n; ' + text + '\n' + ''.join(detail))
    nrepl_announce(session, client, text)
    return 1 if detail else 0


def nrepl_test_command(filename, session, client, verb, targets):
    """Gate on the server's op set, then hand :make something to run."""
    try:
        status = daemon_request(filename, {'kind': 'status'}, timeout=DAEMON_START_TIMEOUT * 4)
    except (OSError, ValueError) as error:
        print('fail ' + quote('nrepl: ' + str(error)))
        return 0
    if not status.get('connected'):
        print('fail ' + quote('nrepl: not connected: ' +
                              str(status.get('error') or 'reason unknown')))
        return 0
    required = 'retest' if verb == 'rerun' else 'test-var-query'
    if not nrepl_advertises(status.get('ops') or [], required):
        print('fail ' + quote(NREPL_NO_TEST_OPS.format(op=required)))
        return 0
    command = ['python3', os.path.abspath(__file__), 'nrepl-test', filename, verb,
               session, client, *targets]
    print('set-option local makecmd ' + quote(shlex.join(command)))
    print('make')
    return 0


def nrepl_test(filename, verb, session, client, targets):
    """Run tests over nREPL, printing what :make reads out of its buffer."""
    status = nrepl_test_report(filename, verb, session, client, targets)
    print(f'\n[exit {status}]', flush=True)
    return status


# --- Doc and source lookup ---------------------------------------------------
#
# The info op is the one piece of introspection both servers carry: Babashka's
# thirteen-op nREPL advertises it alongside lookup and eldoc, and so does a JVM
# server with cider-nrepl. Neither of these two commands is gated on middleware
# for that reason.
#
# clojure-lsp stays the primary lookup, on Space e and Space l. These answer for
# what is only in the running image, so a var the editor cannot see statically
# still has a docstring and a definition.

NREPL_DOC_TIMEOUT = 20.0
NREPL_NO_INFO = ('nrepl: the server knows no {symbol} in {namespace}; expected a var loaded '
                 'into the running REPL. evaluate the buffer first, or use Space e for the '
                 'static answer')


def nrepl_info_reply(messages):
    """One info reply, which arrives as a body message and a status message."""
    merged = {}
    for message in messages:
        merged.update(message)
    return merged


def nrepl_info_found(info):
    """Both servers answer an unknown symbol with a reply carrying no var."""
    return bool(info.get('name'))


def nrepl_qualified_name(info):
    return '/'.join(str(part) for part in [info.get('ns'), info.get('name')] if part)


def nrepl_doc_text(info):
    """Conjure's shape: the qualified name, the arglists, then the docstring."""
    arglists = str(info.get('arglists-str') or '').strip()
    doc = str(info.get('doc') or '').strip()
    lines = [nrepl_qualified_name(info)]
    lines.extend(arglists.split('\n') if arglists else [])
    lines.append('')
    lines.extend(doc.split('\n') if doc else ['no docstring'])
    return '\n'.join(lines)


def nrepl_doc_summary(info):
    """The status line stays useful once the info box is dismissed."""
    arglists = ' '.join(str(info.get('arglists-str') or '').split())
    return ' '.join(part for part in ['nrepl:', nrepl_qualified_name(info), arglists] if part)


def nrepl_definition(info):
    """Where the editor should jump, or why the var cannot be jumped to."""
    url = str(info.get('file') or '')
    path = local_file_path(url)
    if path and os.path.isfile(path):
        # Babashka reports the file without a line; the top of it is still the
        # right answer, and a wrong line would be worse than the first one.
        return path, int(info.get('line') or 1), ''
    if not url or url == 'NO_SOURCE_PATH':
        return '', None, 'was defined at the REPL and has no file to open'
    return '', None, f'is defined in {url}, which is not a file on disk'


def nrepl_lookup(filename, namespace, symbol):
    """The info reply for one symbol, or the Kakoune failure that replaces it."""
    if not filename:
        return None, ('nrepl: this buffer has no file; expected a saved Clojure file. '
                      'write it first')
    try:
        messages = nrepl_op(filename, {'op': 'info', 'ns': namespace or 'user', 'sym': symbol},
                            NREPL_DOC_TIMEOUT)
    except (OSError, ValueError) as error:
        return None, 'nrepl: ' + ' '.join(str(error).split())
    if 'unknown-op' in nrepl_statuses(messages):
        return None, ('nrepl: this server has no info op; expected an nREPL that answers '
                      'introspection. use Space e for the static answer')
    return nrepl_info_reply(messages), ''


def nrepl_doc(filename, namespace, line, column, symbol):
    """Print the Kakoune commands that put the docstring beside the cursor."""
    info, failure = nrepl_lookup(filename, namespace, symbol)
    if failure:
        print('fail ' + quote(failure))
        return 0
    if not nrepl_info_found(info):
        print('nrepl-announce ' + quote(NREPL_NO_INFO.format(symbol=symbol,
                                                             namespace=namespace or 'user')))
        return 0
    print(f'info -anchor {int(line)}.{int(column)} -title ' + quote('nrepl doc') +
          ' -- ' + quote(nrepl_doc_text(info)))
    print('nrepl-announce ' + quote(nrepl_doc_summary(info)))
    return 0


def nrepl_source(filename, namespace, symbol):
    """Print the Kakoune commands that open the definition the REPL knows."""
    info, failure = nrepl_lookup(filename, namespace, symbol)
    if failure:
        print('fail ' + quote(failure))
        return 0
    if not nrepl_info_found(info):
        print('nrepl-announce ' + quote(NREPL_NO_INFO.format(symbol=symbol,
                                                             namespace=namespace or 'user')))
        return 0
    path, line, reason = nrepl_definition(info)
    name = nrepl_qualified_name(info)
    if not path:
        print('nrepl-announce ' + quote(f'nrepl: {name} {reason}'))
        return 0
    print(f'edit -existing {quote(path)} {line} 1')
    print('nrepl-announce ' + quote(f'nrepl: {name} at {path}:{line}'))
    return 0


# --- Namespace refresh -------------------------------------------------------
#
# cider-nrepl's refresh middleware, which inlines clojure.tools.namespace and so
# needs no dependency beyond the middleware projects.kak already injects.
#
# A refresh reloads every changed file on the classpath, which on a large
# project takes far longer than an editor may be held for. The reload therefore
# runs in a detached process that pushes its summary back to the status line,
# the way a test run does, and the timeout is generous rather than interactive.
# Failure is the interesting case: the summary names the namespace that refused
# to load and the exception it raised, and the log keeps every cause.

NREPL_REFRESH_OPS = {'changed': 'refresh', 'all': 'refresh-all', 'clear': 'refresh-clear'}
NREPL_REFRESH_LABELS = {'changed': 'nrepl: reloading the namespaces that changed',
                        'all': 'nrepl: reloading every namespace',
                        'clear': 'nrepl: clearing the refresh cache'}
# Long enough for a cold reload of a large project, and bounded so a reload that
# wedges the server frees the daemon's session again rather than holding it.
NREPL_REFRESH_TIMEOUT = 600.0
NREPL_NO_REFRESH_OPS = ('nrepl: this server has no {op} op; expected a JVM REPL with '
                        "cider-nrepl. Babashka's nREPL carries no refresh middleware, so "
                        'start the project REPL with :project-repl')


def refresh_causes(error):
    """cider answers with analysed exception maps; anything else is its text."""
    if isinstance(error, dict):
        error = [error]
    if isinstance(error, str):
        return [test_text(error)] if error.strip() else []
    causes = []
    for cause in error or []:
        if not isinstance(cause, dict):
            causes.append(test_text(cause))
            continue
        where = f' ({cause.get("file")}:{cause.get("line")})' if cause.get('file') else ''
        causes.append(test_text(cause.get('class')) + ': ' +
                      (test_text(cause.get('message')) or 'no message') + where)
    return causes


def refresh_report(verb, messages):
    """One refresh reply, as a status line and as the log block behind it."""
    reloaded, causes, printed, namespace = [], [], [], ''
    for message in messages:
        reloaded.extend(message.get('reloading') or [])
        if message.get('error'):
            causes.extend(refresh_causes(message['error']))
        if message.get('error-ns'):
            namespace = str(message['error-ns'])
        if message.get('err'):
            printed.append(str(message['err']))
    detail = [f';   reloading: {", ".join(reloaded)}'] if reloaded else []
    detail.extend(f';   cause:     {cause}' for cause in causes)
    detail.extend(f';   err:       {line}' for text in printed
                  for line in text.rstrip('\n').split('\n'))
    if 'error' in nrepl_statuses(messages) or causes:
        summary = (f'nrepl: refresh failed in {namespace or "an unnamed namespace"}: '
                   f'{causes[0] if causes else "no reason given"} '
                   f'(:nrepl-log-open for the detail)')
    elif verb == 'clear':
        summary = 'nrepl: the refresh cache is cleared; the next refresh reloads everything'
    elif reloaded:
        summary = (f'nrepl: refreshed {len(reloaded)} '
                   f'namespace{"" if len(reloaded) == 1 else "s"}: {", ".join(reloaded)}')
    else:
        summary = 'nrepl: refresh found nothing to reload; every namespace is current'
    return summary, ''.join(line + '\n' for line in detail)


def nrepl_refresh(filename, session, client, verb):
    """Reload over nREPL, reporting the reload error rather than swallowing it."""
    op = NREPL_REFRESH_OPS[verb]
    try:
        messages = nrepl_op(filename, {'op': op}, NREPL_REFRESH_TIMEOUT)
    except (OSError, ValueError) as error:
        nrepl_announce(session, client, 'nrepl: ' + ' '.join(str(error).split()))
        return 1
    if 'unknown-op' in nrepl_statuses(messages):
        nrepl_announce(session, client, NREPL_NO_REFRESH_OPS.format(op=op))
        return 1
    summary, detail = refresh_report(verb, messages)
    nrepl_log_append(filename, LOG_SEPARATOR + '\n; ' + summary + '\n' + detail)
    nrepl_announce(session, client, summary)
    return 1 if detail and 'failed' in summary else 0


def nrepl_refresh_command(filename, session, client, verb):
    """Gate on the server's op set, then reload without holding the editor."""
    op = NREPL_REFRESH_OPS.get(verb)
    if not op:
        raise ValueError(f'unknown refresh verb {verb!r}; expected changed, all or clear')
    try:
        status = daemon_request(filename, {'kind': 'status'}, timeout=DAEMON_START_TIMEOUT * 4)
    except (OSError, ValueError) as error:
        print('fail ' + quote('nrepl: ' + str(error)))
        return 0
    if not status.get('connected'):
        print('fail ' + quote('nrepl: not connected: ' +
                              str(status.get('error') or 'reason unknown')))
        return 0
    if not nrepl_advertises(status.get('ops') or [], op):
        print('nrepl-announce ' + quote(NREPL_NO_REFRESH_OPS.format(op=op)))
        return 0
    subprocess.Popen(['python3', os.path.abspath(__file__), 'nrepl-refresh', filename,
                      session, client, verb],
                     stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                     stderr=subprocess.DEVNULL, start_new_session=True, close_fds=True)
    print('nrepl-announce ' + quote(NREPL_REFRESH_LABELS[verb]))
    return 0


# --- Runtime completion ------------------------------------------------------
#
# clojure-lsp already answers from static analysis, so this fills the one gap it
# cannot: vars that exist only because something was evaluated into the running
# image. It never starts a daemon and never waits long, because it runs on every
# idle keystroke.


def clojure_completion_prefix(line, column):
    """The symbol being typed, with the 1-based column its first byte sits at."""
    typed = line.encode()[:max(int(column) - 1, 0)]
    start = len(typed)
    while start > 0 and typed[start - 1] not in CLOJURE_SYMBOL_BREAK:
        start -= 1
    while start < len(typed) and typed[start] in CLOJURE_SYMBOL_PREFIX:
        start += 1
    return typed[start:].decode('utf-8', 'replace'), start + 1


def completion_escape(text):
    """A candidate field is split on unescaped | in the option value."""
    return str(text).replace('\\', '\\\\').replace('|', '\\|')


def completion_menu(candidate):
    """Menu text is markup, so an unescaped brace would name a face."""
    menu = ' '.join(str(part) for part in [candidate.get('ns'), candidate.get('type')] if part)
    return menu.replace('\\', '\\\\').replace('{', '\\{')


def completion_option(line, column, timestamp, candidates, limit):
    """The `completions` value Kakoune's option= completer reads."""
    option = [f'{line}.{column}@{timestamp}']
    for candidate in list(candidates)[:max(int(limit), 0)]:
        option.append('|'.join([completion_escape(candidate.get('candidate', '')), '',
                                completion_escape(completion_menu(candidate))]))
    return option


def nrepl_complete(filename, bufname, session, namespace, line, column, timestamp, limit, text):
    candidates = []
    prefix, anchor = clojure_completion_prefix(text, column)
    if prefix:
        try:
            messages = nrepl_op(filename, {'op': 'complete', 'ns': namespace or 'user',
                                           'prefix': prefix},
                                NREPL_COMPLETE_TIMEOUT, autostart=False)
        except (OSError, ValueError):
            return 0
        if 'unknown-op' in nrepl_statuses(messages):
            return 0
        for message in messages:
            candidates.extend(message.get('completions') or [])
    option = completion_option(line, anchor, timestamp, candidates, limit)
    push_command(session, '', 'evaluate-commands -buffer ' + quote(bufname) + ' ' +
                 quote('set-option buffer nrepl_completions ' + ' '.join(map(quote, option))))
    return 0


def push_command(session, client, command):
    """Run one command inside a Kakoune session, from outside the editor."""
    if client:
        command = 'evaluate-commands -try-client ' + quote(client) + ' ' + quote(command)
    try:
        subprocess.run(['kak', '-p', session], input=command, text=True, timeout=10,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)
    except (OSError, subprocess.SubprocessError):
        pass


def push_to_kakoune(session, client, fields):
    push_command(session, client,
                 'nrepl-handle-result ' + ' '.join(quote(field) for field in fields))


def nrepl_client(action, args):
    if action == 'nrepl-daemon':
        return NreplDaemon(args[0]).serve()
    filename = args[0]
    # These three own their own output: a Kakoune command, the *make* buffer and
    # a pushed set-option. They never fall through to the JSON reply below.
    if action == 'nrepl-test-command':
        return nrepl_test_command(filename, args[1], args[2], args[3], args[4:])
    if action == 'nrepl-test':
        return nrepl_test(filename, args[1], args[2], args[3], args[4:])
    if action == 'nrepl-complete':
        return nrepl_complete(filename, *args[1:])
    if action == 'nrepl-doc':
        return nrepl_doc(filename, args[1], args[2], args[3], args[4])
    if action == 'nrepl-source':
        return nrepl_source(filename, args[1], args[2])
    if action == 'nrepl-refresh-command':
        return nrepl_refresh_command(filename, args[1], args[2], args[3])
    if action == 'nrepl-refresh':
        return nrepl_refresh(filename, args[1], args[2], args[3])
    if action == 'nrepl-status':
        reply = daemon_request(filename, {'kind': 'status'}, timeout=DAEMON_START_TIMEOUT * 4)
        reply['capabilities'] = nrepl_capabilities(reply.get('ops') or [])
    elif action == 'nrepl-shutdown':
        reply = daemon_request(filename, {'kind': 'shutdown'}, autostart=False,
                               timeout=DAEMON_START_TIMEOUT)
    elif action == 'nrepl-interrupt':
        reply = daemon_request(filename, {'kind': 'interrupt'}, timeout=DAEMON_START_TIMEOUT * 4)
    elif action == 'nrepl-op':
        pairs, timeout = nrepl_timeout(args[2:])
        reply = daemon_request(filename, {'kind': 'op', 'timeout': timeout,
                                          'message': nrepl_message(args[1], pairs)},
                               timeout=timeout + DAEMON_REPLY_MARGIN)
    elif action == 'nrepl-eval':
        session, client, namespace, line, column, code = args[1:7]
        reply = daemon_request(filename, {'kind': 'eval', 'code': code, 'ns': namespace,
                                          'file': filename, 'line': line, 'column': column,
                                          'kak-session': session, 'kak-client': client},
                               timeout=DAEMON_START_TIMEOUT * 4)
    else:
        raise ValueError(f'unknown nREPL action {action!r}; expected one of nrepl-daemon, nrepl-status, '
                         f'nrepl-op, nrepl-eval, nrepl-test, nrepl-test-command, nrepl-complete, '
                         f'nrepl-doc, nrepl-source, nrepl-refresh, nrepl-refresh-command, '
                         f'nrepl-interrupt, nrepl-shutdown')
    if reply.get('error') and action != 'nrepl-status':
        raise ValueError(reply['error'])
    if action == 'nrepl-eval':
        print(reply['id'])
    elif action == 'nrepl-op':
        print(json.dumps(reply['messages']))
    else:
        print(json.dumps(reply))
    return 0


def main():
    action, *args = sys.argv[1:]
    if action == 'root':
        print(project_root())
    elif action == 'move':
        move_lines(int(args[0]), args[1], int(args[2]), args[3])
    elif action == 'recent':
        recent(args[0], args[1], int(args[2]))
    elif action == 'build':
        return build(args[0], args[1:])
    elif action == 'bb-server':
        return bb_server(args[0])
    elif action == 'format':
        return format_code(*args)
    elif action == 'grep-open':
        match = re.match(r'^(.+?):([1-9]\d*):([1-9]\d*):', args[1])
        if not match:
            print('fail ' + quote('Select a grep result from the completion menu.'))
        else:
            filename, row, col = match.groups()
            print(f'edit -existing {quote(Path(args[0]) / filename)} {row} {col}')
    elif action == 'clojure-form':
        return clojure_form(args[0], args[1], args[2])
    elif action == 'clojure-test-var':
        name = clojure_test_var(sys.stdin.read())
        if name:
            print(name)
    elif action == 'nrepl-log-relay':
        nrepl_log_relay(args[0], args[1:])
    elif action.startswith('nrepl-'):
        return nrepl_client(action, args)
    elif action == 'zls':
        zig = os.environ['kak_opt_zig_command']
        zls = str(Path.home() / '.zvm/bin/zls')
        if not os.access(zls, os.X_OK):
            zls = 'zls'
        print('[zls]\ncommand = ' + json.dumps(zls))
        print('root_globs = ["build.zig", "build.zig.zon", ".git"]')
        print('settings_section = "zls"\n[zls.settings.zls]\nenable_build_on_save = true')
        if Path(zig).is_absolute():
            print('zig_exe_path = ' + json.dumps(zig))


if __name__ == '__main__':
    try:
        sys.exit(main() or 0)
    except (OSError, ValueError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
