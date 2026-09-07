#!/usr/bin/env python3
import concurrent.futures
import importlib.util
import os
from pathlib import Path
import subprocess
import tempfile
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


class Kakoune(unittest.TestCase):
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
        debug = self.start(f'''edit -scratch options
set-option buffer filetype zig
set-option buffer filetype ocaml
echo -debug RESET %opt{{run_command}} %opt{{test_file_command}} %opt{{indentwidth}}
edit {q(dune)}
echo -debug DUNE %opt{{filetype}} %opt{{build_command}}
edit {q(opam)}
echo -debug OPAM %opt{{filetype}} %opt{{comment_line}}
''')
        self.assertIn('RESET 2', debug)
        self.assertIn('DUNE lisp opam exec -- dune build', debug)
        self.assertIn('OPAM opam #', debug)

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

    def test_repl_against_babashka(self):
        binary = Path.home()/'.local/bin/bb'
        if not binary.exists():
            self.skipTest('Babashka not installed')
        (self.path/'bb.edn').write_text('{}')
        server = subprocess.Popen(['python3', str(ROOT/'support.py'), 'bb-server', str(binary)], cwd=self.path,
                                  stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        self.addCleanup(lambda: server.wait(timeout=5))
        self.addCleanup(server.terminate)
        for _ in range(100):
            if (self.path/'.nrepl-port').exists():
                break
            time.sleep(.02)
        source = self.path/'test.clj'
        source.write_text('(ns review-test)\n(+ 20 22)\n')
        proc = self.start(f'''edit {q(source)}
try %{{ nrepl-evaluate-file }} catch %{{ echo -debug ERROR: %val{{error}} }}
''', asynchronous=True)
        time.sleep(.5)
        self.send(f'''try %{{ buffer *rep*; write {q(self.path/'result')} }} catch %{{ echo -debug ERROR: %val{{error}} }}
buffer *debug*
write {q(self.path/'debug')}
quit!
''')
        proc.communicate(timeout=10)
        self.assertNotIn('ERROR:', (self.path/'debug').read_text())
        self.assertIn('42', (self.path/'result').read_text())
        self.assertIn('[exit 0]', (self.path/'result').read_text())
        self.assertEqual(source.read_text(), '(ns review-test)\n(+ 20 22)\n')


if __name__ == '__main__':
    unittest.main()
