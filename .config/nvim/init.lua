vim.g.mapleader = ' '
vim.g.maplocalleader = ','

vim.o.number = true
vim.o.relativenumber = true
vim.o.signcolumn = 'yes'
vim.o.cursorline = true
vim.o.expandtab = true
vim.o.shiftwidth = 2
vim.o.tabstop = 2
vim.o.smartindent = true
vim.o.wrap = false
vim.o.linebreak = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.undofile = true
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.splitkeep = 'screen'
vim.o.termguicolors = true
vim.o.winborder = 'rounded'
vim.o.smoothscroll = true
vim.o.confirm = true
vim.o.inccommand = 'split'
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.completeopt = 'menuone,noselect,popup,fuzzy'
vim.o.pumheight = 10
vim.o.scrolloff = 8
vim.o.sidescrolloff = 8
vim.o.mouse = 'a'
vim.o.list = true
vim.opt.listchars = { tab = '  ', trail = '.', nbsp = '+' }
vim.opt.jumpoptions:append('view')
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
vim.o.showtabline = 2
vim.o.laststatus = 3

vim.g['conjure#filetypes'] = { 'clojure' }

vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    if ev.data.kind ~= 'install' and ev.data.kind ~= 'update' then return end

    local name = ev.data.spec.name
    if name == 'nvim-treesitter' then
      if not ev.data.active then vim.cmd.packadd('nvim-treesitter') end
      vim.cmd('TSUpdate')
    elseif name == 'smart-splits.nvim' then
      vim.system({ './kitty/install-kittens.bash' }, { cwd = ev.data.path }):wait()
    end
  end,
})

vim.pack.add({
  'https://github.com/miikanissi/modus-themes.nvim',
  'https://github.com/nvim-treesitter/nvim-treesitter',
  'https://github.com/RRethy/nvim-treesitter-endwise',
  'https://github.com/nvim-mini/mini.nvim',
  'https://github.com/neovim/nvim-lspconfig',
  'https://codeberg.org/mfussenegger/nvim-dap',
  'https://github.com/rafamadriz/friendly-snippets',
  'https://github.com/stevearc/oil.nvim',
  'https://github.com/Olical/conjure',
  'https://github.com/gpanders/nvim-parinfer',
  'https://github.com/MeanderingProgrammer/render-markdown.nvim',
  'https://github.com/mbbill/undotree',
  'https://github.com/mrjones2014/smart-splits.nvim',
}, {
  confirm = false,
})

local function setup(name, opts)
  require(name).setup(opts or {})
end

setup('modus-themes', {
  style = 'auto',
  transparent = false,
})

local function apply_desktop_mode(mode)
  vim.schedule(function()
    vim.o.background = mode == 'light' and 'light' or 'dark'
    vim.cmd.colorscheme('modus')
  end)
end

local initial_mode = vim.system({ 'darkman', 'get' }, { text = true }):wait()
apply_desktop_mode(initial_mode.code == 0 and vim.trim(initial_mode.stdout) or 'dark')

local darkman_output = ''
local darkman_watch = vim.system({ 'darkman', 'watch' }, {
  text = true,
  stdout = function(_, data)
    if not data then return end
    darkman_output = darkman_output .. data
    while darkman_output:find('\n', 1, true) do
      local line
      line, darkman_output = darkman_output:match('^(.-)\n(.*)$')
      if line == 'dark' or line == 'light' then apply_desktop_mode(line) end
    end
  end,
})

setup('smart-splits')
setup('oil', { default_file_explorer = true })
setup('render-markdown')

setup('mini.ai')
setup('mini.bracketed')
setup('mini.bufremove')
setup('mini.diff')
setup('mini.extra')
setup('mini.git')
setup('mini.jump')
setup('mini.jump2d')
setup('mini.move')
setup('mini.notify')
setup('mini.pairs')
setup('mini.pick')
setup('mini.statusline', { use_icons = true })
setup('mini.surround')
setup('mini.tabline')
setup('mini.trailspace')

local icons = require('mini.icons')
icons.setup()
icons.tweak_lsp_kind()

vim.notify = require('mini.notify').make_notify()

local snippets = require('mini.snippets')
snippets.setup({
  snippets = { snippets.gen_loader.from_lang() },
})

setup('mini.completion', {
  delay = { completion = 50, info = 100, signature = 50 },
  lsp_completion = { source_func = 'omnifunc', auto_setup = true },
  fallback_action = '<C-n>',
  mappings = { force_twostep = '<C-Space>', force_fallback = '<M-Space>' },
})

vim.g.parinfer_filetypes = { 'clojure' }

local smart_splits = require('smart-splits')
local pick = require('mini.pick')
local extra = require('mini.extra')

vim.keymap.set('n', '<A-h>', smart_splits.resize_left)
vim.keymap.set('n', '<A-j>', smart_splits.resize_down)
vim.keymap.set('n', '<A-k>', smart_splits.resize_up)
vim.keymap.set('n', '<A-l>', smart_splits.resize_right)
vim.keymap.set('n', '<C-h>', smart_splits.move_cursor_left)
vim.keymap.set('n', '<C-j>', smart_splits.move_cursor_down)
vim.keymap.set('n', '<C-k>', smart_splits.move_cursor_up)
vim.keymap.set('n', '<C-l>', smart_splits.move_cursor_right)
vim.keymap.set('n', '<C-\\>', smart_splits.move_cursor_previous)
vim.keymap.set('n', '<leader><leader>h', smart_splits.swap_buf_left)
vim.keymap.set('n', '<leader><leader>j', smart_splits.swap_buf_down)
vim.keymap.set('n', '<leader><leader>k', smart_splits.swap_buf_up)
vim.keymap.set('n', '<leader><leader>l', smart_splits.swap_buf_right)

vim.keymap.set('n', '<leader>m', '<Cmd>RenderMarkdown toggle<CR>', { desc = 'Toggle markdown render' })

vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })

local treesitter = require('nvim-treesitter')
local treesitter_languages = {
  'bash', 'c', 'clojure', 'cpp', 'lua', 'markdown', 'markdown_inline', 'python', 'rust', 'vimdoc', 'zig',
}
treesitter.setup()
treesitter.install(treesitter_languages)
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'bash', 'c', 'clojure', 'cpp', 'help', 'lua', 'markdown', 'python', 'rust', 'zig' },
  callback = function()
    vim.treesitter.start()
    if vim.bo.filetype ~= 'clojure' and vim.bo.filetype ~= 'help' then
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

vim.lsp.config('*', { root_markers = { '.git' } })
vim.lsp.config('zls', {
  settings = {
    zls = {
      enable_build_on_save = true,
    },
  },
})
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
    map('n', '<leader>f', function() vim.lsp.buf.format({ async = true }) end, 'Format buffer')
    map('n', '<leader>e', vim.diagnostic.open_float, 'Show diagnostic')
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

local function zig_root()
  local root = vim.fs.root(0, { 'build.zig', 'build.zig.zon', '.git' })
  return root or vim.fn.getcwd()
end

local function run_zig(args)
  vim.cmd('botright 15split')
  vim.fn.jobstart(vim.list_extend({ 'zig' }, args), {
    cwd = zig_root(),
    term = true,
  })
  vim.cmd('startinsert')
end

vim.keymap.set('n', '<leader>zb', function() run_zig({ 'build' }) end, { desc = 'Zig build' })
vim.keymap.set('n', '<leader>zt', function() run_zig({ 'build', 'test' }) end, { desc = 'Zig build test' })
vim.keymap.set('n', '<leader>zf', function()
  run_zig({ 'test', vim.api.nvim_buf_get_name(0) })
end, { desc = 'Zig test current file' })

local dap = require('dap')
dap.adapters.lldb = {
  type = 'executable',
  command = vim.fn.exepath('lldb-dap'),
  name = 'lldb',
}
dap.configurations.zig = {
  {
    name = 'Launch Zig executable',
    type = 'lldb',
    request = 'launch',
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
    program = function()
      return vim.fn.input('Executable: ', zig_root() .. '/zig-out/bin/', 'file')
    end,
  },
}

vim.keymap.set('n', '<leader>db', dap.toggle_breakpoint, { desc = 'Debug toggle breakpoint' })
vim.keymap.set('n', '<leader>dc', dap.continue, { desc = 'Debug continue' })
vim.keymap.set('n', '<leader>di', dap.step_into, { desc = 'Debug step into' })
vim.keymap.set('n', '<leader>dn', dap.step_over, { desc = 'Debug step over' })
vim.keymap.set('n', '<leader>do', dap.step_out, { desc = 'Debug step out' })
vim.keymap.set('n', '<leader>dr', dap.repl.open, { desc = 'Debug REPL' })
vim.keymap.set('n', '<leader>dt', dap.terminate, { desc = 'Debug terminate' })

vim.keymap.set('n', '<leader><leader>', pick.builtin.files, { desc = 'Find files' })
vim.keymap.set('n', '<leader>/', pick.builtin.grep_live, { desc = 'Live grep' })
vim.keymap.set('n', '<leader>b', pick.builtin.buffers, { desc = 'Buffers' })
vim.keymap.set('n', '<leader>h', pick.builtin.help, { desc = 'Help' })
vim.keymap.set('n', '<leader>r', pick.builtin.resume, { desc = 'Resume picker' })
vim.keymap.set('n', '<leader>o', extra.pickers.oldfiles, { desc = 'Recent files' })
vim.keymap.set('n', '<leader>g', extra.pickers.git_files, { desc = 'Git files' })
vim.keymap.set('n', '<leader>q', extra.pickers.list, { desc = 'Lists' })

vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
vim.keymap.set('n', '<Esc>', '<Cmd>nohlsearch<CR>', { desc = 'Clear search highlight' })
vim.keymap.set('n', '<leader>w', '<Cmd>w<CR>', { desc = 'Save file' })
vim.keymap.set('n', '<leader>bd', function() MiniBufremove.delete(0, false) end, { desc = 'Delete buffer' })
vim.keymap.set('n', '<leader>xd', vim.diagnostic.setqflist, { desc = 'Diagnostics to quickfix' })
vim.keymap.set('n', '<leader>u', '<Cmd>UndotreeToggle<CR>', { desc = 'Toggle undotree' })
vim.keymap.set('n', '<leader>cw', '<Cmd>lua MiniTrailspace.trim()<CR>', { desc = 'Trim trailing whitespace' })
vim.keymap.set('n', '<leader>gg', '<Cmd>botright 15split | terminal lazygit<CR>', { desc = 'Lazygit' })

vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('yank-highlight', {}),
  callback = function() vim.hl.on_yank({ timeout = 200 }) end,
})

local clue = require('mini.clue')
clue.setup({
  triggers = {
    { mode = { 'n', 'x' }, keys = '<Leader>' },
    { mode = 'n', keys = '[' },
    { mode = 'n', keys = ']' },
    { mode = 'i', keys = '<C-x>' },
    { mode = { 'n', 'x' }, keys = 'g' },
    { mode = { 'n', 'x' }, keys = "'" },
    { mode = { 'n', 'x' }, keys = '`' },
    { mode = { 'n', 'x' }, keys = '"' },
    { mode = { 'i', 'c' }, keys = '<C-r>' },
    { mode = 'n', keys = '<C-w>' },
    { mode = { 'n', 'x' }, keys = 'z' },
  },
  clues = {
    clue.gen_clues.square_brackets(),
    clue.gen_clues.builtin_completion(),
    clue.gen_clues.g(),
    clue.gen_clues.marks(),
    clue.gen_clues.registers(),
    clue.gen_clues.windows(),
    clue.gen_clues.z(),
  },
})
