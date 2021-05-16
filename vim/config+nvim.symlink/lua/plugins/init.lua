-- Setup Packer
local packer = require('packer')
return packer.startup(function()
-- Essentials --
	
	-- Plugin manager
	use('wbthomason/packer.nvim')

	-- Auxiliar functinos for using Lua in neovim
	use('svermeulen/vimpeccable')

	-- Tree-sitter
	use({
		'nvim-treesitter/nvim-treesitter',
		run = ':TSUpdate'})

	-- Sessions
	use({
		'rmagatti/auto-session',
		requires = { 'rmagatti/session-lens' }})

-- UI --
	-- Start screen
	use('glepnir/dashboard-nvim')

	-- Colorschemes
	use({
		'ghifarit53/tokyonight-vim',
		'mhartington/oceanic-next',
		'trevordmiller/nova-vim',
		'junegunn/seoul256.vim',
		'sonph/onehalf',
		'ayu-theme/ayu-vim',
		'cocopon/iceberg.vim',
		'srcery-colors/srcery-vim',
		
	})
	

	-- Statusline
	use('glepnir/galaxyline.nvim')

	-- Better splits
	-- Use the 'cust_filetypes' branch for the ignore filetypes feature
	use({
		'beauwilliams/focus.nvim',
		branch = 'cust_filetypes'
	})

	-- Better terminal
	use('akinsho/nvim-toggleterm.lua')

	-- Tree like view for LSP symbols
	use('simrat39/symbols-outline.nvim')

	-- Which-key
	-- Keybindings menu
	use('folke/which-key.nvim')

-- Fuzzy Search --

	-- Telescope
	use({
		'nvim-telescope/telescope.nvim',
		requires = { { 'nvim-lua/popup.nvim' }, { 'nvim-lua/plenary.nvim' } }
	})

-- Git Stuff

	-- Git Gutter alternative, written in lua
	use('lewis6991/gitsigns.nvim')

	-- LazyGit
	use({
		'kdheepak/lazygit.nvim',
		requires = { 'nvim-lua/plenary.nvim' }
	})

-- Completion/LSP --

	-- Neovim Built-in LSP Config
	use('neovim/nvim-lspconfig')

	-- Completion
	use({
		'hrsh7th/nvim-compe',
		requires = {
			{ 'ray-x/lsp_signature.nvim' },
			{ 'onsails/lspkind-nvim' },
			{ 'norcalli/snippets.nvim' },
		}
	})

	-- LSPSaga
	use('glepnir/lspsaga.nvim')

	-- missing `:LspInstall` for `nvim-lspconfig`.
	use('kabouzeid/nvim-lspinstall')

-- File Stuff --

	-- Write & Read files without permissions (i.e in /etc)a without having to use `sudo nvim`
	use('lambdalisue/suda.vim')

	-- File formatting
	use('lukas-reineke/format.nvim')

	-- Autopairs
	use('steelsojka/pears.nvim')

	-- Editorconfig support
	use('editorconfig/editorconfig-vim')

	-- Comments
	use('b3nj5m1n/kommentary')

-- Misc --
	
    -- devicons
    use('kyazdani42/nvim-web-devicons')

	-- Colorizer
	use('norcalli/nvim-colorizer.lua')

	-- Dot-http support
	use('bayne/vim-dot-http')

	-- Emmet support
	use('mattn/emmet-vim')
end)
