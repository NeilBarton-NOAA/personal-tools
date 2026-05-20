syntax on
filetype plugin on
set expandtab
set tabstop=4
set statusline+=%F
set autoindent
set laststatus=2
set hlsearch
set ruler
set number
command V visual
imap <C-c> ############
imap <C-f> !!!!!!!!!!!!
nmap <F5> a<C-R>=strftime("%Y-%m-%d %a %I:%M %p UTC")<CR><Esc>
imap <F5> <C-R>=strftime("%Y-%m-%d %a %I:%M %p UTC")<CR>
nmap <F3> a<C-R>=strftime("Neil P. Barton (NOAA-EMC), %Y-%m-%d %a %I:%M %p UTC")<CR><Esc>
imap <F3> <C-R>=strftime(" Neil P. Barton (NOAA-EMC), %Y-%m-%d %a %I:%M %p UTC")<CR>
autocmd BufRead,BufNewFile *.rc set filetype=cfg
autocmd BufRead,BufNewFile *.cylc set filetype=cfg
autocmd BufRead,BufNewFile *.com set filetype=csh
autocmd BufRead,BufNewFile REPO set filetype=sh
autocmd BufRead,BufNewFile CONFIG* set filetype=sh
autocmd BufRead,BufNewFile *.def set filetype=sh
autocmd BufRead,BufNewFile *.h set filetype=fortran
autocmd BufRead,BufNewFile *.F90 set filetype=fortran
autocmd BufRead,BufNewFile *.md set filetype=conf
inoremap <Esc>Oy 9



