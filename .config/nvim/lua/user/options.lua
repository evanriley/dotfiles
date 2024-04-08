vim.g.mapleader = ' ' -- Set <space> as the leader key
vim.g.maplocalleader = ',' -- Set ',' as localleader

-- [[ Setting options ]]
vim.opt.number = true -- Make line numbers default
vim.opt.relativenumber = true -- Make the line numbers relative
vim.opt.mouse = 'a' -- Enable mouse mode, can be useful for resizing splits
vim.opt.showmode = false -- Don't show the mode, since it's already in the status line
vim.opt.clipboard = 'unnamedplus' -- Sync clipboard between OS and Neovim.
vim.opt.breakindent = true -- Enable break indent
vim.opt.undofile = true -- Save undo history
vim.opt.ignorecase = true -- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.smartcase = true -- ^^
vim.opt.signcolumn = 'yes' -- Keep signcolumn on by default
vim.opt.updatetime = 250 -- Decrease update time
vim.opt.timeoutlen = 300 -- Decrease mapped sequence wait time
vim.opt.splitright = true -- Always open split to right
vim.opt.splitbelow = true -- Always open split below
vim.opt.list = true -- Sets how neovim will display certain whitespace characters in the editor.
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.opt.inccommand = 'split' -- Preview substitutions live
vim.opt.cursorline = true -- Show which line your cursor is on
vim.opt.scrolloff = 10 -- Miniumum number of screen lines to keep above and below the cursor.
