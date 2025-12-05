vim.g.mapleader = ' '
vim.g.maplocalleader = ','

-- Options
local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.signcolumn = 'yes'
opt.statuscolumn = '%=%{v:relnum?v:relnum:v:lnum} %s'
opt.mouse = 'a'
opt.showmode = false
opt.scrolloff = 10
opt.cmdheight = 0
opt.clipboard = 'unnamedplus'
if vim.env.SSH_TTY then
  vim.g.clipboard = {
    name = 'OSC 52',
    copy = {
      ['+'] = require('vim.ui.clipboard.osc52').copy '+',
      ['*'] = require('vim.ui.clipboard.osc52').copy '*',
    },
    paste = {
      ['+'] = function()
        return vim.fn.getreg '+'
      end,
      ['*'] = function()
        return vim.fn.getreg '*'
      end,
    },
  }
end
opt.updatetime = 250
opt.timeoutlen = 300
opt.expandtab = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
opt.wrap = false
opt.ignorecase = true
opt.smartcase = true
opt.undofile = true
opt.splitright = true
opt.splitbelow = true
opt.smoothscroll = true
opt.confirm = true
opt.foldmethod = 'expr'
opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
opt.foldenable = false
opt.foldlevel = 99
opt.completeopt = 'menuone,noinsert,noselect'

-- Statusline (minimal native)
opt.laststatus = 2
opt.statusline = [[%f %m%r%h%w%=%{v:lua.vim.lsp.status()} %l:%c %p%%]]

-- Keymaps
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.keymap.set('n', '<C-h>', '<C-w>h')
vim.keymap.set('n', '<C-j>', '<C-w>j')
vim.keymap.set('n', '<C-k>', '<C-w>k')
vim.keymap.set('n', '<C-l>', '<C-w>l')
vim.keymap.set('n', '<S-l>', '<cmd>bnext<cr>')
vim.keymap.set('n', '<S-h>', '<cmd>bprevious<cr>')
vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')
vim.keymap.set('v', 'p', '"_dP')
vim.keymap.set('v', '<', '<gv')
vim.keymap.set('v', '>', '>gv')
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')
vim.keymap.set('n', '<C-s>', '<cmd>w<cr>')
vim.keymap.set('i', '<C-s>', '<Esc><cmd>w<cr>')
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open diagnostic float' })

-- Diagnostics
vim.diagnostic.config {
  severity_sort = true,
  float = { border = 'rounded', source = true },
  underline = { severity = vim.diagnostic.severity.ERROR },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '󰅚',
      [vim.diagnostic.severity.WARN] = '󰀪',
      [vim.diagnostic.severity.INFO] = '󰋽',
      [vim.diagnostic.severity.HINT] = '󰌶',
    },
  },
  virtual_text = { spacing = 2 },
}

-- Autocmds
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.hl.on_yank()
  end,
})

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    local buf = args.buf
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = buf, desc = 'Go to definition' })
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { buffer = buf, desc = 'Go to declaration' })
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, { buffer = buf, desc = 'References' })
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, { buffer = buf, desc = 'Go to implementation' })
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = buf, desc = 'Hover' })
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { buffer = buf, desc = 'Code action' })
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { buffer = buf, desc = 'Rename' })
    if client and client:supports_method 'textDocument/documentHighlight' then
      local group = vim.api.nvim_create_augroup('lsp-highlight-' .. buf, { clear = true })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = buf,
        group = group,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = buf,
        group = group,
        callback = vim.lsp.buf.clear_references,
      })
    end
  end,
})

vim.api.nvim_create_autocmd('BufReadPost', {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(0) then
      vim.api.nvim_win_set_cursor(0, mark)
    end
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'help', 'qf', 'checkhealth', 'man' },
  callback = function()
    vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = true })
  end,
})

vim.api.nvim_create_autocmd('VimResized', {
  callback = function()
    vim.cmd 'tabdo wincmd ='
  end,
})

-- User commands
vim.api.nvim_create_user_command('W', 'w', {})
vim.api.nvim_create_user_command('Wq', 'wq', {})

-- LSP servers (nvim 0.11+ style)
vim.lsp.enable { 'lua_ls', 'rust_analyzer', 'zls', 'clojure_lsp', 'ruff', 'gleam' }

-- Bootstrap mini.deps
local path_package = vim.fn.stdpath 'data' .. '/site/'
local mini_path = path_package .. 'pack/deps/start/mini.nvim'
if not vim.uv.fs_stat(mini_path) then
  vim.cmd 'echo "Installing mini.nvim..." | redraw'
  vim.fn.system { 'git', 'clone', '--filter=blob:none', 'https://github.com/echasnovski/mini.nvim', mini_path }
  vim.cmd 'packadd mini.nvim | helptags ALL'
end
require('mini.deps').setup { path = { package = path_package } }

local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

-- Immediate loading (colorscheme, core functionality)
now(function()
  add 'webhooked/kanso.nvim'
  require('kanso').setup { disableItalics = true, background = { dark = 'zen', light = 'pearl' } }
  vim.cmd.colorscheme 'kanso'
end)

now(function()
  add { source = 'nvim-treesitter/nvim-treesitter', hooks = {
    post_checkout = function()
      vim.cmd 'TSUpdate'
    end,
  } }
  require('nvim-treesitter.configs').setup {
    ensure_installed = { 'bash', 'c', 'clojure', 'elixir', 'gleam', 'go', 'lua', 'rust', 'zig', 'markdown', 'vim', 'vimdoc', 'toml', 'json', 'yaml' },
    auto_install = true,
    highlight = { enable = true },
    indent = { enable = true },
  }
end)

now(function()
  add 'neovim/nvim-lspconfig'
end)

-- Mini modules
now(function()
  require('mini.icons').setup()
  require('mini.notify').setup()
  vim.notify = require('mini.notify').make_notify()
end)

later(function()
  require('mini.ai').setup { n_lines = 500 }
  require('mini.surround').setup()
  require('mini.pairs').setup()
  require('mini.bufremove').setup()
  require('mini.trailspace').setup()
  require('mini.completion').setup { lsp_completion = { source_func = 'omnifunc', auto_setup = true } }
  vim.keymap.set('i', '<Tab>', function()
    return vim.fn.pumvisible() == 1 and '<C-n>' or '<Tab>'
  end, { expr = true })
  vim.keymap.set('i', '<S-Tab>', function()
    return vim.fn.pumvisible() == 1 and '<C-p>' or '<S-Tab>'
  end, { expr = true })
  vim.keymap.set('i', '<CR>', function()
    return vim.fn.pumvisible() == 1 and '<C-y>' or '<CR>'
  end, { expr = true })
  require('mini.move').setup {
    mappings = {
      left = '<M-S-h>',
      right = '<M-S-l>',
      down = '<M-S-j>',
      up = '<M-S-k>',
      line_left = '<M-S-h>',
      line_right = '<M-S-l>',
      line_down = '<M-S-j>',
      line_up = '<M-S-k>',
    },
  }
  require('mini.git').setup()
  require('mini.bracketed').setup()
  require('mini.hipatterns').setup {
    highlighters = {
      fixme = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'MiniHipatternsFixme' },
      hack = { pattern = '%f[%w]()HACK()%f[%W]', group = 'MiniHipatternsHack' },
      todo = { pattern = '%f[%w]()TODO()%f[%W]', group = 'MiniHipatternsTodo' },
      note = { pattern = '%f[%w]()NOTE()%f[%W]', group = 'MiniHipatternsNote' },
      hex_color = require('mini.hipatterns').gen_highlighter.hex_color(),
    },
  }
  require('mini.clue').setup {
    triggers = {
      { mode = 'n', keys = '<leader>' },
      { mode = 'x', keys = '<leader>' },
      { mode = 'n', keys = 'g' },
      { mode = 'x', keys = 'g' },
      { mode = 'n', keys = "'" },
      { mode = 'x', keys = "'" },
      { mode = 'n', keys = '`' },
      { mode = 'x', keys = '`' },
      { mode = 'n', keys = '"' },
      { mode = 'x', keys = '"' },
      { mode = 'i', keys = '<C-r>' },
      { mode = 'c', keys = '<C-r>' },
      { mode = 'n', keys = '<C-w>' },
      { mode = 'n', keys = 'z' },
      { mode = 'x', keys = 'z' },
      { mode = 'n', keys = '[' },
      { mode = 'n', keys = ']' },
    },
    clues = {
      require('mini.clue').gen_clues.builtin_completion(),
      require('mini.clue').gen_clues.g(),
      require('mini.clue').gen_clues.marks(),
      require('mini.clue').gen_clues.registers(),
      require('mini.clue').gen_clues.windows(),
      require('mini.clue').gen_clues.z(),
    },
    window = { delay = 1000 },
  }
  vim.keymap.set('n', '<leader>bd', function()
    require('mini.bufremove').delete(0, false)
  end, { desc = 'Delete buffer' })
  vim.keymap.set('n', '<leader>bq', function()
    for _, buf in ipairs(vim.fn.getbufinfo { buflisted = 1 }) do
      require('mini.bufremove').delete(buf.bufnr, false)
    end
  end, { desc = 'Delete all buffers' })
end)

-- Deferred plugins
later(function()
  add 'ibhagwan/fzf-lua'
  require('fzf-lua').setup {
    oldfiles = { include_current_session = true },
    grep = { rg_glob = true, glob_flag = '--iglob', glob_separator = '%s%-%-' },
  }
  vim.keymap.set('n', '<leader>ff', function()
    require('fzf-lua').files()
  end, { desc = 'Find files' })
  vim.keymap.set('n', '<leader>fg', function()
    require('fzf-lua').git_files()
  end, { desc = 'Git files' })
  vim.keymap.set('n', '<leader>fs', function()
    require('fzf-lua').live_grep()
  end, { desc = 'Live grep' })
  vim.keymap.set('n', '<leader>fr', function()
    require('fzf-lua').oldfiles()
  end, { desc = 'Recent files' })
  vim.keymap.set('n', '<leader>bb', function()
    require('fzf-lua').buffers { sort_mru = true, sort_lastused = true }
  end, { desc = 'Buffers' })
  vim.keymap.set('n', '<leader>/', function()
    require('fzf-lua').blines()
  end, { desc = 'Search buffer' })
end)

later(function()
  add 'stevearc/oil.nvim'
  require('oil').setup { default_file_explorer = true, columns = { 'size' }, delete_to_trash = true, skip_confirm_for_simple_edits = true }
  vim.keymap.set('n', '-', '<cmd>Oil<cr>', { desc = 'Oil file explorer' })
end)

later(function()
  add 'lewis6991/gitsigns.nvim'
  require('gitsigns').setup()
end)

later(function()
  add 'mbbill/undotree'
  vim.keymap.set('n', '<leader>u', '<cmd>UndotreeToggle<cr>', { desc = 'Undotree' })
end)

later(function()
  add 'folke/flash.nvim'
  require('flash').setup()
  vim.keymap.set({ 'n', 'x', 'o' }, 's', function()
    require('flash').jump()
  end, { desc = 'Flash' })
  vim.keymap.set({ 'n', 'x', 'o' }, 'S', function()
    require('flash').treesitter()
  end, { desc = 'Flash treesitter' })
end)

later(function()
  add 'stevearc/conform.nvim'
  require('conform').setup {
    format_on_save = { timeout_ms = 500, lsp_format = 'fallback' },
    formatters_by_ft = {
      lua = { 'stylua' },
      go = { 'gofmt', 'goimports' },
      gleam = { 'gleam' },
      zig = { 'zigfmt' },
      python = { 'ruff' },
    },
  }
end)

-- Filetype-specific: Clojure
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'clojure',
  once = true,
  callback = function()
    add 'gpanders/nvim-parinfer'
    add 'Olical/conjure'
    vim.g.parinfer_mode = 'indent'
  end,
})
