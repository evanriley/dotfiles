-- Set colorscheme
Execute('set background=dark')
Execute('colorscheme tokyonight')

-- Set colors based on  environment (GUI, TUI)
if Fn.exists('+termguicolors') then
	Opt('o', 'termguicolors', true)
elseif Fn.exists('+guicolors') then
	Opt('o', 'guicolors', true)
end
