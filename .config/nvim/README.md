# Neovim workflow

Neovim 0.12.5, native package management and native automatic completion.
The existing plugin lockfile is retained. Kakoune is independent and unchanged.

Start `ta` in fish, then `nvim`. Fish's EDITOR/VISUAL select Kakoune; invoke
Neovim explicitly. Fish starts in vi insert mode: Escape enters normal mode;
`i` resumes insertion. Ctrl-R searches history and Alt-E edits the current
command in Kakoune.

## Completion and editing

Native `autocomplete` combines LSP suggestions and words from the current,
visible and other loaded listed buffers. Mini completion is no longer loaded.
MiniSnippets still loads friendly-snippets and exposes them through its local
LSP provider. Accepted LSP snippets use Neovim's native snippet engine; direct
MiniSnippets expansion remains supported.

- Tab/Shift-Tab: navigate the popup, then active snippet placeholders, then
  Parinfer indentation or ordinary Tab. Enter accepts only a selected item.
- Ctrl-Space: request LSP completion; Alt-Space: word completion.
- Ctrl-X Ctrl-F: native file-path completion; Ctrl-S: native signature help.
- Mini input supplies prompts. Mini pick supplies selection lists.
- Ctrl-h/j/k/l focuses editor splits; Alt-h/j/k/l resizes them.
- Alt-arrows moves lines or visual selections (Corne Nav + Alt + H/J/K/L).
- Space t toggles the embedded terminal from normal mode. One Escape reaches
  fish; two leave terminal input mode. Space reaches terminal programs unchanged.
- Parinfer owns pairs while enabled in Clojure; Mini pairs pauses accordingly.
- Clojure REPL evaluation stays with Conjure's comma-prefixed mappings.

See [native completion](https://neovim.io/doc/user/insert/#ins-autocompletion)
and [LSP completion](https://neovim.io/doc/user/lsp/#lsp-completion).

## Project commands and navigation

File, grep and Git pickers, builds, tests and runs share the nearest project
root above the source file: Zig, Gleam, Dune, Clojure/Babashka or Git markers. A file
outside a recognized project uses its directory. Scratch and terminal buffers
use Neovim's working directory. The global working directory is not changed.

| Keys | Action |
| --- | --- |
| `Space Space` | Project files |
| `Space /` | Project grep |
| `Space g` | Project Git files |
| Space b / Space o / `-` | Buffers / recent files / Oil directory view |
| Space c b / c t / c T | Build / project tests / current-file test |
| Space c r / c W / c u | Run / watch / REPL |
| Space c n / c p / c q | Next error / previous error / quickfix output |
| Space c s / c S / c D | Document symbols / workspace symbols / diagnostics |
| Space c a / c R | Code actions / rename |
| Visual Space c e / c E | Expand / shrink selection using LSP |
| Space v i | Toggle buffer inlay hints, when supported by its LSP |
| Space v d | Toggle current-line diagnostic details below the code |
| Space v f | Toggle format-on-save for this buffer |
| Space v z | Toggle folding; `za`, `zo`, `zc` work normally |
| Space S w / S r | Save named session / choose session to restore |

In the table, each slash-separated leader sequence starts with Space.
The old Space z b/t/f shortcuts remain aliases for build/test/test-file.
Native `grt` goes to a type definition; `:lsp restart` restarts a language server.

Zig defaults: `zig build`, `zig build test`, `zig test <file>`, `zig build run`.
The project must define the relevant build steps. Standalone file tests do not
inherit build.zig module imports.

Gleam defaults: `gleam build`, `gleam test`, and `gleam run`. The nearest
`gleam.toml` is both the project-command root and the language-server root.

OCaml defaults: `dune build`, `dune runtest`, `dune build --watch`, `dune utop`;
all run through `opam exec --` when available. Run prompts for the Dune
executable target, such as `bin/main.exe`. Current-file tests are project-specific.
Clojure task aliases are also project-specific; Conjure remains its REPL workflow.

Build/test commands save modified file buffers within the selected project.
Other projects and scratch buffers are excluded. They run asynchronously,
leaving complete output in quickfix with jumpable Zig/OCaml diagnostics.
Failed commands open quickfix if their list is still current. Only one build/test
runs per project at a time. Run/watch/REPL commands use terminal splits; Ctrl-C
stops a watcher. Open source in a project before starting a project command.

For custom commands, set an argument list in the source buffer. For example:

```vim
:lua vim.b.project_commands = { run = { 'opam', 'exec', '--', 'dune', 'exec', 'bin/main.exe', '--', 'argument' } }
```

These are buffer-local and are not persisted. For permanent per-project choices,
add path-scoped FileType hooks to your personal config. Project-local code is
not automatically sourced. Arguments are passed directly, without shell parsing;
use an explicit `sh -c` command only when shell syntax is intended.

## Formatting, folds and sessions

Space f and format-on-save use the same formatter: ZLS for Zig, Gleam LSP, Clojure-LSP,
OCaml-LSP, Ruff for Python, clangd for C/C++, Rust Analyzer or Lua LS. A sole
available formatter is the fallback; ambiguous multiple clients are not all run.
Set `vim.b.format_client = 'server_name'` to choose another explicitly.
Formatting waits up to three seconds. The server's formatter must be available
and configured (for example, OCamlformat and the project's .ocamlformat).

Folding prefers an attached LSP's ranges and otherwise uses Tree-sitter.
Files initially open unfolded. The new fish/OCaml parsers are installed, and
shell filetype `sh` now starts the Bash parser. Openings during a first-time
parser download fall back gracefully; reopen the buffer once installation ends.

Sessions save editor buffers and layout, not live REPL process state. Save and
restore are explicit, with files in Neovim's data/session directory. Saving an
existing name updates that session. Restore refuses to discard modified buffers.
No local Session.vim files are automatically read or written.

Rust Analyzer and Lua Language Server executables were absent at the earlier
review; their configurations remain ready for installation. Ruff is a Python
linter/formatter, not a full Python type/completion server. No extra external
language servers were installed during this change.

## Checks

```sh
nvim --headless '+luafile ~/.config/nvim/tests/workflow.lua'
nvim --headless '+luafile ~/.config/nvim/tests/native-lsp.lua'
```

Checks use temporary files and a test LSP. They exercise project roots and save
boundaries, asynchronous compiler output, formatter selection, parser loading,
sessions, mixed buffer/snippet completion, and LSP import edits plus snippet
expansion on acceptance. Run in disposable Neovim processes as above.

Restart Neovim to load this configuration. The init file is not intended to
be repeatedly sourced into an existing editor session.
