#!/usr/bin/env python3
"""Small, independently testable helpers for the Kakoune configuration."""
import fcntl
import glob
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import signal
import subprocess
import sys
import tempfile


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
    """Publish Babashka's ephemeral port for rep, then remove our port file."""
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
    if filetype == 'zig':
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
    elif action == 'rep':
        binary, root, filename, namespace, descriptions, *selections = args
        port = '@.nrepl-port@' + (filename or str(Path(root) / '.'))
        # Selection text is document-ordered; descriptors put the main first.
        locations = sorted(descriptions.split(), key=lambda s: min(
            tuple(map(int, endpoint.split('.'))) for endpoint in s.split(',')))
        status = 0
        for code, desc in zip(selections, locations):
            row, col = min(tuple(map(int, point.split('.'))) for point in desc.split(','))
            ns = 'user' if re.match(r'\s*\(ns\s', code) else namespace
            print(f'{ns}=> {code}', flush=True)
            result = subprocess.run([binary, '--port=' + port, '--namespace=' + ns,
                                     f'--line={filename}:{row}:{col}', '--', code], cwd=root)
            status = status or result.returncode
        print(f'\n[exit {status}]', flush=True)
        return status
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
