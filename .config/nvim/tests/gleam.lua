-- Run with the normal config: nvim --headless '+luafile ~/.config/nvim/tests/gleam.lua'
local workflow = require('workflow')
local dir = vim.fn.tempname()
local root = dir .. '/gleam-project'

vim.fn.mkdir(root .. '/src', 'p')
vim.fn.writefile({ 'name = "music"', 'version = "1.0.0"', 'target = "erlang"' }, root .. '/gleam.toml')
vim.fn.writefile({ 'pub type Music {}' }, root .. '/src/music.gleam')

local function finish(ok, err)
  vim.fn.delete(dir, 'rf')
  if not ok then print(err); vim.cmd('cquit 1') end
  print('PASS: Gleam project/LSP configuration and empty-pair Enter behavior')
  vim.cmd('qa!')
end

local ok, err = pcall(function()
  vim.cmd.edit(root .. '/src/music.gleam')
  assert(vim.bo.filetype == 'gleam', 'Gleam filetype was not detected')
  vim.api.nvim_win_set_cursor(0, { 1, 15 })
  vim.api.nvim_input('a<CR><Esc>')
  vim.defer_fn(function()
    local success, failure = pcall(function()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert(not table.concat(lines, '\n'):find('\006', 1, true), 'Enter inserted a literal ^F')
      assert(vim.deep_equal(lines, { 'pub type Music {', '', '}' }),
        'empty braces expanded incorrectly: ' .. vim.inspect(lines))

      assert(vim.lsp.is_enabled('gleam'), 'Gleam LSP is not enabled')
      assert(vim.lsp.config.gleam.cmd[1] == 'gleam' and vim.lsp.config.gleam.cmd[2] == 'lsp',
        'Gleam LSP command is incorrect')
      vim.lsp.enable('gleam', false)
      assert(workflow.root() == root, 'gleam.toml was not selected as the project root')
      for action, expected in pairs({ build = 'build', test = 'test', run = 'run' }) do
        local command, cwd = workflow.command(action)
        assert(vim.deep_equal(command, { 'gleam', expected }) and cwd == root,
          'incorrect Gleam ' .. action .. ' command')
      end
    end)
    finish(success, failure)
  end, 300)
end)

if not ok then finish(false, err) end
