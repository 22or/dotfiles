source $VIMRUNTIME/defaults.vim



let g:lsp_log_file = expand('~/.vim/lsp.log')	" enable lsp logging
" let g:lsp_log_verbose = 1



call plug#begin()
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'
Plug 'prabirshrestha/vim-lsp'
Plug 'mattn/vim-lsp-settings'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'kshenoy/vim-signature'
Plug 'Valloric/vim-operator-highlight'
Plug 'wellle/context.vim'
Plug 'liuchengxu/vista.vim'
call plug#end()



" VISTA.VIM

let g:vista_default_executive='vim_lsp'	" use vim-lsp as the lsp
let g:vista#renderer#enable_icon=0	" disable icons
let g:vista_enable_centering_jump=0	" bugged; doesn't work for fzf
nm <Leader>f :Vista finder<CR>
" Vista patched: changed zz to zt in autoload/vista/finder/fzf.vim

" Jump to top hack
" function! VistaFinderWithTop()
"     Vista finder
"     augroup VistaJumpTop
"         autocmd!
"         autocmd BufEnter * call timer_start(10, {-> execute('normal! zt') }) | autocmd! VistaJumpTop
"     augroup END
" endfunction



" GTK LOG RECENT FILE

function! GtkRecentLog(path)
python3 << endpython
path = vim.eval("a:path")
recent_mgr = Gtk.RecentManager.get_default()
recent_mgr.add_item('file://' + path)
GLib.timeout_add(22, Gtk.main_quit, None)
Gtk.main()
endpython
endfunction

python3 << endpython
sys.path.insert(0, '/usr/lib/python3/dist-packages')	# Add system dist-packages BEFORE venv site-packages
import vim
import gi
import os
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, GLib
endpython



" ASYNCOMPLETE.VIM

inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <cr>    pumvisible() ? asyncomplete#close_popup() : "\<cr>"
" autocmd CompleteDone * pclose	" close on done
let g:asyncomplete_auto_completeopt = 0	" prevent completeopt from being overwritten
set completeopt=menuone,noinsert,noselect
set pumheight=10	" limit number of suggestions



" CONTEXT.VIM

let g:Context_border_indent = { -> [0, 0] }	" disable border indent
let g:context_highlight_border='LineNr'
let g:context_highlight_tag='LineNr'



" FZF.VIM

let $FZF_DEFAULT_COMMAND='fd --type f --hidden --follow . ../..'	" Default search dir
nnoremap <c-p> :Files<CR>



" VIM-LSP

" display hover popups on top and remove borders
augroup lsp_hover_tweaks
    autocmd!
    autocmd User lsp_float_opened if exists('*popup_setoptions') | call popup_setoptions(lsp#ui#vim#output#getpreviewwinid(), {
		\ 'zindex': 1000,
		\ 'borderchars': [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ']
	\ }) | endif
augroup END



" MORE BINDS

" Echoes the highlight class of the hovered text on F1
nm <silent> <F1> :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name")
    \ . '> trans<' . synIDattr(synID(line("."),col("."),0),"name")
    \ . "> lo<" . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name")
    \ . ">"<CR>

" Opens Document Diagnostics on F2
nm <silent> <F3> :LspDocumentDiagnostics<CR>
nm <silent> <F2> :LspHover<Cr>

" Invisible insert,delete hack to allow indents on blank lines
" inoremap <CR> <CR><Space><BS>
" nnoremap o o<Space><BS>
" nnoremap O O<Space><BS>



" VIM CONFIG

set undofile					" enable undo history persistence
set undodir=~/.vim/undo			" where undos are stored
set backupdir=~/.vim/backup		" where backups are stored
set directory=~/.vim/swap		" where swap files are stored
set tabstop=4					" number of spaces in one tab
set shiftwidth=4				" number of spaces for one shift command (>>)
set relativenumber						" enable line numbers
set number
set cindent						" smarter auto indenter
filetype plugin indent on		" detects syntax rules based on filetype
set breakindent					" Indents word-wrapped lines as much as the 'parent' line
set linebreak					" don't split words when wrapping
autocmd FileType * setlocal formatoptions-=ro " disable continuing comments on o and enter
set signcolumn=yes				" make sign column always visible
autocmd Filetype * setlocal indentkeys-=:	" dont treat : as an indent key
autocmd BufWritePost *  call system('touch -a ' . shellescape(expand('%:p'))) | call GtkRecentLog(expand("%:p"))	" update file access time on write



" COLORS

set background=dark					" needed for colors to work predictably
let g:lsp_diagnostics_echo_cursor=1	" echo error when cursor hovers the code
let g:lsp_semantic_enabled=1		" enable semantic highlighting
unlet c_comment_strings				" disable highlighting constants in comments

" lsp
hi LspSemanticVariable ctermfg=none
hi LspSemanticParameter ctermfg=white
hi LspSemanticProperty ctermfg=white
hi LspSemanticClass ctermfg=green
hi LspSemanticMember ctermfg=lightyellow
hi lspReference ctermbg=black
hi LspSemanticModifier ctermfg=none

" vim
hi NonText ctermfg=darkgray
hi StorageClass ctermfg=cyan
hi Type ctermfg=green
hi Comment ctermfg=red
hi Function ctermfg=lightyellow
hi Structure ctermfg=darkblue
hi Statement ctermfg=magenta
hi Keyword ctermfg=darkblue
hi Constant ctermfg=darkmagenta
hi Identifier ctermfg=darkyellow cterm=none
hi Special ctermfg=darkyellow
hi Error ctermbg=darkred
hi MatchParen ctermbg=black ctermfg=white
hi SignColumn ctermbg=none
hi LineNr ctermfg=darkgray
hi SignatureMarkText ctermfg=gray
let g:ophigh_color=8	" operator color

" vim-lsp/asyncomplete
hi PMenu ctermbg=black ctermfg=gray
hi PMenuSel ctermbg=darkgray ctermfg=black
hi link markdownError NONE
hi markdownCode ctermfg=lightgray ctermbg=darkgray

" language-specific
hi def link javaScriptValue Constant
hi def link javaScriptBraces NONE

