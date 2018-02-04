execute pathogen#infect()

set tags+=tags,./tags
set listchars=tab:__,space:.
" set list

set tabstop=8
set shiftwidth=4
set softtabstop=4
set expandtab

set completeopt-=preview
autocmd BufWritePre * %s/\s\+$//e

" set colorcolumn=79
" hi ColorColumn ctermbg=lightgrey guibg=lightgrey

