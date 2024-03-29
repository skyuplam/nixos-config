" vim: set foldmethod=marker foldlevel=0 nomodeline:

" ============================================================================
" KEY MAPPINGS {{{
" ============================================================================

" Explorer Mapping
" nnoremap <C-p> :Files<CR>
" nnoremap <A-p> :Buffers<CR>
nnoremap <silent> <leader>tb :TagbarToggle<CR>

" Terminal
nnoremap <leader>nt :bo 15sp +term<CR>

" CamelCaseMotion
let g:camelcasemotion_key = '<leader>'

" Mappings to move lines for macOS
nnoremap ∆ :m .+1<CR>==
nnoremap ˚ :m .-2<CR>==
inoremap ∆ <A-j> <Esc>:m .+1<CR>==gi
inoremap ˚ <Esc>:m .-2<CR>==gi
vnoremap ∆ :m '>+1<CR>gv=gv
vnoremap ˚ :m '<-2<CR>gv=gv

nnoremap <A-j> :m .+1<CR>==
nnoremap <A-k> :m .-2<CR>==
inoremap <A-j> <A-j> <Esc>:m .+1<CR>==gi
inoremap <A-k> <Esc>:m .-2<CR>==gi
vnoremap <A-j> :m '>+1<CR>gv=gv
vnoremap <A-k> :m '<-2<CR>gv=gv

" Search for selected text, forwards or backwards.
vnoremap <silent> * :<C-U>
  \let old_reg=getreg('"')<Bar>let old_regtype=getregtype('"')<CR>
  \gvy/<C-R><C-R>=substitute(
  \escape(@", '/\.*$^~['), '\_s\+', '\\_s\\+', 'g')<CR><CR>
  \gV:call setreg('"', old_reg, old_regtype)<CR>
vnoremap <silent> # :<C-U>
  \let old_reg=getreg('"')<Bar>let old_regtype=getregtype('"')<CR>
  \gvy?<C-R><C-R>=substitute(
  \escape(@", '?\.*$^~['), '\_s\+', '\\_s\\+', 'g')<CR><CR>
  \gV:call setreg('"', old_reg, old_regtype)<CR>

" vim-slash https://github.com/junegunn/vim-slash
" Places the current match at the center of the window
noremap <plug>(slash-after) zz

" stolen from https://bitbucket.org/sjl/dotfiles/src/tip/vim/vimrc
" The `zzzv` keeps search matches in the middle of the window.
" and make sure n will go forward when searching with ? or #
" https://vi.stackexchange.com/a/2366/4600
nnoremap <expr> n (v:searchforward ? 'n' : 'N') . 'zzzv'
nnoremap <expr> N (v:searchforward ? 'N' : 'n') . 'zzzv'

" Scrolling sync
nnoremap <silent> <F9> :set scb!<CR>

" Change the current working directory to the filepath of current buffer
nnoremap <leader>cd :cd %:p:h<CR>

" Map common terminal mappings
cnoremap <C-a> <Home>
cnoremap <C-e> <End>
cnoremap <C-p> <Up>
cnoremap <C-n> <Down>
cnoremap <C-b> <Left>
cnoremap <C-f> <Right>
cnoremap <C-d> <Delete>

cnoremap <M-f> <S-Right>
cnoremap <M-b> <S-Left>

" OSX specific
cnoremap ƒ <S-Right>
cnoremap ∫ <S-Left>

" https://github.com/mhinz/vim-galore#dont-lose-selection-when-shifting-sidewards
xnoremap <  <gv
xnoremap >  >gv

" Quickfix list navigation
nmap ]q :cnext<CR>
nmap ]Q :clast<CR>
nmap [q :cprev<CR>
nmap [Q :cfirst<CR>

" Location list navigation
nmap ]l :lnext<CR>
nmap ]L :lfirst<CR>
nmap [l :lprev<CR>
nmap [L :llast<CR>

" Diff and merge tool
" +-----------+------------+------------+
" |           |            |            |
" |           |            |            |
" |   LOCAL   |    BASE    |   REMOTE   |
" +-----------+------------+------------+
" |                                     |
" |                                     |
" |             (edit me)               |
" +-------------------------------------+
" shortcuts for 3-way merge
map <Leader>1 :diffget LOCAL<CR>
map <Leader>2 :diffget BASE<CR>
map <Leader>3 :diffget REMOTE<CR>
" }}}
