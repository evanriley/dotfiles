-- If packer.nvim is not installed then install it and install core plugins after that
local packer_install_path = Fn.stdpath('data')
	.. '/site/pack/packer/start/packer.nvim'
if Fn.empty(Fn.glob(packer_install_path)) > 0 then
	Execute(
		'silent !git clone https://github.com/wbthomason/packer.nvim '
			.. packer_install_path
	)
	Execute('packadd packer.nvim')

	-- Install plugins and then reload configs
	Execute('PackerInstall')
	Execute('luafile $MYVIMRC')
end

-- Set some configs on load
if Fn.has('vim_starting') then
	-- Set encoding
	Opt('o', 'encoding', 'utf-8')
	-- Required to use some colorschemes and improve colors
	Opt('o', 'termguicolors', true)
end

-- Load the default Neovim settings, e.g. tabs width
Default_options()

-- Load packer.nvim and load plugins settings
require('plugins')
require('general.config.load_plugins')
