vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = 'yes'
vim.opt.statuscolumn = '%=%{v:relnum?v:relnum:v:lnum} %s'
vim.opt.laststatus = 2
vim.opt.mouse = 'a'
vim.opt.showmode = false
vim.opt.scrolloff = 10
vim.opt.cmdheight = 0

-- Editing settings
vim.opt.clipboard = 'unnamedplus'
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.wrap = false
vim.opt.list = false

-- Search settings
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.hlsearch = true

-- Undo
vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath 'data' .. '/undodir'

-- Code folding
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'
vim.opt.foldenable = false
vim.opt.foldlevel = 99
