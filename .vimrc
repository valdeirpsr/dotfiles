color desert
set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab
set autoindent

call plug#begin()
  Plug 'preservim/nerdtree'
  Plug 'Xuyuanp/nerdtree-git-plugin'
  Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
  Plug 'ryanoasis/vim-devicons'
call plug#end()

nnoremap <F12> :NERDTreeToggle<CR>
