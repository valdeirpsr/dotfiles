#!/bin/bash

APPS=()
APPS_SNAPD=()
APPS_SNAPD_CLASSIC=()
APPS_FLATPAK=()
SYNC_DOTFILES=0

# Configura as cores, caso o terminal as possuas integradas
function setup_colors() {
    RED=$(printf '\033[31m');
    GREEN=$(printf '\033[32m');
    YELLOW=$(printf '\033[33m');
    BLUE=$(printf '\033[34m');
    BOLD=$(printf '\033[1m');
    RESET=$(printf '\033[m');
}

# Formata e exibe mensagem de erro
fmt_error() {
  printf '%sErro: %s%s\n' "$BOLD$RED" "$*" "$RESET" >&2;
  exit 1;
}

# Formata e exibe mensagem de sucesso
fmt_success() {
  printf '%sSucesso: %s%s\n' "$BOLD$GREEN" "$*" "$RESET"
}

# Formata e exibe mensagem de espera
fmt_wait() {
  printf '%sAguarde: %s%s\n' "$BOLD$YELLOW" "$*" "$RESET"
}

# Formata e exibe código
fmt_code() {
  printf '`\033[38;5;247m%s%s`\n' "$*" "$RESET"
}

fmt_msg() {
    printf $*;
}

# Mensagem de ajuda
function usage() {
    echo "--gui"
    echo "--minimal"
    echo "--normal"
    echo "--server"
    echo "--full"
    echo "--funny"
    echo "--sync-dotfiles"
    echo "--help"
}

# Prepara a instalação do Docker
function prepare_docker_install() {
    set -x;

    sudo apt install -y apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release \
        curl;

    platform=$(lsb_release -si | tr '[:upper:]' '[:lower:]')

    if [[ $(uname -v | tr '[:upper:]' '[:lower:]') =~ ubuntu ]]; then
        platform="ubuntu";
    fi

    if [[ $platform =~ ubuntu|debian ]]; then
        curl -fsSL "https://download.docker.com/linux/$platform/gpg" | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg;
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$platform $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null;
        set +x;
    else
        echo "Não há suporte para $platform";
        exit 1;
    fi
}

# Prepara a instalação do Kubectl
function prepare_kubectl_install() {
    set -x;

    sudo apt install -y apt-transport-https \
        ca-certificates \
        curl;

    sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
}

# Prepara a instalação do Github CLI
function prepare_gh_install() {
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
        sudo gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
        sudo tee /etc/apt/sources.list.d/github-cli.list
}

# Instala os pacotes mínimos
function install_minimal() {
    # git
    command -v git >> /dev/null || APPS+=("git")
    # wget
    command -v wget >> /dev/null || APPS+=("wget")
    # vim
    command -v vim >> /dev/null || APPS+=("vim")
    # curl
    command -v curl >> /dev/null || APPS+=("curl")
    # lsb-release
    command -v lsb_release >> /dev/null || APPS+=("lsb-release")
    # htop
    command -v htop >> /dev/null || APPS+=("htop")
    # less
    command -v less >> /dev/null || APPS+=("less")
    # neofetch
    command -v neofetch >> /dev/null || APPS+=("neofetch")

    if [[ $1 = "start" ]]; then
        install_apps;
    fi
}

# Instala os pacotes mínimos e o normal
function install_normal() {
    install_minimal;

    # ffmpeg
    command -v ffmpeg >> /dev/null || APPS+=("ffmpeg")
    # lynx
    command -v lynx >> /dev/null || APPS+=("lynx")

    if [[ $1 = "start" ]]; then
        install_apps;
    fi
}

# Instala os pacotes mínimos e para servidor (docker)
function install_server() {
    install_minimal;
    prepare_docker_install;

    # docker
    command -v docker >> /dev/null || APPS+=(docker-ce docker-ce-cli containerd.io)

    # docker-compose
    command -v docker-compose >> /dev/null || APPS+=("docker-compose")

    if [[ $1 = "start" ]]; then
        install_apps;
    fi
}

# Instala pacotes de servidor e ffmpeg, tilix, zsh, snapd e flatpak
function install_full() {
    install_server;

    # ffmpeg
    command -v ffmpeg >> /dev/null || APPS+=("ffmpeg")

    # tilix
    command -v tilix >> /dev/null || APPS+=("tilix")

    # zsh
    command -v zsh >> /dev/null || APPS+=("zsh")

    # snap
    command -v snap >> /dev/null || APPS+=("snapd")

    # flatpak
    command -v flatpak >> /dev/null || APPS+=("flatpak")

    sync_dotfiles;

    install_apps_from_snapd;
}

function install_apps_from_snapd() {
    # visual studio code
    command -v code >> /dev/null || APPS_SNAPD+=("code")

    # skype
    command -v skype >> /dev/null || APPS_SNAPD+=("skype")

    # teams
    command -v teams >> /dev/null || APPS_SNAPD+=("teams")
    
    # krita
    command -v krita >> /dev/null || APPS_SNAPD+=("krita")

    # postman
    command -v postman >> /dev/null || APPS_SNAPD+=("postman")

    # simplescreenrecorder
    command -v simplescreenrecorder >> /dev/null || APPS_SNAPD+=("simplescreenrecorder")

    install_apps;
}

function install_funny() {
    # lolcat
    # asciiview
    # cowsay
    # 
    echo "Funny";
}

function choose_apps() {
    APPS=$(
        dialog \
            --clear \
            --stdout \
            --title "Escolha os apps" \
            --extra-button \
            --extra-label "Adicionar mais" \
            --checklist "Instalação via APT" \
            0 0 0 \
            git Git on \
            wget wget on \
            vim vim on \
            curl curl on \
            httpie HTTPie on \
            jq Json on \
            lsb-release "Linux Standard Base" on \
            htop "Process Viewer" on \
            less less on \
            neofetch Neofetch off \
            ffmpeg ffmpeg on \
            ffmpegthumbnailer "Video Thumbnails" off \
            docker Docker on \
            kubectl Kubernetes off \
            tilix Tilix off \
            zsh zsh off \
            snapd Snapcraft off \
            flatpak Flatpak off \
    );

    APPS=$(echo ${APPS/docker/docker-ce docker-ce-cli containerd.io docker-compose})

    if [[ $? -eq 3 ]]; then
        APPSExtra=$(dialog --stdout --clear --title "Separe por espaço" --inputbox "Informe outros pacotes" 0 0);
        APPS="$APPS $APPSExtra";
    fi

    choose_apps_from_flatpak;
}

function choose_apps_from_snapd() {
    if [[ $(command -v snap) ]]; then
        arch=$(uname -m);

        APPS_SNAPD=$(
            dialog \
                --clear \
                --stdout \
                --title "Escolha os apps" \
                --checklist "Instalação via Snapcraft.io ($arch)" \
                0 0 0 \
                $([[ $arch = "x86_64" ]] && echo "postman postman off") \
                $([[ $arch = "x86_64" ]] && echo "taskbook taskbook off") \
                $([[ $arch = "x86_64" ]] && echo "task Task-Runner off") \
        );

        if [[ $APPS_SNAPD =~ task ]]; then
            APPS_SNAPD_CLASSIC+=('task')
            APPS_SNAPD=$(echo $APPS_SNAPD | sed 's/\btask\b//g')
        fi
    fi

    sync_dotfiles;
}

function choose_apps_from_flatpak() {
    if [[ $(command -v flatpak) ]]; then
        arch=$(uname -m);

        APPS_FLATPAK=$(
            dialog \
                --clear \
                --stdout \
                --title "Escolha os apps" \
                --checklist "Instalação via Flathub ($arch)" \
                0 0 0 \
                $([[ $arch = "x86_64" ]] && echo "com.spotify.Client Spotify off") \
                $([[ $arch = "x86_64" ]] && echo "com.discordapp.Discord Discord off") \
                $([[ $arch = "x86_64" ]] && echo "com.valvesoftware.Steam Steam off") \
                $([[ $arch = "x86_64" ]] && echo "us.zoom.Zoom Zoom off") \
                com.visualstudio.code VSCode off \
                org.telegram.desktop Telegram off \
                $([[ $arch = "x86_64" ]] && echo "com.obsproject.Studio OBS-Studio off") \
                $([[ $arch = "x86_64" ]] && echo "com.microsoft.Teams Teams off") \
                $([[ $arch = "x86_64" ]] && echo "com.skype.Client Skype off") \
                org.inkscape.Inkscape "Ink Scape" off \
                org.gnome.gitlab.somas.Apostrophe Apostrophe off \
                com.simplenote.Simplenote Simplenote off \
                org.flameshot.Flameshot Flameshot off \
                org.kde.krita Krita off \
                $([[ $arch = "x86_64" ]] && echo "com.google.AndroidStudio Android-Studio off") \
                $([[ $arch = "x86_64" ]] && echo "com.slack.Slack Slack off") \
        );
    fi

    choose_apps_from_snapd;
}

function sync_dotfiles() {
    dialog --stdout --clear --yesno "Deseja sincronizar os arquivos .dotfiles?" 0 0;

    if [[ $? -eq 0 ]]; then
        SYNC_DOTFILES=1;
    fi

    install_apps;
}

function install_apps() {

    if [[ $APPS =~ docker ]]; then
        fmt_wait "Preparando instalação do Docker"
        prepare_docker_install;
        fmt_success "Preparação para instalação do Docker concluída"
    fi

    if [[ $APPS =~ kubectl ]]; then
        fmt_wait "Preparando instalação do Kubernetes"
        prepare_kubectl_install;
        fmt_success "Preparação para instalação do Kubernetes concluída"
    fi

    if [[ $APPS =~ gh ]]; then
        fmt_wait "Preparando instalação do GitHub CLI"
        prepare_gh_install;
        fmt_success "Preparação para instalação do GitHub CLI concluída"
    fi

    fmt_wait "Atualizando repositório"
    sudo apt update;
    fmt_success "Repositório atualizado"

    if [[ -n $APPS ]]; then
        fmt_wait "Instalando os apps: $(echo ${APPS[@]} | sed 's/ /\n/g' | sed 's/^/ - /g')"
        sudo apt install -y ${APPS[@]};
    fi

    if [[ -n $APPS_SNAPD ]]; then
        fmt_wait "Instalando os apps (via Snapd): $(echo ${APPS_SNAPD[@]} | sed 's/ /\n/g' | sed 's/^/ - /g')"
        sudo snap install $APPS_SNAPD;
    fi

    if [[ -n $APPS_SNAPD_CLASSIC ]]; then
        fmt_wait "Instalando os apps (via Snapd Classic): $(echo ${APPS_SNAPD_CLASSIC[@]} | sed 's/ /\n/g' | sed 's/^/ - /g')"
        sudo snap install --classic $APPS_SNAPD_CLASSIC;
    fi

    if [[ -n $APPS_FLATPAK ]]; then
        fmt_wait "Instalando os apps (via FlatPak): $(echo ${APPS_FLATPAK[@]} | sed 's/ /\n/g' | sed 's/^/ - /g')"
        sudo flatpak install -y flathub $APPS_FLATPAK;
    fi

    fmt_success "Aplicados instalados"
    
    # ohmyzsh
    if [[ $APPS =~ "zsh" ]]; then
        fmt_wait "Instalando oh-my-zsh"

        CHSH="no" RUNZSH="no" \
            sh -c "$(curl -sSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --skip-chsh --unattended

        git clone https://github.com/zsh-users/zsh-autosuggestions \
            ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

        git clone https://github.com/spaceship-prompt/spaceship-prompt.git \
            "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/spaceship-prompt" --depth=1

        ln -s "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/spaceship-prompt/spaceship.zsh-theme" \
            "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/spaceship.zsh-theme"

        fmt_success "A instalação do oh-my-zsh foi concluída"
    fi

    if [[ $SYNC_DOTFILES -eq 1 ]]; then
        fmt_wait "Sincronizando DotFiles..."

        [[ ! -d /tmp ]] && mkdir /tmp
        [[ ! -d /tmp/dotfiles ]] && mkdir /tmp/dotfiles

        set -x;
        sudo apt install fonts-powerline

        curl -sSLo "/tmp/dotfiles.tar.gz" "https://github.com/valdeirpsr/dotfiles/archive/refs/heads/main.tar.gz"

        tar -zxf /tmp/dotfiles.tar.gz -C /tmp/dotfiles --strip-components 1
        rm -r /tmp/dotfiles/{README.md,install.sh}

        tar -cC /tmp/dotfiles -f - . | tar -xf - -C $HOME

        sed -i "s/DEFAULT_USER=\"user\"/DEFAULT_USER=\"$USERNAME\"/g" ~/.zshrc
        set +x;
        fmt_success "Sincronização finalizada..."
    fi

    if [[ $APPS =~ "vim" ]]; then
        fmt_wait "Configurando o editor VIM..."

        # Instala o gerenciador de plugin do vim
        curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

        # Cria pasta para fontes
        mkdir -p ~/.local/share/fonts 2>/dev/null

        # Baixa a fonte para o plugin devicons
        curl -sSLo "~/.local/share/fonts/Hack Regular Nerd Font Complete.ttf" \
            "https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Hack/Regular/complete/Hack%20Regular%20Nerd%20Font%20Complete.ttf"

        fmt_success "Editor VIM configurado"
    fi

    # Instala o awscli2
    arch=$(uname -m)

    if [[ $arch =~ x86_64|aarch64 ]]; then
        fmt_wait "Instalando AWS-CLI-v2"

        curl "https://awscli.amazonaws.com/awscli-exe-linux-$arch.zip" -o "/tmp/awscliv2.zip"

        if [[ -e /tmp/awscliv2.zip ]]; then
            [[ -d /tmp/aws ]] && rm -r /tmp/aws
            unzip /tmp/awscliv2.zip -d /tmp
            sudo /tmp/aws/install

            fmt_success "AWS Cli instalado"
        else
            fmt_msg "Não foi possível instalar o awscli-v2"
        fi
    fi

    msg_finish;
}

function msg_finish() {
    echo "  ___           _        _            /\/|       ";
    echo " |_ _|_ __  ___| |_ __ _| | __ _  ___|/\/_  ___  ";
    echo "  | || '_ \/ __| __/ _' | |/ _' |/ __/ _' |/ _ \ ";
    echo "  | || | | \__ \ || (_| | | (_| | (_| (_| | (_) |";
    echo " |___|_| |_|___/\__\__,_|_|\__,_|\___\__,_|\___/ ";
    echo "  _____ _             _ _         )_)  _         ";
    echo " |  ___(_)_ __   __ _| (_)______ _  __| | __ _   ";
    echo " | |_  | | '_ \ / _' | | |_  / _' |/ _' |/ _' |  ";
    echo " |  _| | | | | | (_| | | |/ / (_| | (_| | (_| |  ";
    echo " |_|   |_|_| |_|\__,_|_|_/___\__,_|\__,_|\__,_|  ";
    echo "                                                 ";
    echo "                                    By Valdeir S.";
    echo "                              https://valdeir.dev";
    echo "";
}

function start() {
    if [[ -z $(command -v sudo) ]]; then
        apt -q update;
        apt -q install -y sudo;
    fi

    which dialog > /dev/null;

    if [ $? -eq 1 ]; then
        sudo apt -q update;
        sudo apt -q install -y dialog;
    fi;

    installMethod=$(dialog --stdout --clear --menu "Escolha o método de instalação" 0 0 0 1 "Minimal" 2 "Normal" 3 "Server" 4 "Full" 5 "Custom"); dialog --clear

    case $installMethod in
        1) install_minimal "start";;
        2) install_normal "start";;
        3) install_server "start";;
        4) install_full "start";;
        5) choose_apps;;
    esac;
}

echo "  ___                            _            ";
echo " / _ \                          | |           ";
echo "/ /_\ \ __ _ _   _  __ _ _ __ __| | ___       ";
echo "|  _  |/ _' | | | |/ _' | '__/ _' |/ _ \      ";
echo "| | | | (_| | |_| | (_| | | | (_| |  __/_ _ _ ";
echo "\_| |_/\__, |\__,_|\__,_|_|  \__,_|\___(_|_|_)";
echo "        __/ |                                 ";
echo "       |___/                     By Valdeir S.";
echo "                           https://valdeir.dev";
echo ""
echo "Verificando pré-requisitos."

start;
