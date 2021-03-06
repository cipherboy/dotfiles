filetype plugin indent on
syntax on

set tags+=tags,./tags
set listchars=tab:__,space:.
" set list

set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set shiftround

set completeopt-=preview
autocmd BufWritePre * %s/\s\+$//e
autocmd BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal g'\"" | endif

set directory=$HOME/.vim/swapfiles//
set backupdir=$HOME/.vim/swapfiles//

set spell
set spellfile=$HOME/.vim/spell/en.utf-8.add

set noro

" set colorcolumn=79
" hi ColorColumn ctermbg=lightgrey guibg=lightgrey
