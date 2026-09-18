#!/usr/bin/env python3
import concurrent.futures
import importlib.util
import json
import os
from pathlib import Path
import re
import socket
import subprocess
import tempfile
import threading
import time
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('support', ROOT / 'support.py')
support = importlib.util.module_from_spec(spec)
spec.loader.exec_module(support)


def q(s):
    return support.quote(s)


class Helpers(unittest.TestCase):
    def test_roots_and_fallback(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'src').mkdir()
            (root / 'deps.edn').touch()
            self.assertEqual(support.root_for(root/'src/file.clj', ['deps.edn']), root)
            (root / 'gleam.toml').touch()
            self.assertEqual(support.root_for(root/'src/file.gleam', ['gleam.toml']), root)
            self.assertEqual(support.root_for(root/'src/file.ml', ['dune-project']), root/'src')
            (root / 'example.opam').touch()
            self.assertEqual(support.root_for(root/'src/file.ml', ['*.opam']), root)

    def test_recent_concurrent_writers(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            paths = [root / str(n) for n in range(24)]
            for p in paths:
                p.touch()
            def update(p):
                subprocess.run(['python3', str(ROOT/'support.py'), 'recent', str(root/'mru'), str(p), '30'], check=True)
            with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
                list(pool.map(update, paths))
            self.assertEqual(set((root/'mru').read_text().splitlines()), set(map(str, paths)))
            update(paths[0])
            self.assertEqual((root/'mru').read_text().splitlines()[0], str(paths[0]))

    def test_diagnostics(self):
        self.assertEqual(support.normalize('src/a.zig:3:7: error: broken\n', '/tmp/project'),
                         '/tmp/project/src/a.zig:3:7: error: broken\n')
        self.assertEqual(support.normalize('File "lib/a.ml", line 2, characters 4-8:\n', '/tmp/project'),
                         '/tmp/project/lib/a.ml:2:5: error: OCaml diagnostic\n')


class KakouneSession(unittest.TestCase):
    """A real client and window, so filetype hooks and window options apply."""

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='kak-test-')
        self.addCleanup(self.temp.cleanup)
        self.path = Path(self.temp.name)

    def start(self, script, asynchronous=False):
        prelude = f'''rename-client test
remove-hooks global clipboard
set-option global recent_files_path {q(self.path/'mru')}
lsp-disable
define-command -override lsp-formatting-sync %{{ nop }}
'''
        end = f'''buffer *debug*
write {q(self.path/'debug')}
quit!
'''
        for name in ['debug', 'moved']:
            (self.path/name).unlink(missing_ok=True)
        (self.path/'script.kak').write_text(prelude + script + ('' if asynchronous else end))
        command = ['kak', '-ui', 'dummy', '-s', self.path.name, '-e', f'source {q(self.path/"script.kak")}']
        if asynchronous:
            proc = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            def stop():
                if proc.poll() is None:
                    proc.kill()
                proc.wait(timeout=5)
            self.addCleanup(stop)
            self.addCleanup(proc.stdin.close)
            self.addCleanup(proc.stdout.close)
            self.addCleanup(proc.stderr.close)
            return proc
        result = subprocess.run(command, input='', text=True, capture_output=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stderr)
        debug = (self.path/'debug').read_text()
        self.assertNotIn('error while parsing', debug)
        self.assertNotIn('ERROR:', debug)
        return debug

    def send(self, commands):
        subprocess.run(['kak', '-p', self.path.name], input='evaluate-commands -client test %{'+commands+'}', text=True, check=True)


class Kakoune(KakouneSession):
    def test_move_selections_and_undo(self):
        cases = [
            ('1.1,1.1 3.1,3.1', 'down', 'B\nA\nD\nC\n'),
            ('2.1,2.1 4.1,4.1', 'up', 'B\nA\nD\nC\n'),
            ('1.1,1.1 2.1,2.1', 'down', 'C\nA\nB\nD\n'),
            ('1.1,1.1 3.1,3.1', 'up', 'A\nC\nB\nD\n'),
            ('2.1,2.1 4.1,4.1', 'down', 'A\nC\nB\nD\n'),
            ('1.1,4.1', 'down', 'A\nB\nC\nD\n'),
            ('3.1,2.1', 'up', 'B\nC\nA\nD\n'),
        ]
        for number, (selections, direction, expected) in enumerate(cases):
            script = f'''edit -scratch move-test
execute-keys 'iA<ret>B<ret>C<ret>D<esc>'
select {selections}
try %{{ move-lines-{direction} }} catch %{{ echo -debug ERROR: %val{{error}} }}
write {q(self.path/'moved')}
'''
            self.start(script)
            self.assertEqual((self.path/'moved').read_text(), expected, str(number))

    def test_move_preserves_registers_and_one_undo(self):
        source = self.path/'lines.txt'
        source.write_text('A\nB\nC\nD\n')
        debug = self.start(f'''edit {q(source)}
set-register m untouched
set-register '"' clipboard
select 3.1,3.1 1.1,1.1
move-lines-down
echo -debug REGISTERS %reg{{m}} %reg{{"}}
echo -debug SELECTIONS %val{{selections_desc}}
execute-keys u
write {q(source)}
''')
        self.assertIn('REGISTERS untouched clipboard', debug)
        self.assertIn('SELECTIONS 4.1,4.1 2.1,2.1', debug)
        self.assertEqual(source.read_text(), 'A\nB\nC\nD\n')

    def test_editing_toggles(self):
        source = self.path/'sample.clj'
        source.write_text('(let [x 1] (+ x 2))\n')
        debug = self.start(f'''edit {q(source)}
echo -debug PARINFER %opt{{parinfer_enabled}}
parinfer-toggle
echo -debug DISABLED %opt{{parinfer_enabled}}
parinfer-toggle
set-option buffer filetype text
echo -debug RESTORED %opt{{auto_close_trigger}}
try %{{ toggle-inlay-diagnostics; toggle-inlay-diagnostics; toggle-type-hints; toggle-type-hints }} catch %{{ echo -debug ERROR: %val{{error}} }}
''')
        self.assertIn('PARINFER true', debug)
        self.assertIn('DISABLED false', debug)
        self.assertNotIn('RESTORED <a-k>(?!)', debug)

    def test_filetype_reset_and_dune(self):
        dune = self.path/'dune'
        dune.write_text('(library (name hello))\n')
        opam = self.path/'hello.opam'
        opam.write_text('opam-version: "2.0"\n')
        gleam = self.path/'main.gleam'
        gleam.write_text('pub fn main() { Nil }\n')
        (self.path/'gleam.toml').write_text('name = "example"\nversion = "1.0.0"\n')
        debug = self.start(f'''edit -scratch options
set-option buffer filetype zig
set-option buffer filetype ocaml
echo -debug RESET %opt{{run_command}} %opt{{test_file_command}} %opt{{indentwidth}}
edit {q(dune)}
echo -debug DUNE %opt{{filetype}} %opt{{build_command}}
edit {q(opam)}
echo -debug OPAM %opt{{filetype}} %opt{{comment_line}}
edit {q(gleam)}
echo -debug GLEAM %opt{{filetype}} %opt{{build_command}} %opt{{test_command}} %opt{{run_command}}
echo -debug GLEAM-LSP %opt{{lsp_servers}}
''')
        self.assertIn('RESET 2', debug)
        self.assertIn('DUNE lisp opam exec -- dune build', debug)
        self.assertIn('OPAM opam #', debug)
        self.assertIn('GLEAM gleam gleam build gleam test gleam run', debug)
        self.assertIn('[gleam]', debug)
        self.assertIn('command = "gleam"', debug)
        self.assertIn('args = ["lsp"]', debug)
        self.assertIn('root_globs = ["gleam.toml"]', debug)

    def test_build_saves_project_and_jumps(self):
        project = self.path/"project's files"
        project.mkdir()
        (project/'.git').mkdir()
        source = project/'main.txt'
        source.write_text('old\n')
        other = self.path/'outside.txt'
        other.write_text('outside\n')
        builder = project/'builder.py'
        builder.write_text("from pathlib import Path\nprint('main.txt:1:1: error: ' + Path('main.txt').read_text().strip())\n")
        proc = self.start(f'''edit {q(other)}
execute-keys '%cunsaved outside<esc>'
edit {q(source)}
execute-keys '%cnew<esc>'
set-option buffer build_command python3 {q(builder)}
try %{{ build }} catch %{{ echo -debug ERROR: %val{{error}} }}
''', asynchronous=True)
        time.sleep(.5)
        self.send(f'''try %{{ buffer *make*; write {q(self.path/'output')}; make-next-error; echo -debug JUMP %val{{buffile}} }} catch %{{ echo -debug ERROR: %val{{error}} }}
buffer *debug*
write {q(self.path/'debug')}
quit!
''')
        proc.communicate(timeout=10)
        debug = (self.path/'debug').read_text()
        self.assertNotIn('ERROR:', debug)
        self.assertEqual(source.read_text(), 'new\n')
        self.assertEqual(other.read_text(), 'outside\n')
        self.assertIn(str(source)+':1:1: error: new', (self.path/'output').read_text())
        self.assertIn('JUMP '+str(source), debug)

    def test_native_formatting_and_invalid_input(self):
        for suffix, text, expected, config in [
            ('clj', '(let [x 1]\n(+ x 2))\n', '(let [x 1]\n  (+ x 2))\n', {}),
            ('gleam', 'pub fn main(){Nil}\n', 'pub fn main() {\n  Nil\n}\n', {}),
            ('zig', 'const value=1;\n', 'const value = 1;\n', {}),
            ('ml', 'let value=1\n', 'let value = 1\n', {'.ocamlformat': 'version=0.29.0\n'}),
        ]:
            with self.subTest(suffix=suffix):
                for name, value in config.items():
                    (self.path/name).write_text(value)
                source = self.path/('format.'+suffix)
                source.write_text(text)
                self.start(f'''edit {q(source)}
try %{{ code-format-sync }} catch %{{ echo -debug ERROR: %val{{error}} }}
evaluate-commands -no-hooks %{{ write {q(source)} }}
''')
                self.assertEqual(source.read_text(), expected)
        source = self.path/'invalid.clj'
        source.write_text('(let [x 1]\n')
        self.start(f'''edit {q(source)}
parinfer-off
try %{{ code-format-sync }}
evaluate-commands -no-hooks %{{ write {q(source)} }}
''')
        self.assertEqual(source.read_text(), '(let [x 1]\n')

    def test_clojure_repl_command_deps_edn_injects_cider_middleware(self):
        (self.path/'deps.edn').write_text('{:paths ["src"]}\n')
        source = self.path/'core.clj'
        source.write_text('(ns core)\n')
        debug = self.start(f"""edit {q(source)}
echo -debug CLJ %opt{{repl_command}}
""")
        self.assertIn('cider/cider-nrepl {:mvn/version "0.62.2"}', debug)
        self.assertIn('refactor-nrepl/refactor-nrepl {:mvn/version "3.14.0"}', debug)
        self.assertIn('nrepl/nrepl {:mvn/version "1.7.0"}', debug)
        self.assertIn('--middleware [cider.nrepl/cider-middleware,refactor-nrepl.middleware/wrap-refactor]', debug)
        self.assertIn('--interactive', debug)

    def test_clojure_repl_command_leiningen_injects_cider_plugins(self):
        (self.path/'project.clj').write_text('(defproject example "0.1.0")\n')
        source = self.path/'core.clj'
        source.write_text('(ns core)\n')
        debug = self.start(f"""edit {q(source)}
echo -debug CLJ %opt{{repl_command}}
""")
        self.assertIn('lein update-in :dependencies conj [nrepl/nrepl "1.7.0"]', debug)
        self.assertIn('update-in :plugins conj [cider/cider-nrepl "0.62.2"]', debug)
        self.assertIn('update-in :plugins conj [refactor-nrepl/refactor-nrepl "3.14.0"]', debug)
        self.assertIn('-- repl', debug)
        self.assertNotIn(':headless', debug)

    def test_clojure_repl_command_babashka_has_no_cider(self):
        (self.path/'bb.edn').write_text('{}\n')
        source = self.path/'core.clj'
        source.write_text('(ns core)\n')
        debug = self.start(f"""edit {q(source)}
echo -debug CLJ %opt{{repl_command}}
""")
        self.assertIn('bb-server', debug)
        self.assertNotIn('cider', debug)

    def test_nrepl_result_payload_reaches_the_kakoune_client(self):
        binary = Path.home()/'.local/bin/bb'
        if not binary.exists():
            self.skipTest('Babashka not installed')
        (self.path/'bb.edn').write_text('{}')
        server = subprocess.Popen(['python3', str(ROOT/'support.py'), 'bb-server', str(binary)], cwd=self.path,
                                  stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        self.addCleanup(lambda: server.wait(timeout=10))
        self.addCleanup(server.terminate)
        for _ in range(500):
            if (self.path/'.nrepl-port').exists():
                break
            time.sleep(.02)
        def stop_daemon():
            subprocess.run(['python3', str(ROOT/'support.py'), 'nrepl-shutdown', str(self.path/'form.clj')],
                           capture_output=True, text=True, timeout=15)
            for path in support.nrepl_paths(support.nrepl_root(self.path/'form.clj')).values():
                Path(path).unlink(missing_ok=True)
        self.addCleanup(stop_daemon)
        source = self.path/'form.clj'
        source.write_text('(ns demo)\n')
        proc = self.start('''define-command -override -params 8 nrepl-handle-result %{
    echo -debug "RESULT %arg{1}|%arg{2}|%arg{3}|%arg{4}|%arg{5}|%arg{6}|%arg{7}|%arg{8}"
}
''' + f'edit {q(source)}\n', asynchronous=True)
        time.sleep(.5)
        subprocess.run(['python3', str(ROOT/'support.py'), 'nrepl-op', str(source), 'eval', 'code=(ns demo)'],
                       capture_output=True, text=True, timeout=30, check=True)
        code = '(do (println "noise") {:a "it\'s}"})'
        result = subprocess.run(['python3', str(ROOT/'support.py'), 'nrepl-eval', str(source),
                                 self.path.name, 'test', 'demo', '7', '3', code],
                                capture_output=True, text=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stderr)
        time.sleep(1.5)
        self.send(f'''buffer *debug*
write {q(self.path/'debug')}
quit!
''')
        proc.communicate(timeout=10)
        debug = (self.path/'debug').read_text()
        self.assertIn('RESULT ', debug)
        line = [l for l in debug.splitlines() if l.startswith('RESULT ')][0]
        fields = line[len('RESULT '):].split('|')
        self.assertEqual(fields[1:], ['ok', 'demo', '{:a "it\'s}"}', '', str(source), '7', '3'])


class Bencode(unittest.TestCase):
    def test_roundtrip_nested_structures_preserves_values(self):
        message = {'op': 'eval', 'code': '(+ 1 2)', 'line': 12,
                   'status': ['done', 'eval-error'], 'nested': {'a': [1, 'two']}}
        decoded, rest = support.bdecode(support.bencode(message))
        self.assertEqual(rest, b'')
        self.assertEqual(decoded, [message])

    def test_roundtrip_empty_containers_and_negative_integers(self):
        for value in [{}, [], '', -17, 0, ['', {}, [[]]]]:
            with self.subTest(value=value):
                decoded, rest = support.bdecode(support.bencode(value))
                self.assertEqual((decoded, rest), ([value], b''))

    def test_decode_frame_split_across_reads_returns_remainder(self):
        frame = support.bencode({'id': '1', 'value': '42'})
        for cut in range(1, len(frame)):
            with self.subTest(cut=cut):
                decoded, rest = support.bdecode(frame[:cut])
                self.assertEqual(decoded, [])
                self.assertEqual(rest, frame[:cut])
                decoded, rest = support.bdecode(rest + frame[cut:])
                self.assertEqual(decoded, [{'id': '1', 'value': '42'}])
                self.assertEqual(rest, b'')

    def test_decode_two_frames_with_trailing_partial_keeps_partial(self):
        first = support.bencode({'id': '1'})
        second = support.bencode({'id': '2'})
        decoded, rest = support.bdecode(first + second + b'd2:id')
        self.assertEqual(decoded, [{'id': '1'}, {'id': '2'}])
        self.assertEqual(rest, b'd2:id')

    def test_decode_utf8_payload_returns_text(self):
        decoded, rest = support.bdecode(support.bencode({'value': '"λ"'}))
        self.assertEqual((decoded, rest), ([{'value': '"λ"'}], b''))

    def test_decode_invalid_marker_raises_value_error(self):
        with self.assertRaises(ValueError):
            support.bdecode(b'x3:abc')

    def test_encode_unsupported_type_raises_value_error(self):
        with self.assertRaises(ValueError):
            support.bencode(3.5)


class NreplArguments(unittest.TestCase):
    def test_timeout_argument_is_split_out_of_the_message_pairs(self):
        pairs, timeout = support.nrepl_timeout(['code=(+ 1 1)', 'timeout=2.5', 'ns=user'])
        self.assertEqual(pairs, ['code=(+ 1 1)', 'ns=user'])
        self.assertEqual(timeout, 2.5)

    def test_absent_timeout_argument_keeps_the_daemon_default(self):
        pairs, timeout = support.nrepl_timeout(['code=(+ 1 1)'])
        self.assertEqual(pairs, ['code=(+ 1 1)'])
        self.assertEqual(timeout, support.DAEMON_REQUEST_TIMEOUT)

    def test_a_value_containing_an_equals_sign_is_not_mistaken_for_a_timeout(self):
        pairs, timeout = support.nrepl_timeout(['code=(= 1 1)'])
        self.assertEqual(pairs, ['code=(= 1 1)'])
        self.assertEqual(timeout, support.DAEMON_REQUEST_TIMEOUT)

    def test_a_timeout_that_is_not_a_positive_number_is_rejected(self):
        for value in ['timeout=nope', 'timeout=0', 'timeout=-1']:
            with self.subTest(value=value):
                with self.assertRaises(ValueError):
                    support.nrepl_timeout([value])


class Nrepl(unittest.TestCase):
    """Live checks against a Babashka nREPL server."""

    def setUp(self):
        binary = Path.home()/'.local/bin/bb'
        if not binary.exists():
            self.skipTest('Babashka not installed')
        self.binary = binary
        self.temp = tempfile.TemporaryDirectory(prefix='kak-nrepl-test-')
        self.addCleanup(self.temp.cleanup)
        self.path = Path(self.temp.name)
        self.source = self.path/'src'/'demo.clj'
        self.source.parent.mkdir()
        self.source.write_text('(ns demo)\n')
        (self.path/'bb.edn').write_text('{}')
        self.addCleanup(self.stop_daemon)

    def support_command(self, *args, timeout=30):
        return subprocess.run(['python3', str(ROOT/'support.py'), *map(str, args)],
                              capture_output=True, text=True, timeout=timeout)

    def stop_daemon(self):
        self.support_command('nrepl-shutdown', self.source, timeout=15)
        for path in support.nrepl_paths(support.nrepl_root(self.source)).values():
            Path(path).unlink(missing_ok=True)

    def start_server(self):
        server = subprocess.Popen(['python3', str(ROOT/'support.py'), 'bb-server', str(self.binary)],
                                  cwd=self.path, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        self.addCleanup(lambda: server.wait(timeout=10))
        self.addCleanup(server.terminate)
        for _ in range(500):
            if (self.path/'.nrepl-port').exists():
                return server
            time.sleep(.02)
        self.fail('Babashka did not publish .nrepl-port')

    def evaluate(self, code, timeout=30):
        result = self.support_command('nrepl-op', self.source, 'eval', 'code=' + code, timeout=timeout)
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout)

    def status(self):
        result = self.support_command('nrepl-status', self.source)
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout)

    def test_daemon_keeps_one_session_so_state_survives_evaluations(self):
        self.start_server()
        self.evaluate('(def remembered 7)')
        messages = self.evaluate('(inc remembered)')
        self.assertEqual([m['value'] for m in messages if 'value' in m], ['8'])

    def test_daemon_session_keeps_star_one_and_current_namespace(self):
        self.start_server()
        self.evaluate('(+ 20 22)')
        self.assertEqual([m['value'] for m in self.evaluate('*1') if 'value' in m], ['42'])
        self.evaluate('(in-ns (quote demo.other))')
        namespaces = [m['ns'] for m in self.evaluate('(str *ns*)') if 'ns' in m]
        self.assertEqual(namespaces[-1], 'demo.other')

    def test_status_reports_port_session_and_server_op_set(self):
        self.start_server()
        status = self.status()
        self.assertTrue(status['connected'], status)
        self.assertEqual(status['port'], int((self.path/'.nrepl-port').read_text().strip()))
        self.assertTrue(status['session'])
        self.assertIn('eval', status['ops'])
        self.assertIn('describe', status['ops'])
        self.assertTrue(Path(status['fifo']).is_fifo())
        self.assertTrue(Path(status['log']).is_file())

    def test_second_client_reuses_the_running_daemon_session(self):
        self.start_server()
        first = self.status()
        self.evaluate('(def shared 1)')
        second = self.status()
        self.assertEqual(first['session'], second['session'])
        self.assertEqual(first['socket'], second['socket'])
        self.assertEqual([m['value'] for m in self.evaluate('shared') if 'value' in m], ['1'])

    def test_log_orders_out_err_and_value_chronologically(self):
        self.start_server()
        self.evaluate('(do (println "before") (binding [*out* *err*] (println "problem")) (println "after") :done)')
        log = Path(self.status()['log']).read_text()
        body = log[log.rindex(support.LOG_SEPARATOR):]
        kept = [line for line in body.splitlines()
                if line.startswith('; (out)') or line.startswith('; (err)') or line == ':done']
        self.assertEqual(kept, ['; (out) before', '; (err) problem', '; (out) after', ':done'])

    def test_log_records_the_originating_position_and_namespace(self):
        self.start_server()
        self.evaluate('(ns demo)')
        result = self.support_command('nrepl-eval', self.source, '', '', 'demo', 4, 3, '(+ 1 1)')
        self.assertEqual(result.returncode, 0, result.stderr)
        deadline = time.monotonic() + 10
        log = ''
        while time.monotonic() < deadline and '\n2\n' not in log:
            log = Path(self.status()['log']).read_text()
            time.sleep(.05)
        self.assertIn(f'; eval ({self.source}:4:3) demo', log)
        self.assertIn('\n2\n', log)

    def test_evaluation_error_reports_exception_text(self):
        self.start_server()
        messages = self.evaluate('(/ 1 0)')
        self.assertTrue(any('eval-error' in m.get('status', []) for m in messages), messages)
        self.assertIn('Divide by zero', ''.join(m.get('err', '') for m in messages))

    def test_missing_port_file_reports_error_without_hanging(self):
        status = self.status()
        self.assertFalse(status['connected'])
        self.assertIn('.nrepl-port', status['error'])
        result = self.support_command('nrepl-op', self.source, 'eval', 'code=(+ 1 1)', timeout=20)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('.nrepl-port', result.stderr)

    def test_stale_port_file_pointing_at_nothing_reports_error(self):
        listener = socket.socket()
        listener.bind(('127.0.0.1', 0))
        port = listener.getsockname()[1]
        listener.close()
        (self.path/'.nrepl-port').write_text(f'{port}\n')
        status = self.status()
        self.assertFalse(status['connected'])
        self.assertIn(str(port), status['error'])

    def test_server_death_during_evaluation_fails_the_request(self):
        server = self.start_server()
        self.evaluate('(+ 1 1)')
        outcome = []
        waiter = threading.Thread(target=lambda: outcome.append(
            self.support_command('nrepl-op', self.source, 'eval', 'code=(Thread/sleep 60000)', timeout=60)))
        waiter.start()
        time.sleep(1.5)
        server.terminate()
        waiter.join(timeout=30)
        self.assertFalse(waiter.is_alive(), 'the daemon wedged after the server died')
        self.assertNotEqual(outcome[0].returncode, 0)
        self.assertIn('connection', outcome[0].stderr.lower())
        self.assertFalse(self.status()['connected'])

    def test_daemon_recovers_after_a_restarted_server(self):
        server = self.start_server()
        self.evaluate('(def before 1)')
        server.terminate()
        server.wait(timeout=10)
        for _ in range(200):
            if not (self.path/'.nrepl-port').exists():
                break
            time.sleep(.05)
        self.support_command('nrepl-op', self.source, 'eval', 'code=(+ 1 1)', timeout=20)
        self.start_server()
        self.assertEqual([m['value'] for m in self.evaluate('(+ 2 2)') if 'value' in m], ['4'])

    def test_interrupt_reports_the_server_answer(self):
        self.start_server()
        result = self.support_command('nrepl-interrupt', self.source)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('messages', json.loads(result.stdout))

    def test_generic_op_passthrough_reaches_an_unsupported_op(self):
        self.start_server()
        result = self.support_command('nrepl-op', self.source, 'test-var-query')
        messages = json.loads(result.stdout) if result.returncode == 0 else []
        statuses = [s for m in messages for s in m.get('status', [])]
        self.assertIn('done', statuses, result.stderr)

    def test_op_timeout_gives_up_on_a_runaway_form_instead_of_blocking(self):
        self.start_server()
        started = time.monotonic()
        result = self.support_command('nrepl-op', self.source, 'eval',
                                      'code=(Thread/sleep 60000)', 'timeout=2', timeout=40)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('within 2s', result.stderr)
        self.assertLess(time.monotonic() - started, 30)

    def test_a_timed_out_request_stays_interruptible(self):
        self.start_server()
        self.support_command('nrepl-op', self.source, 'eval',
                             'code=(Thread/sleep 60000)', 'timeout=2', timeout=40)
        result = self.support_command('nrepl-interrupt', self.source)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(json.loads(result.stdout)['interrupted'])


class ClojureForms(unittest.TestCase):
    """Form and symbol selection, the part of evaluation easiest to get wrong."""

    SAMPLE = (b'(ns demo)\n'
              b'\n'
              b'(defn f [x]\n'
              b'  (let [y (+ x 1)]\n'
              b'    (* y 2)))\n')

    def span(self, text, line, column, kind):
        offset = support.byte_offset(text, line, column)
        if kind == 'word':
            return support.clojure_word_range(text, offset)
        return support.clojure_form_range(text, offset, kind == 'root')

    def test_form_innermost_returns_the_nearest_enclosing_parens(self):
        start, end = self.span(self.SAMPLE, 4, 14, 'form')
        self.assertEqual(self.SAMPLE[start:end + 1], b'(+ x 1)')

    def test_form_root_returns_the_whole_top_level_form(self):
        start, end = self.span(self.SAMPLE, 4, 14, 'root')
        self.assertEqual(support.line_column(self.SAMPLE, start), (3, 1))
        self.assertEqual(support.line_column(self.SAMPLE, end), (5, 13))

    def test_form_on_the_opening_bracket_selects_that_form(self):
        start, end = self.span(self.SAMPLE, 4, 3, 'form')
        self.assertEqual(self.SAMPLE[start:end + 1].split(b'\n')[0], b'(let [y (+ x 1)]')

    def test_form_root_of_a_vector_literal_returns_the_vector(self):
        text = b'[1 2 3]\n'
        start, end = self.span(text, 1, 4, 'root')
        self.assertEqual(text[start:end + 1], b'[1 2 3]')

    def test_form_ignores_brackets_inside_strings(self):
        text = b'(str "a (b" x)\n'
        start, end = self.span(text, 1, 13, 'form')
        self.assertEqual(text[start:end + 1], text.strip())

    def test_form_ignores_brackets_inside_line_comments(self):
        text = b'(do ; (ignored\n  1)\n'
        start, end = self.span(text, 2, 3, 'form')
        self.assertEqual(text[start:end + 1], b'(do ; (ignored\n  1)')

    def test_form_ignores_a_bracket_character_literal(self):
        text = b'(conj xs \\( )\n'
        start, end = self.span(text, 1, 2, 'form')
        self.assertEqual(text[start:end + 1], text.strip())

    def test_form_outside_every_bracket_returns_nothing(self):
        self.assertIsNone(self.span(self.SAMPLE, 2, 1, 'form'))
        self.assertIsNone(self.span(self.SAMPLE, 2, 1, 'root'))

    def test_form_unclosed_extends_to_the_end_of_the_buffer(self):
        text = b'(defn f [x]\n  (+ x 1\n'
        start, end = self.span(text, 2, 6, 'root')
        self.assertEqual(support.line_column(text, start), (1, 1))
        self.assertEqual(end, len(text) - 1)

    def test_word_keeps_the_punctuation_clojure_symbols_use(self):
        text = b'(clojure.string/blank? x)\n'
        start, end = self.span(text, 1, 10, 'word')
        self.assertEqual(text[start:end + 1], b'clojure.string/blank?')

    def test_word_strips_the_reader_prefixes_that_are_not_part_of_the_name(self):
        text = b"(map #'inc xs)\n"
        start, end = self.span(text, 1, 8, 'word')
        self.assertEqual(text[start:end + 1], b'inc')

    def test_word_keeps_a_trailing_quote_that_is_part_of_the_name(self):
        text = b"(let [x' 1] x')\n"
        start, end = self.span(text, 1, 7, 'word')
        self.assertEqual(text[start:end + 1], b"x'")

    def test_word_on_whitespace_returns_nothing(self):
        self.assertIsNone(self.span(self.SAMPLE, 4, 13, 'word'))

    def test_form_command_prints_a_kakoune_select(self):
        result = subprocess.run(['python3', str(ROOT/'support.py'), 'clojure-form', 'form', '4', '14'],
                                input=self.SAMPLE, capture_output=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.decode().strip(), 'select 4.11,4.17')

    def test_test_var_names_the_deftest_the_form_defines(self):
        self.assertEqual(support.clojure_test_var('(deftest add-works\n  (is true))'), 'add-works')

    def test_test_var_reads_past_the_metadata_a_test_may_carry(self):
        self.assertEqual(support.clojure_test_var('(deftest ^:slow add-works (is true))'), 'add-works')

    def test_test_var_accepts_defspec_as_a_test_definer(self):
        self.assertEqual(support.clojure_test_var('  (defspec roundtrip 100\n  ...)'), 'roundtrip')

    def test_test_var_of_a_form_that_defines_no_test_returns_nothing(self):
        self.assertIsNone(support.clojure_test_var('(defn add [a b] (+ a b))'))

    def test_test_var_of_a_name_that_merely_starts_with_deftest_returns_nothing(self):
        self.assertIsNone(support.clojure_test_var('(deftest-like thing 1)'))

    def test_form_command_prints_a_fail_when_there_is_no_form(self):
        result = subprocess.run(['python3', str(ROOT/'support.py'), 'clojure-form', 'form', '2', '1'],
                                input=self.SAMPLE, capture_output=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(result.stdout.decode().startswith('fail '), result.stdout)


class NreplTestReport(unittest.TestCase):
    """Turning a cider-nrepl test reply into lines :make can jump from."""

    # Kakoune's own default, from `:doc options`. make-next-error selects with
    # it, so a failure line that does not match it is reachable only by hand.
    MAKE_ERROR_PATTERN = re.compile(r'^([^:\n]+):(\d+):(?:(\d+):)? (?:fatal )?error:([^\n]+)?')

    FAILURE = {'type': 'fail', 'ns': 'demo.core-test', 'var': 'add-fails',
               'context': 'deliberate failure', 'message': '', 'index': 0,
               'expected': '99\n', 'actual': '3\n', 'file': 'core_test.clj', 'line': 10}
    ERROR = {'type': 'error', 'ns': 'demo.core-test', 'var': 'add-errors',
             'context': [], 'message': [], 'index': 0, 'expected': '(= 1 (core/add 1 nil))\n',
             'error': 'java.lang.NullPointerException: x is null',
             'file': 'Numbers.java', 'line': 13}
    PATH = '/project/test/demo/core_test.clj'

    def test_a_failure_in_the_test_file_keeps_the_assertion_line(self):
        self.assertEqual(support.test_result_location(self.FAILURE, self.PATH, 8),
                         (self.PATH, 10))

    def test_an_error_thrown_outside_the_test_file_falls_back_to_the_deftest_line(self):
        self.assertEqual(support.test_result_location(self.ERROR, self.PATH, 12),
                         (self.PATH, 12))

    def test_a_result_whose_var_has_no_known_file_reports_no_location(self):
        self.assertEqual(support.test_result_location(self.FAILURE, '', None), ('', None))

    def test_a_failure_line_matches_the_pattern_make_next_error_searches_for(self):
        line = support.test_failure_line(self.FAILURE, (self.PATH, 10))
        match = self.MAKE_ERROR_PATTERN.match(line)
        self.assertIsNotNone(match, line)
        self.assertEqual(match.group(1, 2, 3), (self.PATH, '10', '1'))

    def test_a_failure_line_names_the_test_and_both_sides_of_the_assertion(self):
        line = support.test_failure_line(self.FAILURE, (self.PATH, 10))
        self.assertIn('FAIL demo.core-test/add-fails', line)
        self.assertIn('deliberate failure', line)
        self.assertIn('expected 99, actual 3', line)

    def test_an_error_line_carries_the_exception_text_and_says_error(self):
        line = support.test_failure_line(self.ERROR, (self.PATH, 12))
        self.assertIn('ERROR demo.core-test/add-errors', line)
        self.assertIn('NullPointerException', line)

    def test_a_failure_with_no_location_is_reported_as_a_comment_not_a_jump(self):
        line = support.test_failure_line(self.FAILURE, ('', None))
        self.assertIsNone(self.MAKE_ERROR_PATTERN.match(line))
        self.assertTrue(line.startswith('; '), line)
        self.assertIn('FAIL demo.core-test/add-fails', line)

    def test_a_line_is_one_line_however_many_the_values_printed_over(self):
        entry = dict(self.FAILURE, actual='{:a 1\n :b 2}\n')
        self.assertNotIn('\n', support.test_failure_line(entry, (self.PATH, 10)))

    def test_the_summary_counts_every_outcome_the_server_reported(self):
        summary = support.test_summary_text({'test': 4, 'pass': 2, 'fail': 1, 'error': 1, 'ns': 2, 'var': 4})
        self.assertIn('4 tests', summary)
        self.assertIn('2 passed', summary)
        self.assertIn('1 failed', summary)
        self.assertIn('1 errored', summary)

    def test_a_summary_of_one_test_does_not_call_it_tests(self):
        self.assertIn('1 test,', support.test_summary_text(
            {'test': 1, 'pass': 1, 'fail': 0, 'error': 0}))

    def test_a_summary_with_nothing_run_says_so_rather_than_reporting_zeroes(self):
        self.assertIn('no tests', support.test_summary_text({'test': 0, 'pass': 0, 'fail': 0, 'error': 0}))

    def test_failures_are_listed_in_namespace_then_var_order(self):
        results = {'b.core-test': {'z': [self.FAILURE], 'a': [self.ERROR]},
                   'a.core-test': {'m': [dict(self.FAILURE, type='pass')]}}
        names = [(entry['ns'], entry['var']) for entry in support.test_failures(results)]
        self.assertEqual(names, [('demo.core-test', 'add-errors'), ('demo.core-test', 'add-fails')])

    def test_the_log_block_keeps_the_detail_the_one_line_report_dropped(self):
        block = support.test_failure_log(self.FAILURE, (self.PATH, 10))
        self.assertIn('expected', block)
        self.assertIn('99', block)
        self.assertIn('actual', block)
        self.assertIn('3', block)
        self.assertTrue(all(line.startswith(';') for line in block.splitlines()), block)


class NreplCompletionCandidates(unittest.TestCase):
    """The prefix under the cursor and the completions option built from it."""

    def test_the_prefix_is_the_symbol_ending_just_before_the_cursor(self):
        self.assertEqual(support.clojure_completion_prefix('(map inc co', 12), ('co', 10))

    def test_the_prefix_stops_at_the_bracket_that_opens_the_form(self):
        self.assertEqual(support.clojure_completion_prefix('(ma', 4), ('ma', 2))

    def test_the_prefix_keeps_the_namespace_alias_of_a_qualified_symbol(self):
        self.assertEqual(support.clojure_completion_prefix('(str/jo', 8), ('str/jo', 2))

    def test_the_prefix_drops_the_reader_syntax_that_is_not_part_of_the_name(self):
        self.assertEqual(support.clojure_completion_prefix("#'fo", 5), ('fo', 3))

    def test_a_cursor_after_whitespace_has_no_prefix_to_complete(self):
        self.assertEqual(support.clojure_completion_prefix('(map inc ', 10), ('', 10))

    def test_a_candidate_renders_as_text_select_command_and_menu_text(self):
        option = support.completion_option(3, 10, 42, [
            {'candidate': 'add-works', 'ns': 'demo.core-test', 'type': 'var'}], 10)
        self.assertEqual(option, ['3.10@42', 'add-works||demo.core-test var'])

    def test_a_pipe_in_a_candidate_is_escaped_so_the_option_still_parses(self):
        option = support.completion_option(1, 1, 7, [{'candidate': 'a|b', 'ns': 'x', 'type': 'var'}], 10)
        self.assertEqual(option[1], 'a\\|b||x var')

    def test_a_brace_in_the_menu_text_is_escaped_so_it_is_not_read_as_a_face(self):
        option = support.completion_option(1, 1, 7, [{'candidate': 'a', 'ns': '{x}', 'type': 'var'}], 10)
        self.assertIn('\\{x}', option[1])

    def test_no_more_candidates_are_offered_than_the_limit_allows(self):
        candidates = [{'candidate': f'v{n}', 'ns': 'x', 'type': 'var'} for n in range(20)]
        self.assertEqual(len(support.completion_option(1, 1, 7, candidates, 5)), 6)

    def test_an_answer_with_no_candidates_still_produces_a_valid_empty_option(self):
        self.assertEqual(support.completion_option(2, 5, 9, [], 10), ['2.5@9'])


class NreplDocReply(unittest.TestCase):
    """The info op's reply, as a doc box and as a place to jump to."""

    # Captured from Babashka 1.12 and from nREPL 1.7 carrying cider-nrepl 0.62.2.
    BABASHKA = {'arglists-str': '[a b]', 'doc': 'Adds a and b.', 'name': 'add', 'ns': 'demo',
                'file': 'file:/project/demo.clj', 'status': ['done']}
    JVM = {'arglists-str': '[a b]', 'doc': 'Adds a and b.', 'name': 'add', 'ns': 'demo.core',
           'file': 'file:/project/src/demo/core.clj', 'line': 3, 'column': 1, 'status': ['done']}
    REPL_DEFINED = {'file': 'NO_SOURCE_PATH', 'line': 1, 'column': 1, 'name': 'repl-only',
                    'ns': 'user', 'status': ['done']}
    IN_A_JAR = {'arglists-str': '[f]\n[f coll]', 'doc': 'Returns a lazy sequence.',
                'name': 'map', 'ns': 'clojure.core', 'line': 2748,
                'file': 'jar:file:/home/user/.m2/clojure-1.12.6.jar!/clojure/core.clj',
                'status': ['done']}
    UNKNOWN = {'status': ['done', 'no-info']}

    def test_the_reply_is_merged_from_the_body_and_the_status_message(self):
        merged = support.nrepl_info_reply([{'name': 'add', 'ns': 'demo'}, {'status': ['done']}])
        self.assertEqual(merged, {'name': 'add', 'ns': 'demo', 'status': ['done']})

    def test_a_reply_that_carries_no_name_is_not_a_var_the_server_knows(self):
        self.assertFalse(support.nrepl_info_found(self.UNKNOWN))
        self.assertTrue(support.nrepl_info_found(self.BABASHKA))

    def test_the_doc_box_opens_with_the_qualified_name_then_the_arglists(self):
        lines = support.nrepl_doc_text(self.JVM).splitlines()
        self.assertEqual(lines[0], 'demo.core/add')
        self.assertEqual(lines[1], '[a b]')
        self.assertIn('Adds a and b.', lines)

    def test_every_arglist_of_a_multi_arity_var_keeps_its_own_line(self):
        lines = support.nrepl_doc_text(self.IN_A_JAR).splitlines()
        self.assertEqual(lines[1:3], ['[f]', '[f coll]'])

    def test_a_var_with_no_docstring_says_so_rather_than_ending_blank(self):
        self.assertIn('no docstring', support.nrepl_doc_text(self.REPL_DEFINED))

    def test_the_summary_names_the_var_and_its_arglists_on_one_line(self):
        self.assertEqual(support.nrepl_doc_summary(self.JVM), 'nrepl: demo.core/add [a b]')

    def test_a_var_loaded_from_a_file_on_disk_is_a_place_to_jump_to(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory)/'core.clj'
            source.write_text('(ns demo.core)\n')
            info = dict(self.JVM, file='file:' + str(source))
            self.assertEqual(support.nrepl_definition(info), (str(source), 3, ''))

    def test_a_var_defined_at_the_repl_says_it_has_no_file_rather_than_failing(self):
        path, line, reason = support.nrepl_definition(self.REPL_DEFINED)
        self.assertEqual((path, line), ('', None))
        self.assertIn('defined at the REPL', reason)

    def test_a_var_inside_a_jar_says_its_source_is_not_a_file_on_disk(self):
        path, line, reason = support.nrepl_definition(self.IN_A_JAR)
        self.assertEqual((path, line), ('', None))
        self.assertIn('not a file on disk', reason)

    def test_a_var_whose_file_is_gone_is_reported_rather_than_opened_empty(self):
        path, line, reason = support.nrepl_definition(
            dict(self.JVM, file='file:/project/deleted/core.clj'))
        self.assertEqual((path, line), ('', None))
        self.assertIn('/project/deleted/core.clj', reason)

    def test_a_babashka_reply_with_no_line_still_jumps_to_the_top_of_the_file(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory)/'demo.clj'
            source.write_text('(ns demo)\n')
            info = dict(self.BABASHKA, file='file:' + str(source))
            self.assertEqual(support.nrepl_definition(info), (str(source), 1, ''))


class NreplRefreshReport(unittest.TestCase):
    """cider-nrepl's refresh reply, as a status line and as a log block."""

    # Captured from cider-nrepl 0.62.2, whose refresh middleware inlines
    # clojure.tools.namespace 1.5.1 and so needs no dependency of its own.
    RELOADED = [{'reloading': ['demo.core', 'demo.broken']}, {'status': ['ok']},
                {'status': ['done']}]
    UNCHANGED = [{'reloading': []}, {'status': ['ok']}, {'status': ['done']}]
    CLEARED = [{'status': ['done']}]
    FAILED = [
        {'reloading': ['demo.core', 'demo.broken']},
        {'error': [{'class': 'clojure.lang.Compiler$CompilerException',
                    'message': 'Syntax error macroexpanding at (broken.clj:4:11).',
                    'file': 'broken.clj', 'line': 4},
                   {'class': 'java.lang.NullPointerException',
                    'message': 'Cannot invoke "Object.getClass()" because "x" is null'}],
         'error-ns': 'demo.broken', 'status': ['error']},
        {'err': 'Execution error (NullPointerException) at demo.core/add (core.clj:6).\n'
                'Cannot invoke "Object.getClass()" because "x" is null\n'},
        {'status': ['done']}]

    def test_a_successful_refresh_names_every_namespace_it_reloaded(self):
        summary, _ = support.refresh_report('changed', self.RELOADED)
        self.assertIn('2 namespaces', summary)
        self.assertIn('demo.core, demo.broken', summary)

    def test_a_refresh_with_nothing_to_reload_says_so_rather_than_naming_none(self):
        summary, _ = support.refresh_report('changed', self.UNCHANGED)
        self.assertIn('nothing to reload', summary)

    def test_clearing_the_cache_reports_what_the_next_refresh_will_do(self):
        summary, _ = support.refresh_report('clear', self.CLEARED)
        self.assertIn('cache', summary)
        self.assertIn('next refresh', summary)

    def test_a_failed_refresh_names_the_namespace_and_the_exception(self):
        summary, _ = support.refresh_report('changed', self.FAILED)
        self.assertIn('refresh failed in demo.broken', summary)
        self.assertIn('broken.clj:4', summary)
        self.assertIn(':nrepl-log-open', summary)

    def test_a_failed_refresh_summary_is_one_line_however_many_the_error_spans(self):
        summary, _ = support.refresh_report('changed', self.FAILED)
        self.assertNotIn('\n', summary)

    def test_the_log_block_keeps_the_root_cause_the_summary_dropped(self):
        _, detail = support.refresh_report('changed', self.FAILED)
        self.assertIn('NullPointerException', detail)
        self.assertIn('demo.core, demo.broken', detail)
        self.assertIn('Execution error', detail)
        self.assertTrue(all(line.startswith(';') for line in detail.splitlines()), detail)

    def test_a_failure_reported_only_as_text_is_still_read_as_a_failure(self):
        summary, _ = support.refresh_report(
            'changed', [{'error': 'could not resolve demo.broken', 'error-ns': 'demo.broken',
                         'status': ['error']}])
        self.assertIn('refresh failed in demo.broken', summary)
        self.assertIn('could not resolve', summary)


class NreplVerbs(KakouneSession):
    """The evaluation verbs, with dispatch stubbed so no server is needed."""

    STUB = """define-command -override -params 5 nrepl-send-code %{
    echo -debug "SENT %arg{1}|%arg{3}|%arg{4}|%arg{5}"
}
"""

    def dispatch(self, name, body, keys, command):
        source = self.path/name
        source.write_text(body)
        return self.start(self.STUB + f'''edit {q(source)}
execute-keys {q(keys)}
try %{{ {command} }} catch %{{ echo -debug CAUGHT %val{{error}} }}
echo -debug "CURSOR %val{{cursor_line}}.%val{{cursor_column}}"
''')

    NESTED = '(ns demo)\n\n(defn f [x]\n  (let [y (+ x 1)]\n    (* y 2)))\n'

    def test_eval_form_sends_the_innermost_enclosing_form(self):
        debug = self.dispatch('forms.clj', self.NESTED, '4g13l', 'nrepl-eval-form')
        self.assertIn('SENT demo|4|11|(+ x 1)', debug)
        self.assertIn('CURSOR 4.14', debug)

    def test_eval_root_form_sends_the_whole_top_level_form(self):
        debug = self.dispatch('forms.clj', self.NESTED, '4g13l', 'nrepl-eval-root-form')
        self.assertIn('SENT demo|3|1|(defn f [x]', debug)
        self.assertIn('CURSOR 4.14', debug)

    def test_eval_word_sends_only_the_symbol_under_the_cursor(self):
        debug = self.dispatch('forms.clj', self.NESTED, '4g13l', 'nrepl-eval-word')
        self.assertIn('SENT demo|4|14|x', debug)

    def test_eval_word_off_a_symbol_reports_instead_of_evaluating(self):
        debug = self.dispatch('forms.clj', self.NESTED, '4g12l', 'nrepl-eval-word')
        self.assertNotIn('SENT ', debug)
        self.assertIn('no Clojure symbol under the cursor', debug)

    def test_eval_buffer_loads_the_whole_buffer_from_user(self):
        body = ';; header\n(ns demo)\n(+ 1 1)\n'
        debug = self.dispatch('buffer.clj', body, 'gg', 'nrepl-eval-buffer')
        self.assertIn('SENT user|1|1|;; header', debug)

    def test_eval_file_sends_a_load_file_of_the_path_on_disk(self):
        debug = self.dispatch('ondisk.clj', self.NESTED, 'gg', 'nrepl-eval-file')
        self.assertIn('SENT user|1|1|(load-file "' + str(self.path/'ondisk.clj') + '")', debug)

    def test_the_namespace_prompt_sets_the_override_and_empty_restores_inference(self):
        source = self.path/'forms.clj'
        source.write_text(self.NESTED)
        debug = self.start(self.STUB + f'''edit {q(source)}
execute-keys ': nrepl-set-namespace<ret>other.ns<ret>'
execute-keys '4g13l'
nrepl-eval-form
execute-keys ': nrepl-set-namespace<ret>' '<backspace>' '<backspace>' '<backspace>' '<backspace>' '<backspace>' '<backspace>' '<backspace>' '<backspace>' '<ret>'
nrepl-eval-form
''')
        self.assertIn('SENT other.ns|4|11|(+ x 1)', debug)
        self.assertIn('SENT demo|4|11|(+ x 1)', debug)

    def test_namespace_override_replaces_the_inferred_namespace(self):
        source = self.path/'forms.clj'
        source.write_text(self.NESTED)
        debug = self.start(self.STUB + f'''edit {q(source)}
set-option buffer nrepl_namespace other.ns
execute-keys '4g13l'
nrepl-eval-form
''')
        self.assertIn('SENT other.ns|4|11|(+ x 1)', debug)

    def test_an_ns_form_is_always_evaluated_from_user(self):
        debug = self.dispatch('forms.clj', self.NESTED, 'gg', 'nrepl-eval-form')
        self.assertIn('SENT user|1|1|(ns demo)', debug)

    def test_selections_are_paired_with_their_own_positions(self):
        body = '(ns demo)\n(+ 1 1)\n(+ 2 2)\n'
        debug = self.dispatch('many.clj', body, '2gxC', 'nrepl-eval-selection')
        self.assertIn('SENT demo|2|1|(+ 1 1)', debug)
        self.assertIn('SENT demo|3|1|(+ 2 2)', debug)

    def handle(self, status, error, request='kak-9'):
        return self.start(self.STUB + f'''set-option global nrepl_retry_id kak-9
set-option global nrepl_retry_command "nrepl-send-code user /tmp/x.clj 3 1 '(+ 1 1)'"
nrepl-handle-result {request} {status} '' '' {q(error)} /tmp/x.clj 3 1
echo -debug "REPORT %opt{{nrepl_report}}"
echo -debug "ARMED %opt{{nrepl_retry_id}}."
''')

    def test_an_error_naming_a_missing_namespace_retries_once_in_user(self):
        debug = self.handle('error', ': No namespace: nope found user')
        self.assertIn('SENT user|3|1|(+ 1 1)', debug)
        self.assertIn('ARMED .', debug)

    def test_an_error_with_no_text_retries_in_user_as_nrepl_1_7_reports_it(self):
        debug = self.handle('error', '')
        self.assertIn('SENT user|3|1|(+ 1 1)', debug)

    def test_an_error_that_names_a_real_failure_is_reported_not_retried(self):
        debug = self.handle('error', 'java.lang.ArithmeticException: Divide by zero')
        self.assertNotIn('SENT ', debug)
        self.assertIn('REPORT nrepl error: java.lang.ArithmeticException', debug)

    def test_a_result_from_another_request_never_triggers_the_retry(self):
        debug = self.handle('error', '', request='kak-8')
        self.assertNotIn('SENT ', debug)

    def test_a_successful_result_reports_the_value_with_its_namespace(self):
        debug = self.start(self.STUB + '''nrepl-handle-result kak-1 ok demo 42 '' /tmp/x.clj 1 1
echo -debug "REPORT %opt{nrepl_report}"
''')
        self.assertIn('REPORT demo=> 42', debug)

    def test_an_interrupted_result_says_so_rather_than_reporting_an_error(self):
        debug = self.start(self.STUB + '''nrepl-handle-result kak-1 interrupted '' '' '' /tmp/x.clj 1 1
echo -debug "REPORT %opt{nrepl_report}"
''')
        self.assertIn('REPORT nrepl: interrupted', debug)


class NreplTestVerbs(KakouneSession):
    """Which targets each test verb asks the runner for."""

    STUB = """define-command -override -params 1.. nrepl-run-tests %{
    echo -debug "TESTS %arg{@}"
}
"""

    TESTS = ('(ns demo.core-test\n  (:require [clojure.test :refer [deftest is]]))\n'
             '\n'
             '(deftest add-works\n  (is (= 3 (+ 1 2))))\n'
             '\n'
             '(def not-a-test 1)\n')

    def dispatch(self, name, body, keys, command):
        source = self.path/name
        source.write_text(body)
        return self.start(self.STUB + f'''edit {q(source)}
execute-keys {q(keys)}
try %{{ {command} }} catch %{{ echo -debug CAUGHT %val{{error}} }}
''')

    def test_the_cursor_inside_a_deftest_runs_that_one_test(self):
        debug = self.dispatch('core_test.clj', self.TESTS, '5g6l', 'nrepl-test-under-cursor')
        self.assertIn('TESTS var demo.core-test/add-works', debug)

    def test_a_cursor_in_a_form_that_is_not_a_test_reports_instead_of_running(self):
        debug = self.dispatch('core_test.clj', self.TESTS, '7g6l', 'nrepl-test-under-cursor')
        self.assertIn('CAUGHT', debug)
        self.assertIn('no deftest at the cursor', debug)
        self.assertNotIn('TESTS', debug)

    def test_a_source_namespace_offers_itself_and_its_test_sibling(self):
        debug = self.dispatch('core.clj', '(ns demo.core)\n', 'gg', 'nrepl-test-namespace')
        self.assertIn('TESTS namespace demo.core demo.core-test', debug)

    def test_a_test_namespace_is_its_own_only_target(self):
        debug = self.dispatch('core_test.clj', '(ns demo.core-test)\n', 'gg', 'nrepl-test-namespace')
        self.assertIn('TESTS namespace demo.core-test', debug)
        self.assertNotIn('demo.core-test-test', debug)

    def test_the_whole_project_takes_no_target_at_all(self):
        debug = self.dispatch('core.clj', '(ns demo.core)\n', 'gg', 'nrepl-test-all')
        self.assertIn('TESTS all', debug)

    def test_the_rerun_verb_asks_the_server_for_its_own_last_failures(self):
        debug = self.dispatch('core.clj', '(ns demo.core)\n', 'gg', 'nrepl-test-rerun')
        self.assertIn('TESTS rerun', debug)


class NreplKeyGrammar(KakouneSession):
    """The Conjure localleader grammar, scoped to Clojure windows."""

    def reached(self, command, keys, name='forms.clj', body='(ns demo)\n'):
        source = self.path/name
        source.write_text(body)
        return self.start(f'''define-command -override {command} %{{ echo -debug "REACHED {command}" }}
edit {q(source)}
execute-keys -with-maps {q(keys)}
''')

    def selection_count(self, name, keys, body='alpha\nbeta\ngamma\n', extra=''):
        source = self.path/name
        source.write_text(body)
        debug = self.start(f'''{extra}edit {q(source)}
select 1.1,1.1 2.1,2.1 3.1,3.1
execute-keys -with-maps {q(keys)}
echo -debug "COUNT %val{{selection_count}}"
''')
        return re.search(r'COUNT (\d+)', debug).group(1)

    def test_localleader_in_a_clojure_buffer_enters_the_mode(self):
        debug = self.reached('nrepl-eval-selection', ',E')
        self.assertIn('REACHED nrepl-eval-selection', debug)

    def test_localleader_three_levels_deep_reaches_the_comment_verb(self):
        debug = self.reached('nrepl-eval-comment-form', ',ece')
        self.assertIn('REACHED nrepl-eval-comment-form', debug)

    def test_localleader_submodes_reach_their_verbs(self):
        for command, keys in [('nrepl-eval-root-form', ',er'),
                              ('nrepl-log-open-in-client', ',lv'),
                              ('nrepl-status', ',cs'),
                              ('nrepl-test-namespace', ',tn'),
                              ('nrepl-refresh-changed', ',rr'),
                              ('nrepl-doc-word', ',K'),
                              ('nrepl-goto-definition', ',gd')]:
            with self.subTest(keys=keys):
                self.assertIn(f'REACHED {command}', self.reached(command, keys))

    def test_the_space_r_alias_reaches_the_same_mode(self):
        debug = self.reached('nrepl-eval-selection', '<space>rE')
        self.assertIn('REACHED nrepl-eval-selection', debug)

    def test_localleader_in_a_clojure_buffer_keeps_every_selection(self):
        self.assertEqual(self.selection_count('keep.clj', ',<esc>'), '3')

    def test_space_comma_in_a_clojure_buffer_keeps_only_the_main_selection(self):
        self.assertEqual(self.selection_count('keep.clj', '<space>,'), '1')

    def test_comma_outside_clojure_keeps_only_the_main_selection(self):
        self.assertEqual(self.selection_count('plain.txt', ','), '1')

    def test_leaving_a_clojure_filetype_restores_the_native_comma(self):
        count = self.selection_count('plain.txt', ',',
                                     extra=f'edit {q(self.path/"first.clj")}\n')
        self.assertEqual(count, '1')


class NreplInlineResults(KakouneSession):
    """Virtual text: anchoring, collapsing, clearing and the buffer it lands in."""

    STUB = NreplVerbs.STUB
    # Line 4 is '  (let [y (+ x 1)]', eighteen bytes, so its end of line is 4.19.
    NESTED = NreplVerbs.NESTED
    FORM_LINE = 4
    FORM_ANCHOR = '4.19+0'

    def deliver(self, keys, verb, status, values, error, line, between='', after=''):
        source = self.path/'render.clj'
        source.write_text(self.NESTED)
        return self.start(self.STUB + f'''edit {q(source)}
execute-keys {q(keys)}
{verb}
{between}
nrepl-handle-result kak-1 {status} demo {q(values)} {q(error)} {q(source)} {line} 1
{after}
echo -debug "SPECS %opt{{nrepl_eval_results}}"
''')

    def test_a_value_renders_as_virtual_text_at_the_end_of_its_form_line(self):
        debug = self.deliver('4g13l', 'nrepl-eval-form', 'ok', '42', '', self.FORM_LINE)
        self.assertIn(self.FORM_ANCHOR + '|{InlayEvalResult}  ; => 42', debug)

    def test_an_empty_value_renders_as_nil_rather_than_an_empty_comment(self):
        debug = self.deliver('4g13l', 'nrepl-eval-form', 'ok', '', '', self.FORM_LINE)
        self.assertIn(self.FORM_ANCHOR + '|{InlayEvalResult}  ; => nil', debug)

    def test_an_error_renders_with_its_own_face_so_it_reads_as_a_failure(self):
        debug = self.deliver('4g13l', 'nrepl-eval-form', 'error', '',
                             'java.lang.ArithmeticException: Divide by zero', self.FORM_LINE)
        self.assertIn(self.FORM_ANCHOR + '|{InlayEvalError}  ; !! java.lang.ArithmeticException',
                      debug)

    def test_a_multi_line_value_collapses_to_one_line_pointing_at_the_log(self):
        debug = self.deliver('4g13l', 'nrepl-eval-form', 'ok', '{:a 1\n :b 2}', '', self.FORM_LINE)
        specs = [line for line in debug.splitlines() if line.startswith('SPECS ')][-1]
        self.assertIn(':a 1 :b 2} ... (:nrepl-log-open)', specs)

    def test_a_value_wider_than_the_limit_is_cut_back_to_it(self):
        debug = self.deliver('4g13l', 'nrepl-eval-form', 'ok', 'x' * 200, '', self.FORM_LINE,
                             between='set-option global nrepl_result_width 20')
        specs = [line for line in debug.splitlines() if line.startswith('SPECS ')][-1]
        self.assertIn('; => ' + 'x' * 20 + ' ... (:nrepl-log-open)', specs)
        self.assertNotIn('x' * 21, specs)

    def test_a_brace_in_a_value_is_escaped_so_it_is_not_read_as_a_face(self):
        # Expanding a list option doubles the backslash that escapes the brace,
        # so the stored markup holds one and the value renders whole.
        debug = self.deliver('4g13l', 'nrepl-eval-form', 'ok', '{:a 1}', '', self.FORM_LINE)
        self.assertIn('; => ' + '\\' * 2 + '{:a 1}', debug)

    def test_an_edit_between_the_evaluation_and_the_result_renders_nothing(self):
        debug = self.deliver('4g13l', 'nrepl-eval-form', 'ok', '42', '', self.FORM_LINE,
                             between="execute-keys 'ggO;; inserted<esc>'")
        specs = [line for line in debug.splitlines() if line.startswith('SPECS ')][-1]
        self.assertNotIn('+0|', specs)

    def test_an_edit_after_the_result_drops_it_rather_than_moving_it(self):
        # The hooks that call this on a real edit are idle driven, and a
        # scripted session never idles, so the check itself is driven here.
        debug = self.deliver('4g13l', 'nrepl-eval-form', 'ok', '42', '', self.FORM_LINE,
                             after="execute-keys 'ggOz<esc>'\nnrepl-clear-results-if-edited\n"
                                   'echo -debug "AFTER %opt{nrepl_eval_results}"')
        after = [line for line in debug.splitlines() if line.startswith('AFTER ')][-1]
        self.assertNotIn('+0|', after)

    def test_cursor_movement_leaves_the_result_in_place(self):
        debug = self.deliver('4g13l', 'nrepl-eval-form', 'ok', '42', '', self.FORM_LINE,
                             after="execute-keys 'ggjjl'\nnrepl-clear-results-if-edited\n"
                                   'echo -debug "AFTER %opt{nrepl_eval_results}"')
        after = [line for line in debug.splitlines() if line.startswith('AFTER ')][-1]
        self.assertIn(self.FORM_ANCHOR + '|{InlayEvalResult}  ; => 42', after)

    def test_the_next_evaluation_clears_the_results_of_the_previous_one(self):
        debug = self.deliver('4g13l', 'nrepl-eval-form', 'ok', '42', '', self.FORM_LINE,
                             after='nrepl-eval-form\necho -debug "AFTER %opt{nrepl_eval_results}"')
        after = [line for line in debug.splitlines() if line.startswith('AFTER ')][-1]
        self.assertNotIn('+0|', after)

    def test_two_evaluated_selections_each_keep_their_own_anchor(self):
        source = self.path/'many.clj'
        source.write_text('(ns demo)\n(+ 1 1)\n(+ 2 2)\n')
        debug = self.start(self.STUB + f'''edit {q(source)}
execute-keys '2gxC'
nrepl-eval-selection
nrepl-handle-result kak-1 ok demo 2 '' {q(source)} 2 1
nrepl-handle-result kak-2 ok demo 4 '' {q(source)} 3 1
echo -debug "SPECS %opt{{nrepl_eval_results}}"
''')
        specs = [line for line in debug.splitlines() if line.startswith('SPECS ')][-1]
        self.assertIn('2.8+0|{InlayEvalResult}  ; => 2', specs)
        self.assertIn('3.8+0|{InlayEvalResult}  ; => 4', specs)

    def test_a_result_for_a_background_buffer_never_renders_in_the_visible_one(self):
        background = self.path/'background.clj'
        background.write_text(self.NESTED)
        foreground = self.path/'foreground.clj'
        foreground.write_text(self.NESTED)
        debug = self.start(self.STUB + f'''edit {q(background)}
execute-keys '4g13l'
nrepl-eval-form
edit {q(foreground)}
nrepl-handle-result kak-1 ok demo 42 '' {q(background)} 4 1
echo -debug "FOREGROUND %opt{{nrepl_eval_results}}"
evaluate-commands -buffer {q(background)} %{{ echo -debug "BACKGROUND %opt{{nrepl_eval_results}}" }}
''')
        foreground_specs = [l for l in debug.splitlines() if l.startswith('FOREGROUND ')][-1]
        background_specs = [l for l in debug.splitlines() if l.startswith('BACKGROUND ')][-1]
        self.assertNotIn('+0|', foreground_specs)
        self.assertIn(self.FORM_ANCHOR + '|{InlayEvalResult}  ; => 42', background_specs)

    def test_a_result_for_a_line_past_the_end_of_the_buffer_renders_nothing(self):
        debug = self.deliver('4g13l', 'nrepl-eval-form', 'ok', '42', '', 99)
        specs = [line for line in debug.splitlines() if line.startswith('SPECS ')][-1]
        self.assertNotIn('+0|', specs)

    def test_the_toggle_removes_only_the_evaluation_highlighter(self):
        source = self.path/'render.clj'
        source.write_text(self.NESTED)
        debug = self.start(self.STUB + f'''edit {q(source)}
echo -debug "ENABLED %opt{{show_eval_results}}"
toggle-eval-results
echo -debug "OFF %opt{{show_eval_results}} %opt{{show_inlay_diagnostics}}"
try %{{ remove-highlighter global/nrepl-eval-results; echo -debug STILLTHERE }} catch %{{ echo -debug GONE }}
toggle-eval-results
echo -debug "ON %opt{{show_eval_results}}"
''')
        self.assertIn('ENABLED true', debug)
        self.assertIn('OFF false true', debug)
        self.assertIn('GONE', debug)
        self.assertIn('ON true', debug)



class NreplEditorAgainstBabashka(KakouneSession):
    """Verbs that need a live server: replace, comment, fallback, interrupt."""

    def setUp(self):
        binary = Path.home()/'.local/bin/bb'
        if not binary.exists():
            self.skipTest('Babashka not installed')
        super().setUp()
        (self.path/'bb.edn').write_text('{}')
        self.source = self.path/'demo.clj'
        self.source.write_text('(ns demo)\n')
        self.addCleanup(self.stop_daemon)
        server = subprocess.Popen(['python3', str(ROOT/'support.py'), 'bb-server', str(binary)],
                                  cwd=self.path, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        self.addCleanup(lambda: server.wait(timeout=10))
        self.addCleanup(server.terminate)
        for _ in range(500):
            if (self.path/'.nrepl-port').exists():
                break
            time.sleep(.02)
        else:
            self.fail('Babashka did not publish .nrepl-port')
        # Warm the daemon here so the editor timeout only covers the evaluation.
        self.support_command('nrepl-status', self.source, timeout=60)

    def support_command(self, *args, timeout=30):
        return subprocess.run(['python3', str(ROOT/'support.py'), *map(str, args)],
                              capture_output=True, text=True, timeout=timeout)

    def stop_daemon(self):
        self.support_command('nrepl-shutdown', self.source, timeout=15)
        for path in support.nrepl_paths(support.nrepl_root(self.source)).values():
            Path(path).unlink(missing_ok=True)

    def edit(self, body, script):
        self.source.write_text(body)
        debug = self.start(f'edit {q(self.source)}\n' + script +
                           f'\nevaluate-commands -no-hooks %{{ write {q(self.source)} }}\n')
        return debug, self.source.read_text()

    def test_replace_form_substitutes_the_evaluated_value(self):
        _, text = self.edit('(ns demo)\n\n(+ 20 22)\n', """execute-keys '3g2l'
nrepl-eval-replace-form
""")
        self.assertEqual(text, '(ns demo)\n\n42\n')

    def test_replace_form_leaves_the_text_alone_when_it_times_out(self):
        body = '(ns demo)\n\n(Thread/sleep 60000)\n'
        self.source.write_text(body)
        debug = self.start(f'''edit {q(self.source)}
set-option buffer nrepl_sync_timeout 2
execute-keys '3g2l'
try %{{ nrepl-eval-replace-form }} catch %{{ echo -debug CAUGHT %val{{error}} }}
evaluate-commands -no-hooks %{{ write {q(self.source)} }}
''')
        self.assertIn('CAUGHT', debug)
        self.assertIn('within 2s', debug)
        self.assertEqual(self.source.read_text(), body)

    def test_replace_form_leaves_the_text_alone_when_evaluation_fails(self):
        body = '(ns demo)\n\n(/ 1 0)\n'
        self.source.write_text(body)
        debug = self.start(f'''edit {q(self.source)}
execute-keys '3g2l'
try %{{ nrepl-eval-replace-form }} catch %{{ echo -debug CAUGHT %val{{error}} }}
evaluate-commands -no-hooks %{{ write {q(self.source)} }}
''')
        self.assertIn('CAUGHT', debug)
        self.assertEqual(self.source.read_text(), body)

    def test_comment_form_appends_the_value_below_the_form(self):
        debug, text = self.edit('(ns demo)\n\n(+ 20 22)\n', """execute-keys '3g2l'
nrepl-eval-comment-form
echo -debug "CURSOR %val{cursor_line}.%val{cursor_column}"
""")
        self.assertEqual(text, '(ns demo)\n\n(+ 20 22)\n;; => 42\n')
        self.assertIn('CURSOR 3.3', debug)

    def test_comment_root_form_comments_the_top_level_form_at_its_indent(self):
        _, text = self.edit('(ns demo)\n\n(let [y 1]\n  (+ y 41))\n', """execute-keys '4g5l'
nrepl-eval-comment-root-form
""")
        self.assertEqual(text, '(ns demo)\n\n(let [y 1]\n  (+ y 41))\n;; => 42\n')

    def test_comment_word_comments_the_symbol_under_the_cursor(self):
        self.support_command('nrepl-op', self.source, 'eval', 'code=(def answer 42)', 'ns=user')
        _, text = self.edit('(ns demo)\n\nanswer\n', """execute-keys '3g2l'
nrepl-eval-comment-word
""")
        self.assertEqual(text, '(ns demo)\n\nanswer\n;; => 42\n')

    def test_evaluation_falls_back_to_user_when_the_namespace_is_absent(self):
        _, text = self.edit('(ns demo)\n\n(+ 20 22)\n', """set-option buffer nrepl_namespace nope
execute-keys '3g2l'
nrepl-eval-replace-form
""")
        self.assertEqual(text, '(ns demo)\n\n42\n')

    def test_asynchronous_evaluation_retries_in_user_after_a_missing_namespace(self):
        self.source.write_text('(ns demo)\n\n(def remembered 42)\n')
        proc = self.start(f'''edit {q(self.source)}
set-option buffer nrepl_namespace nope
execute-keys '3g2l'
nrepl-eval-form
''', asynchronous=True)
        deadline = time.monotonic() + 30
        while time.monotonic() < deadline:
            messages = json.loads(self.support_command(
                'nrepl-op', self.source, 'eval', 'code=(resolve (quote user/remembered))').stdout or '[]')
            if [m for m in messages if m.get('value', 'nil') != 'nil']:
                break
            time.sleep(.5)
        else:
            self.fail('the missing-namespace retry never reached user')
        self.send(f'echo -debug "REPORT %opt{{nrepl_report}}"\nbuffer *debug*\n'
                  f'write {q(self.path/"debug")}\nquit!\n')
        proc.communicate(timeout=10)
        self.assertIn("REPORT user=> #'user/remembered", (self.path/'debug').read_text())

    def test_interrupt_without_the_op_reports_it_instead_of_failing(self):
        self.support_command('nrepl-eval', self.source, 'no-such-session', '',
                             'user', '1', '1', '(Thread/sleep 5000)')
        debug = self.start(f'''edit {q(self.source)}
nrepl-interrupt
echo -debug REPORT %opt{{nrepl_report}}
''')
        self.assertIn('REPORT nrepl: this server has no interrupt op', debug)

    def test_interrupt_with_nothing_running_says_so(self):
        debug = self.start(f'''edit {q(self.source)}
nrepl-interrupt
echo -debug REPORT %opt{{nrepl_report}}
''')
        self.assertIn('REPORT nrepl: nothing is running', debug)

    def test_status_reports_the_op_set_so_a_missing_test_op_is_visible(self):
        debug = self.start(f'''edit {q(self.source)}
nrepl-status
echo -debug REPORT %opt{{nrepl_report}}
echo -debug DETAIL %opt{{nrepl_status_detail}}
''')
        self.assertIn('REPORT nrepl: connected 127.0.0.1:', debug)
        self.assertIn('| tests no', debug)
        self.assertIn('ops: classpath, clone', debug)

    def test_a_test_verb_names_the_op_the_babashka_server_does_not_carry(self):
        result = self.support_command('nrepl-test-command', self.source, '', '',
                                      'namespace', 'demo')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(result.stdout.startswith('fail '), result.stdout)
        self.assertIn('no test-var-query op', result.stdout)
        self.assertIn('Babashka', result.stdout)
        self.assertNotIn('make', result.stdout)

    def test_the_rerun_verb_names_retest_rather_than_the_query_op(self):
        result = self.support_command('nrepl-test-command', self.source, '', '', 'rerun')
        self.assertIn('no retest op', result.stdout)

    def test_completion_offers_a_var_that_exists_only_in_the_running_image(self):
        self.support_command('nrepl-op', self.source, 'eval',
                             'code=(ns demo) (def runtime-only 42)', 'ns=user')
        debug = self.start(f"""edit {q(self.source)}
execute-keys 'georuntim'
execute-keys '<esc>'
nrepl-complete
""", asynchronous=True)
        # The candidates arrive from a detached process, so the option is read
        # back only once it has had time to answer.
        time.sleep(3)
        self.send(f"""echo -debug "COMPLETIONS %opt{{nrepl_completions}}"
buffer *debug*
write {q(self.path/'debug')}
quit!
""")
        debug.communicate(timeout=10)
        self.assertIn('runtime-only||demo', (self.path/'debug').read_text())

    def test_completion_sits_behind_the_lsp_completer_and_ahead_of_word_completion(self):
        debug = self.start(f"""edit {q(self.source)}
set-option window completers option=lsp_completions filename word=all
nrepl-completion-enable
echo -debug "COMPLETERS %opt{{completers}}"
""")
        self.assertIn('COMPLETERS option=lsp_completions option=nrepl_completions '
                      'filename word=all', debug)

    def test_enabling_completion_twice_does_not_list_it_twice(self):
        debug = self.start(f"""edit {q(self.source)}
nrepl-completion-enable
nrepl-completion-enable
echo -debug "COMPLETERS %opt{{completers}}"
""")
        line = [row for row in debug.splitlines() if row.startswith('COMPLETERS')][0]
        self.assertEqual(line.count('option=nrepl_completions'), 1, line)

    def test_doc_reports_the_arglists_and_docstring_the_running_image_holds(self):
        self.support_command('nrepl-op', self.source, 'eval',
                             'code=(ns demo) (defn add "Adds a and b." [a b] (+ a b))', 'ns=user')
        debug, _ = self.edit('(ns demo)\n\nadd\n', """execute-keys '3g1l'
nrepl-doc-word
echo -debug REPORT %opt{nrepl_report}
""")
        self.assertIn('REPORT nrepl: demo/add [a b]', debug)

    def test_doc_of_a_symbol_the_server_does_not_know_says_so(self):
        debug, _ = self.edit('(ns demo)\n\nzzznope\n', """execute-keys '3g1l'
nrepl-doc-word
echo -debug REPORT %opt{nrepl_report}
""")
        self.assertIn('REPORT nrepl: the server knows no zzznope', debug)

    def test_goto_definition_opens_the_file_the_repl_loaded_the_var_from(self):
        self.support_command('nrepl-op', self.source, 'eval',
                             'code=(load-file "' + str(self.source) + '")', 'ns=user')
        self.source.write_text('(ns demo)\n\n(defn add [a b] (+ a b))\n')
        self.support_command('nrepl-op', self.source, 'eval',
                             'code=(load-file "' + str(self.source) + '")', 'ns=user')
        debug = self.start(f"""edit {q(self.source)}
execute-keys '3g8l'
nrepl-goto-definition
echo -debug "JUMP %val{{buffile}}:%val{{cursor_line}}"
echo -debug REPORT %opt{{nrepl_report}}
""")
        self.assertIn(f'JUMP {self.source}:1', debug)
        self.assertIn(f'REPORT nrepl: demo/add at {self.source}:1', debug)

    def test_the_refresh_verb_names_the_op_the_babashka_server_does_not_carry(self):
        result = self.support_command('nrepl-refresh-command', self.source, '', '', 'changed')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(result.stdout.startswith('nrepl-announce '), result.stdout)
        self.assertIn('no refresh op', result.stdout)
        self.assertIn('Babashka', result.stdout)

    def test_each_refresh_verb_names_its_own_missing_op(self):
        for verb, op in [('all', 'refresh-all'), ('clear', 'refresh-clear')]:
            result = self.support_command('nrepl-refresh-command', self.source, '', '', verb)
            self.assertIn(f'no {op} op', result.stdout)

    def test_a_refresh_run_against_babashka_reports_rather_than_failing(self):
        result = self.support_command('nrepl-refresh', self.source, '', '', 'changed')
        self.assertIn('no refresh op', result.stdout)

    def test_log_opens_with_earlier_history_and_keeps_streaming(self):
        self.support_command('nrepl-op', self.source, 'eval', 'code=(println "earlier")', 'ns=user')
        proc = self.start(f"""edit {q(self.source)}
nrepl-log-open
echo -debug "LOGBUF %val{{bufname}}"
""", asynchronous=True)
        time.sleep(1.5)
        self.support_command('nrepl-op', self.source, 'eval', 'code=(println "later")', 'ns=user')
        time.sleep(1.5)
        self.send(f"""write {q(self.path/'log-view')}
buffer *debug*
write {q(self.path/'debug')}
quit!
""")
        proc.communicate(timeout=10)
        self.assertIn('LOGBUF *nrepl-log*', (self.path/'debug').read_text())
        log = (self.path/'log-view').read_text()
        self.assertIn('(out) earlier', log)
        self.assertIn('(out) later', log)

    def relay_processes(self):
        """Processes still streaming this project's nREPL log into the buffer."""
        log = json.loads(self.support_command('nrepl-status', self.source).stdout)['log']
        listing = subprocess.run(['ps', '-eo', 'pid,args'], capture_output=True,
                                 text=True, check=True, timeout=10)
        return [row for row in listing.stdout.splitlines()
                if 'tail' in row and log in row]

    def test_opening_the_log_then_quitting_leaves_no_relay_process(self):
        self.start(f"""edit {q(self.source)}
nrepl-log-open
echo -debug "LOGBUF %val{{bufname}}"
""")
        self.assertEqual(self.relay_processes(), [])

    def test_closing_the_log_reaps_the_relay_before_the_session_ends(self):
        proc = self.start(f"""edit {q(self.source)}
nrepl-log-open
""", asynchronous=True)
        time.sleep(1.5)
        self.assertNotEqual(self.relay_processes(), [])
        self.send('nrepl-log-close')
        time.sleep(1.5)
        surviving = self.relay_processes()
        self.send('quit!')
        proc.communicate(timeout=10)
        self.assertEqual(surviving, [])

    def test_reopening_the_log_after_a_close_keeps_one_relay_at_a_time(self):
        proc = self.start(f"""edit {q(self.source)}
nrepl-log-open
""", asynchronous=True)
        time.sleep(1.5)
        self.send('nrepl-log-close')
        self.send('nrepl-log-open')
        time.sleep(1.5)
        running = self.relay_processes()
        self.send('quit!')
        proc.communicate(timeout=10)
        self.assertEqual(len(running), 1, running)


class NreplTestsAgainstJvm(KakouneSession):
    """The test verbs against a real JVM nREPL carrying cider-nrepl."""

    NREPL_DEPS = ('{:deps {nrepl/nrepl {:mvn/version "1.7.0"}'
                  ' cider/cider-nrepl {:mvn/version "0.62.2"}'
                  ' refactor-nrepl/refactor-nrepl {:mvn/version "3.14.0"}}}')
    MIDDLEWARE = '[cider.nrepl/cider-middleware,refactor-nrepl.middleware/wrap-refactor]'
    SOURCE = '(ns demo.core)\n\n(defn add [a b]\n  (+ a b))\n'
    TESTS = ('(ns demo.core-test\n'
             '  (:require [clojure.test :refer [deftest is testing]]\n'
             '            [demo.core :as core]))\n'
             '\n'
             '(deftest add-works\n'
             '  (is (= 3 (core/add 1 2))))\n'
             '\n'
             '(deftest add-fails\n'
             '  (testing "deliberate failure"\n'
             '    (is (= 99 (core/add 1 2)))))\n'
             '\n'
             '(deftest add-errors\n'
             '  (is (= 1 (core/add 1 nil))))\n')
    # The line the failing assertion of add-fails sits on, and the line the
    # deftest of add-errors starts at -- the error itself is thrown in the JDK.
    FAIL_LINE, ERROR_LINE = 10, 12

    def setUp(self):
        binary = Path.home()/'.local/bin/clojure'
        if not binary.exists():
            self.skipTest('the Clojure CLI is not installed')
        super().setUp()
        (self.path/'deps.edn').write_text('{:paths ["src" "test"]}\n')
        (self.path/'src'/'demo').mkdir(parents=True)
        (self.path/'test'/'demo').mkdir(parents=True)
        self.source = self.path/'src'/'demo'/'core.clj'
        self.tests = self.path/'test'/'demo'/'core_test.clj'
        self.source.write_text(self.SOURCE)
        self.tests.write_text(self.TESTS)
        self.addCleanup(self.stop_daemon)
        server = subprocess.Popen(
            [str(binary), '-Sdeps', self.NREPL_DEPS, '-M', '-m', 'nrepl.cmdline',
             '--middleware', self.MIDDLEWARE],
            cwd=self.path, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        self.addCleanup(lambda: server.wait(timeout=20))
        self.addCleanup(server.terminate)
        for _ in range(3000):
            if (self.path/'.nrepl-port').exists():
                break
            time.sleep(.02)
        else:
            self.fail('the JVM nREPL did not publish .nrepl-port')
        self.support_command('nrepl-status', self.tests, timeout=120)

    def support_command(self, *args, timeout=120):
        return subprocess.run(['python3', str(ROOT/'support.py'), *map(str, args)],
                              capture_output=True, text=True, timeout=timeout)

    def stop_daemon(self):
        self.support_command('nrepl-shutdown', self.tests, timeout=20)
        for path in support.nrepl_paths(support.nrepl_root(self.tests)).values():
            Path(path).unlink(missing_ok=True)

    def run_tests(self, verb, *targets):
        result = self.support_command('nrepl-test', self.tests, verb, '', '', *targets,
                                      timeout=300)
        return result.stdout

    def test_a_namespace_run_reports_every_failure_at_a_clojure_source_line(self):
        report = self.run_tests('namespace', 'demo.core-test')
        self.assertIn(f'{self.tests}:{self.FAIL_LINE}:1: error: FAIL '
                      f'demo.core-test/add-fails', report)
        self.assertIn(f'{self.tests}:{self.ERROR_LINE}:1: error: ERROR '
                      f'demo.core-test/add-errors', report)
        self.assertIn('nrepl: 3 tests, 1 passed, 1 failed, 1 errored', report)

    def test_an_error_thrown_inside_the_jdk_still_points_at_clojure_source(self):
        report = self.run_tests('namespace', 'demo.core-test')
        self.assertNotIn('.java:', report)

    def test_a_single_test_runs_only_itself(self):
        report = self.run_tests('var', 'demo.core-test/add-works')
        self.assertIn('nrepl: 1 test, 1 passed, 0 failed, 0 errored', report)

    def test_a_project_run_covers_every_namespace(self):
        self.assertIn('nrepl: 3 tests,', self.run_tests('all'))

    def test_the_rerun_verb_runs_only_what_failed_last_time(self):
        self.run_tests('namespace', 'demo.core-test')
        self.assertIn('nrepl: 2 tests, 0 passed, 1 failed, 1 errored', self.run_tests('rerun'))

    def test_the_expected_and_actual_values_reach_the_log_not_the_report(self):
        report = self.run_tests('namespace', 'demo.core-test')
        self.assertNotIn('actual', report.split('FAIL demo.core-test/add-fails')[0])
        log = json.loads(self.support_command('nrepl-status', self.tests).stdout)['log']
        text = Path(log).read_text()
        self.assertIn('; FAIL demo.core-test/add-fails', text)
        self.assertIn('context:  deliberate failure', text)
        self.assertRegex(text, r'expected:.*99')
        self.assertRegex(text, r'actual:.*3')

    def refresh(self, verb):
        return self.support_command('nrepl-refresh', self.source, '', '', verb,
                                    timeout=300).stdout

    def lookup(self, namespace, symbol):
        """Warm the info op, whose first call on a JVM server is the slow one."""
        return self.support_command('nrepl-op', self.source, 'info', 'ns=' + namespace,
                                    'sym=' + symbol).stdout

    def scratch(self, body):
        source = self.path/'src'/'demo'/'scratch.clj'
        source.write_text(body)
        return source

    def test_doc_answers_from_the_running_image_with_arglists_and_docstring(self):
        self.support_command("nrepl-op", self.source, 'eval', "code=(require 'demo.core)",
                             'ns=user')
        self.lookup('demo.core', 'add')
        source = self.scratch('(ns demo.core)\n\nadd\n')
        debug = self.start(f"""edit {q(source)}
execute-keys '3g2l'
nrepl-doc-word
echo -debug REPORT %opt{{nrepl_report}}
""")
        self.assertIn('REPORT nrepl: demo.core/add [a b]', debug)

    def test_goto_definition_jumps_to_the_line_the_var_was_defined_on(self):
        self.support_command("nrepl-op", self.source, 'eval', "code=(require 'demo.core)",
                             'ns=user')
        self.lookup('demo.core', 'add')
        source = self.scratch('(ns demo.core)\n\nadd\n')
        debug = self.start(f"""edit {q(source)}
execute-keys '3g2l'
nrepl-goto-definition
echo -debug "JUMP %val{{buffile}}:%val{{cursor_line}}"
""")
        self.assertIn(f'JUMP {self.source}:3', debug)

    def test_a_repl_defined_var_says_it_has_no_file_rather_than_failing(self):
        self.support_command('nrepl-op', self.source, 'eval', 'code=(def repl-only 42)',
                             'ns=user')
        self.lookup('user', 'repl-only')
        source = self.scratch('(ns user)\n\nrepl-only\n')
        debug = self.start(f"""edit {q(source)}
execute-keys '3g2l'
nrepl-goto-definition
echo -debug REPORT %opt{{nrepl_report}}
""")
        self.assertIn('REPORT nrepl: user/repl-only was defined at the REPL', debug)

    def test_a_refresh_reloads_the_namespaces_the_project_carries(self):
        report = self.refresh('changed')
        self.assertIn('nrepl: refreshed', report)
        self.assertIn('demo.core', report)

    def test_a_refresh_with_nothing_changed_since_says_so(self):
        self.refresh('changed')
        self.assertIn('nothing to reload', self.refresh('changed'))

    def test_a_namespace_that_fails_to_reload_is_named_with_its_exception(self):
        broken = self.path/'src'/'demo'/'broken.clj'
        broken.write_text('(ns demo.broken)\n\n(def boom (/ 1 0))\n')
        report = self.refresh('changed')
        self.assertIn('nrepl: refresh failed in demo.broken', report)
        self.assertIn('broken.clj:3', report)
        self.assertIn(':nrepl-log-open', report)
        log = json.loads(self.support_command('nrepl-status', self.source).stdout)['log']
        text = Path(log).read_text()
        self.assertIn('Divide by zero', text)
        self.assertIn('cause:', text)

    def test_clearing_the_cache_makes_the_next_refresh_reload_everything(self):
        self.refresh('changed')
        self.assertIn('cache is cleared', self.refresh('clear'))
        self.assertIn('nrepl: refreshed', self.refresh('changed'))

    def test_refresh_all_reloads_what_a_plain_refresh_would_have_skipped(self):
        self.refresh('changed')
        self.assertIn('demo.core', self.refresh('all'))

    def test_the_refresh_verb_dispatches_without_holding_the_editor(self):
        debug = self.start(f"""edit {q(self.source)}
nrepl-refresh-changed
echo -debug REPORT %opt{{nrepl_report}}
""")
        self.assertIn('REPORT nrepl: reloading the namespaces that changed', debug)

    def test_a_failure_in_the_make_buffer_jumps_to_the_line_that_failed(self):
        proc = self.start(f"""edit {q(self.tests)}
nrepl-test-namespace
""", asynchronous=True)
        # :make streams its output into the buffer from a background process.
        time.sleep(25)
        self.send(f"""buffer *make*
write {q(self.path/'make-buffer')}
make-next-error
echo -to-file {q(self.path/'jump')} -- "JUMP %val{{bufname}}:%val{{cursor_line}} REPORT %opt{{nrepl_report}}"
quit!
""")
        proc.communicate(timeout=20)
        made = (self.path/'make-buffer').read_text()
        self.assertIn(f'{self.tests}:{self.ERROR_LINE}:1: error: ERROR', made)
        jumped = (self.path/'jump').read_text()
        self.assertIn(f'JUMP {self.tests}:{self.ERROR_LINE}', jumped)
        self.assertIn('REPORT nrepl: 3 tests, 1 passed, 1 failed, 1 errored', jumped)


if __name__ == '__main__':
    unittest.main()
