vim.g.mapleader = ' '
vim.g.maplocalleader = ','

-- Options
vim.o.number = true
vim.o.relativenumber = true
vim.o.signcolumn = 'yes'
vim.o.cursorline = true
vim.o.expandtab = true
vim.o.shiftwidth = 2
vim.o.tabstop = 2
vim.o.smartindent = true
vim.o.wrap = false
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.undofile = true
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.termguicolors = true
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.completeopt = 'menuone,noselect,popup'
vim.o.pumheight = 10
vim.o.scrolloff = 8
vim.o.sidescrolloff = 8
vim.o.mouse = 'a'
-- OSC 52 clipboard (works over SSH/tmux)
vim.g.clipboard = {
  name = 'OSC 52',
  copy = {
    ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
    ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
  },
  paste = {
    ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
    ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
  },
}
vim.o.clipboard = 'unnamedplus'
vim.o.showmode = false
vim.o.showtabline = 0
vim.o.laststatus = 3
vim.o.statusline = ' %f %m%r%h%w%=%y %l:%c '

vim.g['conjure#filetypes'] = { 'clojure' }

vim.pack.add({
  'https://github.com/aktersnurra/no-clown-fiesta.nvim',
  'https://github.com/nvim-treesitter/nvim-treesitter',
  'https://github.com/RRethy/nvim-treesitter-endwise',
  'https://github.com/echasnovski/mini.nvim',
  'https://github.com/rafamadriz/friendly-snippets',
  'https://github.com/stevearc/oil.nvim',
  'https://github.com/zk-org/zk-nvim',
  'https://github.com/Olical/conjure',
  'https://github.com/gpanders/nvim-parinfer',
  'https://github.com/zbirenbaum/copilot.lua',
  'https://github.com/MeanderingProgrammer/render-markdown.nvim',
  'https://github.com/mbbill/undotree',
  'https://github.com/christoomey/vim-tmux-navigator',
})

local ok = pcall(vim.cmd.colorscheme, 'no-clown-fiesta')
if not ok then vim.cmd.colorscheme('default') end

local function setup(name, opts)
  local ok, mod = pcall(require, name)
  if ok and mod.setup then mod.setup(opts or {}) end
end

local ok_icons, mini_icons = pcall(require, 'mini.icons')
if ok_icons then
  mini_icons.setup()
  mini_icons.tweak_lsp_kind()
end

setup('mini.pairs')
setup('mini.surround')
setup('mini.diff')

local ok_snip, mini_snippets = pcall(require, 'mini.snippets')
if ok_snip then
  mini_snippets.setup({
    snippets = { mini_snippets.gen_loader.from_lang() },
  })
end

setup('mini.completion', {
  delay = { completion = 50, info = 100, signature = 50 },
  lsp_completion = { source_func = 'omnifunc', auto_setup = true },
  fallback_action = '<C-n>',
  mappings = { force_twostep = '<C-Space>', force_fallback = '<M-Space>' },
})
setup('mini.pick')
setup('mini.git')
setup('mini.ai')
setup('mini.bracketed')
setup('mini.move')
setup('oil', { default_file_explorer = true })
setup('zk', { picker = 'select' })
setup('render-markdown')
vim.keymap.set('n', '<leader>m', '<Cmd>RenderMarkdown toggle<CR>', { desc = 'Toggle markdown render' })

setup('copilot', {
  suggestion = {
    auto_trigger = true,
    keymap = { accept = '<M-l>', next = '<M-]>', prev = '<M-[>', dismiss = '<M-h>' },
  },
  panel = { enabled = false },
  filetypes = { markdown = true, yaml = true },
})

vim.g.parinfer_filetypes = { 'clojure' }

vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })

local ok, ts = pcall(require, 'nvim-treesitter.configs')
if ok then
  ts.setup({
    ensure_installed = { 'rust', 'python', 'lua', 'zig', 'c', 'cpp', 'clojure', 'markdown', 'markdown_inline', 'vimdoc' },
    highlight = { enable = true },
    indent = { enable = true },
    endwise = { enable = true },
  })
end

vim.lsp.config('*', { root_markers = { '.git' } })
vim.lsp.enable({ 'rust_analyzer', 'ruff', 'zls', 'clangd', 'clojure_lsp', 'lua_ls' })

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp-attach', {}),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then return end
    local buf = args.buf

    if client:supports_method('textDocument/formatting') then
      vim.api.nvim_create_autocmd('BufWritePre', {
        group = vim.api.nvim_create_augroup('lsp-format-' .. buf, {}),
        buffer = buf,
        callback = function()
          vim.lsp.buf.format({ bufnr = buf, id = client.id, timeout_ms = 1000 })
        end,
      })
    end

    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
    end
    map('n', 'gd', vim.lsp.buf.definition, 'Go to definition')
    map('n', 'gr', vim.lsp.buf.references, 'Go to references')
    map('n', 'grn', vim.lsp.buf.rename, 'Rename symbol')
    map('n', 'gra', vim.lsp.buf.code_action, 'Code action')
    map('n', '<leader>f', function() vim.lsp.buf.format({ async = true }) end, 'Format buffer')
    map('n', '<leader>e', vim.diagnostic.open_float, 'Show diagnostic')
    map('n', '[d', function() vim.diagnostic.jump({ count = -1 }) end, 'Prev diagnostic')
    map('n', ']d', function() vim.diagnostic.jump({ count = 1 }) end, 'Next diagnostic')
  end,
})

vim.keymap.set('i', '<Tab>', function()
  if vim.fn.pumvisible() == 1 then
    return '<C-n>'
  elseif vim.snippet.active({ direction = 1 }) then
    return '<Cmd>lua vim.snippet.jump(1)<CR>'
  else
    return '<Tab>'
  end
end, { expr = true })

vim.keymap.set('i', '<S-Tab>', function()
  if vim.fn.pumvisible() == 1 then
    return '<C-p>'
  elseif vim.snippet.active({ direction = -1 }) then
    return '<Cmd>lua vim.snippet.jump(-1)<CR>'
  else
    return '<S-Tab>'
  end
end, { expr = true })

vim.keymap.set('i', '<CR>', function()
  if vim.fn.pumvisible() == 1 and vim.fn.complete_info().selected ~= -1 then
    return '<C-y>'
  end
  -- Handle pair expansion: {|} -> {\n  |\n}
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local before = line:sub(col, col)
  local after = line:sub(col + 1, col + 1)
  local pairs = { ['('] = ')', ['['] = ']', ['{'] = '}' }
  if pairs[before] == after then
    return '<CR><CR><Up><End><C-f>'
  end
  return '<CR>'
end, { expr = true })

vim.diagnostic.config({
  virtual_text = { spacing = 4, prefix = '' },
  signs = true,
  underline = true,
  update_in_insert = false,
})

local term_buf, term_win = nil, nil
local function toggle_terminal()
  if term_win and vim.api.nvim_win_is_valid(term_win) then
    vim.api.nvim_win_hide(term_win)
    term_win = nil
  else
    if term_buf and vim.api.nvim_buf_is_valid(term_buf) then
      term_win = vim.api.nvim_open_win(term_buf, true, {
        split = 'below', height = 15,
      })
    else
      vim.cmd('botright 15split | terminal')
      term_buf = vim.api.nvim_get_current_buf()
      term_win = vim.api.nvim_get_current_win()
      vim.bo[term_buf].buflisted = false
    end
    vim.cmd('startinsert')
  end
end
vim.keymap.set({ 'n', 't' }, '<leader>t', toggle_terminal, { desc = 'Toggle terminal' })

local ok_pick, pick = pcall(require, 'mini.pick')
if ok_pick then
  vim.keymap.set('n', '<leader><leader>', pick.builtin.files, { desc = 'Find files' })
  vim.keymap.set('n', '<leader>/', pick.builtin.grep_live, { desc = 'Live grep' })
  vim.keymap.set('n', '<leader>b', pick.builtin.buffers, { desc = 'Buffers' })
  vim.keymap.set('n', '<leader>h', pick.builtin.help, { desc = 'Help' })
end

vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
vim.keymap.set('n', '<Esc>', '<Cmd>nohlsearch<CR>', { desc = 'Clear search highlight' })
vim.keymap.set('n', '<leader>w', '<Cmd>w<CR>', { desc = 'Save file' })
vim.keymap.set('n', '<leader>xd', vim.diagnostic.setqflist, { desc = 'Diagnostics to quickfix' })
vim.keymap.set('n', '<leader>u', '<Cmd>UndotreeToggle<CR>', { desc = 'Toggle undotree' })
vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Window left' })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Window down' })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'Window up' })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Window right' })

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('close-with-q', {}),
  pattern = { 'help', 'qf', 'man', 'notify', 'checkhealth' },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set('n', 'q', '<Cmd>close<CR>', { buffer = event.buf, silent = true })
  end,
})

if vim.env.TMUX then
  vim.keymap.set('n', '<C-h>', '<Cmd>TmuxNavigateLeft<CR>', { desc = 'Navigate left' })
  vim.keymap.set('n', '<C-j>', '<Cmd>TmuxNavigateDown<CR>', { desc = 'Navigate down' })
  vim.keymap.set('n', '<C-k>', '<Cmd>TmuxNavigateUp<CR>', { desc = 'Navigate up' })
  vim.keymap.set('n', '<C-l>', '<Cmd>TmuxNavigateRight<CR>', { desc = 'Navigate right' })
end

vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('yank-highlight', {}),
  callback = function() vim.hl.on_yank({ timeout = 200 }) end,
})
