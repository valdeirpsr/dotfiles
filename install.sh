#!/bin/bash

APPS=()

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
  printf '%sError: %s%s\n' "$BOLD$RED" "$*" "$RESET" >&2;
  exit 1;
}

# Formata e exibe mensagem de sucesso
fmt_success() {
  printf '%sSucesso: %s%s\n' "$BOLD$GREEN" "$*" "$RESET"
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

    platform=$(lsb_release -si | tr A-Z a-z)

    if [[ $platform =~ ubuntu|debian ]]; then
        curl -fsSL "https://download.docker.com/linux/$platform/gpg" | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg;
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$platform $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null;
        set +x;
    else
        echo "Não há suporte para $platform";
        exit 1;
    fi
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
        set -x;
        sudo apt update
        sudo apt install -y ${APPS[@]}
        set +x;
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
        set -x;
        sudo apt update
        sudo apt install -y ${APPS[@]}
        set +x;
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
        set -x;
        sudo apt update
        sudo apt install -y ${APPS[@]}
        set +x;
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

    set -x;
    sudo apt update;
    sudo apt install -y ${APPS[@]};
    set +x;
    install_apps_from_snapd;

    set -x;
    # ohmyzsh
    CHSH="no" RUNZSH="no" \
        sh -c "$(curl -sSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --skip-chsh --unattended
    set +x;
}

function install_apps_from_snapd() {
    local APPS_SNAPD=()

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

    set -x;
    sudo snap install ${APPS_SNAPD[@]}
    set +x;

    sync_dotfiles;
}

function install_funny() {
    # lolcat
    # asciiview
    # cowsay
    # 
    echo "Funny";
}

function sync_dotfiles() {
    dialog --stdout --clear --yesno "Deseja sincronizar os arquivos .dotfiles?" 0 0;

    if [[ $? -eq 0 ]]; then
        dialog --clear;

        [[ ! -d /tmp ]] && mkdir /tmp
        [[ ! -d /tmp/dotfiles ]] && mkdir /tmp/dotfiles

        set -x;
        sudo apt install fonts-powerline

        curl -sSLo "/tmp/dotfiles.tar.gz" "https://github.com/valdeirpsr/dotfiles/archive/refs/heads/main.tar.gz"

        tar -zxf /tmp/dotfiles.tar.gz -C /tmp/dotfiles --strip-components 1

        tar -cC /tmp/dotfiles -f - . | tar -xf - -C ~

        sed -i "s/DEFAULT_USER=\"user\"/DEFAULT_USER=\"$USER\"/g" ~/.zshrc
        set +x;
    fi

    msg_finish;
}

function choose_apps() {
    appsSelected=$(
        dialog \
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
            lsb-release "Linux Standard Base" on \
            htop "Process Viewer" on \
            less less on \
            neofetch Neofetch on \
            ffmpeg ffmpeg on \
            ffmpegthumbnailer "Video Thumbnails" on \
            docker Docker on \
            tilix Tilix on \
            zsh zsh on \
            snapd Snapcraft on \
            flatpak Flatpak on \
    );

    appsSelected=$(echo ${appsSelected/docker/docker-ce docker-ce-cli containerd.io docker-compose})

    if [[ $? -eq 3 ]]; then
        appsSelectedExtra=$(dialog --stdout --clear --title "Separe por espaço" --inputbox "Informe outros pacotes" 0 0);
        appsSelected="$appsSelected $appsSelectedExtra";
    fi

    dialog --clear;

    if [[ -n $appsSelected ]]; then
        set -x;
        sudo apt install -y $appsSelected;
        set +x;
    fi

    choose_apps_from_snapd;
}

function choose_apps_from_snapd() {
    if [[ $(command -v snap) ]]; then
        arch=$(uname -m);

        appsSelected=$(
            dialog \
                --stdout \
                --title "Escolha os apps" \
                --checklist "Instalação via Snapcraft.io ($arch)" \
                0 0 0 \
                $([[ $arch = "x86_64" ]] && discord Discord on) \
                inkscape Inkscape on \
                $([[ $arch = "x86_64" ]] && android-studio "Android Studio" on) \
                $([[ $arch = "x86_64" ]] && postman postman on) \
                $([[ $arch = "x86_64" ]] && krita krita on) \
                $([[ $arch = "x86_64" ]] && taskbook taskbook on) \
                $([[ $arch = "x86_64" ]] && teams Teams on) \
                $([[ $arch = "x86_64" ]] && slack slack on) \
                $([[ $arch = "x86_64" ]] && skype skype on) \
        );

        if [[ $? -eq 1 ]]; then
            echo "Putz";
            choose_apps_from_flathub;
            return 1;
        fi

        dialog --clear;

        if [[ -n $appsSelected ]]; then
            set -x;
            sudo snap install $appsSelected;
            set +x;
        fi
    fi

    choose_apps_from_flathub;
}

function choose_apps_from_flathub() {
    if [[ $(command -v flatpak) ]]; then
        arch=$(uname -m);

        appsSelected=$(
            dialog \
                --stdout \
                --title "Escolha os apps" \
                --checklist "Instalação via Flathub ($arch)" \
                0 0 0 \
                $([[ $arch = "x86_64" ]] && com.spotify.Client Spotify on) \
                $([[ $arch = "x86_64" ]] && com.discordapp.Discord Discord on) \
                $([[ $arch = "x86_64" ]] && com.valvesoftware.Steam Steam on) \
                $([[ $arch = "x86_64" ]] && us.zoom.Zoom Zoom on) \
                com.visualstudio.code VSCode on \
                org.telegram.desktop Telegram on \
                $([[ $arch = "x86_64" ]] && com.obsproject.Studio "OBS Studio" on) \
                $([[ $arch = "x86_64" ]] && com.microsoft.Teams Teams on) \
                $([[ $arch = "x86_64" ]] && com.skype.Client Skype on) \
                org.inkscape.Inkscape "Ink Scape" on \
                org.gnome.gitlab.somas.Apostrophe Apostrophe on \
                com.simplenote.Simplenote Simplenote on \
                org.flameshot.Flameshot Flameshot on \
                org.kde.krita Krita on \
                $([[ $arch = "x86_64" ]] && com.google.AndroidStudio "Android Studio" on) \
        );

        dialog --clear;

        if [[ -n $appsSelected ]]; then
            set -x;
            sudo flatpak install -y flathub $appsSelected;
            set +x;
        fi
    fi

    sync_dotfiles;
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

    set -ea;

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