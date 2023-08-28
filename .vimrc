color desert
set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab
set autoindent
set encoding=UTF-8
set guifont=Hack\ Nerd\ Font

let g:airline_powerline_fonts = 1

call plug#begin()
  Plug 'preservim/nerdtree'
  Plug 'Xuyuanp/nerdtree-git-plugin'
  Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
  Plug 'ryanoasis/vim-devicons'

  Plug 'airblade/vim-gitgutter'
  Plug 'mattn/emmet-vim'
  Plug 'junegunn/vim-easy-align'
  Plug 'vim-airline/vim-airline'
  Plug 'vim-airline/vim-airline-themes'
  Plug 'neoclide/jsonc.vim'
call plug#end()

nnoremap <F12> :NERDTreeToggle<CR>

autocmd VimLeave * let &t_EI.="\e[5 q" | normal i
