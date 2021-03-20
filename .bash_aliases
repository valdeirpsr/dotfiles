# Alias para Grep e LS (cor)
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Alias para listagem de arquivos e diretórios
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Alias para pular diretórios
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias v5="cd /var/www/html/v5"
alias ~~="cd ~"
alias --="cd -"

# Alias para capturar o IP
alias myip="dig +short myip.opendns.com @resolver1.opendns.com"

# Outros
alias diff="git diff --no-index"

# Finaliza todos os containers do Docker
function dockerStopAll() {
  for c in $(docker ps | tail -n +2 | cut -d' ' -f1); do
    docker stop $c;
  done
}

alias docker-stop-all='dockerStopAll'

# Executa PHP Interactive Shell
function start_php_commandline() {
  versions=$(docker image ls | grep php)
  
  if [ -n "$1" ] && [ $1 =~ ^[0-9]\.[0-9]$ ]; then
    versions=$(grep "$1" <<< $versions)
  fi
  
  versions=$(head -n 1 <<< $versions | awk '{ print $3 }')
  
  if [ -z "$versions" ]; then
    versions="php:latest"
  fi
  
  echo $versions;
}

alias php-cli='docker run -it $(start_php_commandline) php -a $@'

# Executa Node Interactive Shell
function start_node_commandline() {
  versions=$(docker image ls | grep node)
  
  if [ -n "$1" ]; then
    versions=$(grep "$1" <<< $versions)
  fi
  
  versions=$(head -n 1 <<< $versions | awk '{ print $3 }')
  
  if [ -z "$versions" ]; then
    versions="node:latest"
  fi
  
  echo $versions;
}

alias node-cli='docker run -it $(start_node_commandline) node'
