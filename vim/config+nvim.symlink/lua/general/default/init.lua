---[[---------------------------------------]]---
--         default - Doom Nvim defaults        --
--              Author: NTBBloodbath           --
--              License: MIT                   --
---[[---------------------------------------]]---
-- Set and load default options
function Default_options()
    local o = vim.o
    ----- Default Neovim configurations
    Cmd('highlight WhichKeyFloat guibg=#202328')

	-- Set default options
	Cmd('syntax on')
	Cmd('filetype plugin indent on')
	Opt('o', 'encoding', 'utf-8')

	-- Global options
	Opt('o', 'wildmenu', true)
	Opt('o', 'autoread', true)
	Opt('o', 'smarttab', true)
	Opt('o', 'hidden', true)
	Opt('o', 'hlsearch', true)
	Opt('o', 'laststatus', 2)
	Opt('o', 'backspace', 'indent,eol,start')
	Opt('o', 'updatetime', 100)
	Opt('o', 'timeoutlen', 200)
	Opt(
		'o',
		'completeopt',
		'menu,menuone,preview,noinsert,noselect'
	)
    Cmd('set shortmess += "atsc"')
	Opt('o', 'inccommand', 'split')
	Opt('o', 'path', '**')
    --Cmd('set signcolumn=yes')

	-- Buffer options
	Opt('b', 'autoindent', true)
	Opt('b', 'smartindent', true)

    -- Use clipboard outside vim
        Opt('o', 'clipboard', 'unnamedplus')

        Cmd('set cursorline')
        Cmd('set nocursorline')

    -- Automatic split locations
        Opt('o', 'splitright', true)

        Opt('o', 'splitbelow', true)

    -- Enable scroll off
        Opt('o', 'scrolloff', 4)

    -- Enable showmode
        Cmd('set showmode')

    -- disable wrapping
        Cmd('set nowrap')

    -- Enable swap files
	Cmd('set swapfile')

    -- Set numbering
	Cmd('set nu rnu')


    -- Set local-buffer options
	Execute('let &expandtab = 1')
	Execute('let &tabstop = 4')
	Execute('let &shiftwidth = 4')
	Execute('let &softtabstop = 4')
	Execute('let &colorcolumn = 120')
	Execute('let &conceallevel = 0')
end

