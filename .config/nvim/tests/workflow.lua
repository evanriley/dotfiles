-- Run with the normal config: nvim --headless '+luafile ~/.config/nvim/tests/workflow.lua'
local w = require('workflow')
local dir = vim.fn.tempname()
vim.fn.mkdir(dir .. '/project with space/src', 'p')
local root = dir .. '/project with space'
local function finish(ok, err)
  vim.fn.delete(dir, 'rf')
  if not ok then print(err); vim.cmd('cquit 1') end
  print('PASS: project roots/saves, real async quickfix, formatter selection, sessions, native buffer/LSP/snippet completion and acceptance')
  vim.cmd('qa!')
end
local function later(ms, fn)
  vim.defer_fn(function()
    local ok, err = pcall(fn)
    if not ok then finish(false, err) end
  end, ms)
end

local ok, err = pcall(function()
  assert(vim.o.autocomplete and vim.o.complete == 'o,.,w,b')
  assert(package.loaded['mini.completion'] == nil)
  assert(vim.fn.maparg(' t', 't') == '')
  for _, name in ipairs({ 'zls', 'ocamllsp', 'clojure_lsp', 'lua_ls' }) do vim.lsp.enable(name, false) end
  vim.fn.writefile({}, root .. '/build.zig')
  vim.cmd.edit(vim.fn.fnameescape(root .. '/src/main.zig'))
  local source = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { '// save me' })
  local other = vim.fn.bufadd(dir .. '/outside.zig')
  vim.fn.bufload(other)
  vim.api.nvim_buf_set_lines(other, 0, -1, false, { '// keep unsaved' })
  assert(w.root() == root)
  local cmd, cwd = w.command('test_file')
  assert(cmd[3] == root .. '/src/main.zig' and cwd == root)
  w.save_project(root)
  assert(vim.fn.readfile(root .. '/src/main.zig')[1] == '// save me')
  assert(vim.bo[other].modified and vim.fn.filereadable(dir .. '/outside.zig') == 0)
  local ds = w.diagnostics('src/main.zig:2:3: error: broken\nFile "src/a.ml", line 4, characters 2-8:\nError: wrong type', root)
  assert(ds[1].lnum == 2 and ds[1].filename == root .. '/src/main.zig')
  assert(ds[2].lnum == 4 and ds[2].col == 3 and ds[3].valid == 0)
  local get_clients = vim.lsp.get_clients
  vim.lsp.get_clients = function() return { { name = 'other', id = 30 }, { name = 'zls', id = 40 } } end
  assert(w.formatter(source).id == 40)
  vim.b.format_client = 'other'
  assert(w.formatter(source).id == 30)
  vim.b.format_client = nil
  vim.lsp.get_clients = get_clients
  for _, file in ipairs({ 'shell.sh', 'shell.fish', 'a.ml', 'a.mli' }) do
    vim.cmd.edit(root .. '/' .. file)
    assert(pcall(vim.treesitter.get_parser), file .. ' parser unavailable')
  end
  vim.api.nvim_set_current_buf(source)
  local sessions = require('mini.sessions')
  sessions.config.directory = dir .. '/sessions'
  vim.fn.mkdir(sessions.config.directory, 'p')
  sessions.write('test', { verbose = false })
  assert(vim.fn.filereadable(dir .. '/sessions/test') == 1)
  vim.bo[other].modified = false
  sessions.read('test', { verbose = false })
  assert(vim.api.nvim_buf_get_name(0) == root .. '/src/main.zig')
  vim.b.project_commands = { build = { 'sh', '-c', 'printf "src/main.zig:1:1: error: test failure\\n"; exit 1' } }
  w.run('build')
  assert(vim.wait(3000, function() return vim.fn.getqflist({ title = 0 }).title:find('[exit 1]', 1, true) ~= nil end))
  local qf = vim.fn.getqflist()
  assert(qf[1].lnum == 1 and vim.api.nvim_buf_get_name(qf[1].bufnr) == root .. '/src/main.zig')
  vim.cmd.cclose()
  vim.cmd.enew()
  vim.bo.filetype = 'text'
  MiniSnippets.config.snippets = { { prefix = 'nat', body = 'native(${1:value})$0', desc = 'Native test' } }
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'nativebuffer', '' })
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  later(300, function()
    vim.api.nvim_input('inat')
    later(700, function()
      local info = vim.fn.complete_info({ 'items', 'selected' })
      assert(vim.fn.pumvisible() == 1, 'no automatic popup')
      local buffer, snippet
      for i, item in ipairs(info.items) do
        if item.word == 'nativebuffer' then buffer = true end
        if item.abbr == 'nat' then snippet = i end
      end
      assert(buffer and snippet, 'buffer and LSP snippet must share the popup')
      vim.api.nvim_input(string.rep('<Tab>', snippet) .. '<CR>')
      later(300, function()
        assert(vim.api.nvim_buf_get_lines(0, 1, 2, false)[1] == 'native(value)', 'snippet did not expand')
        assert(vim.snippet.active(), 'native snippet session missing')
        -- Verify a further Tab exits the placeholder via the retained mapping.
        vim.api.nvim_input('<Tab>')
        later(200, function() finish(true) end)
      end)
    end)
  end)
end)
if not ok then finish(false, err) end
