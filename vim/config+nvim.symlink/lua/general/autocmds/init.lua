
local autocmds = {
	core = {
		-- Ensure every file does full syntax highlight
		{ 'BufEnter', '*', ':syntax sync fromstart' },
        { 'BufEnter', '*', ':set signcolumn=yes'},
		-- Compile new plugins changes at save
		{
			'BufWritePost',
			'init.lua',
			'PackerCompile profile=true',
		},
	},
	extras = {
		-- Set up vim_buffer_previewer in telescope.nvim
		{ 'User', 'TelescopePreviewerLoaded', 'setlocal wrap' },
		-- Disable tabline on Dashboard
		{
			'FileType',
			'dashboard',
			'set showtabline=0 | autocmd WinLeave <buffer> set showtabline=2',
		},
	},
}

-- Set relative numbers
table.insert(autocmds['core'], {
	'BufEnter,WinEnter',
	'*',
	'if &nu | set rnu | endif',
})
table.insert(autocmds['core'], {
	'BufLeave,WinEnter',
	'*',
	'if &nu | set nornu | endif',
})

-- Set autosave
table.insert(autocmds['core'], {
	'TextChanged,TextChangedI',
	'<buffer>',
	'silent! write',
})

-- Enable auto comment
table.insert(autocmds['core'], {
	{'BufWinEnter', '*', 'setlocal formatoptions-=c formatoptions-=r formatoptions-=o'},
})

-- Enable highlight on yank
table.insert(autocmds['core'], {
	{'TextYankPost', '*', 'lua require(\'vim.highlight\').on_yank({higroup = \'Search\', timeout = 200})'},
})

-- Format on save
table.insert(autocmds['core'], {
	'BufWritePost',
	'*',
	'FormatWrite',
})

-- Preserve last editing position
table.insert(autocmds['core'], {
		'VimLeave',
		'*',
		':lua Dump_messages()',
	})
-- Create augroups
Create_augroups(autocmds)
