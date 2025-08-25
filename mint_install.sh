#!/bin/bash

# TODO: See about using star tags. Maybe get the current tag in here, then the star tag, and see
# if an update is needed

set -e # quit on error
cp "$HOME/.bashrc" "$HOME/.bashrc.bak"

# NOTE: Any program that needs to be manually updated should have an associated variable with
# "_update" in the name for easier search/grep

#############################################
# Check that the script is being run properly
#############################################

if [ -n "$SUDO_USER" ]; then
    echo "Running this script with sudo will cause pathing to break. Exiting..."
    exit 1
fi

if [ "$PWD" != "$HOME" ]; then
    echo "Error: This script must be run from the home directory ($HOME)."
    exit 1
fi

#############################
# Confirm we want to continue
#############################

fresh_install=false

echo "Install script for Linux Mint Xia with i3"
echo "Before running this, run sudo apt update, upgrade, autoremove, and autoclean"
echo "This might be necessary to make kernel updates install"
echo ""

echo "Target home directory: $HOME"
read -p "Fresh install, update, or quit? (i/u/q): " choice

if [[ "$choice" != "i" && "$choice" != "I" && "$choice" != "u" && "$choice" != "U" ]]; then
    echo "Exiting."
    exit 0
fi

if [[ "$choice" == "i" || "$choice" == "I" ]]; then
    fresh_install=true
fi

# Not sure if I need this, but a useful code snippet
# if [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
#     export PATH=/usr/local/bin:$PATH
# fi

if [[ "$fresh_install" == true ]]; then
    cat <<EOF >>"$HOME/.bashrc"

alias mint-install="bash \$HOME/mint_install/mint_install.sh"
EOF
fi

##################
# System Hardening
##################

if [[ "$fresh_install" == true ]]; then
    sudo apt install -y ufw
    sudo apt remove -y gufw # Mint default

    sudo ufw default deny incoming  # Should be default, but let's be sure
    sudo ufw default allow outgoing # Also should be default
    sudo ufw logging on
    sudo ufw --force enable

    ssh_dir="$HOME/.ssh"
    [ ! -d "$ssh_dir" ] && mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"

    cat <<'EOF' >"$ssh_dir/config"
Host *
ServerAliveInterval 60
ServerAliveCountMax 30
EOF
    chmod 600 "$ssh_dir/config"
fi

############
# Apt Basics
############

sudo apt update
sudo apt upgrade -y

###########
# Utilities
###########

if [[ "$fresh_install" == true ]]; then
    sudo apt install -y fd-find
    sudo apt install -y vim
    sudo apt install -y sqlite3
    sudo apt install -y virtualbox

    # perf would be installed here if needed
    echo "kernel.perf_event_paranoid = -1" | sudo tee /etc/sysctl.conf
fi

###########
# Dev Tools
###########

if [[ "$fresh_install" == true ]]; then
    sudo apt install -y shellcheck
    sudo apt install -y llvm
fi

#####
# Git
#####

if [[ "$fresh_install" == true ]]; then
    sudo apt install -y git-all

    git config --global user.name "Mike J. McGuirk"
    git config --global user.email "mike.j.mcguirk@gmail.com"
    # Rebase can do goofy stuff
    git config --global pull.rebase false

    # libsecret-1-0 already installed
    sudo apt install -y libsecret-1-dev
    libsecret_path="/usr/share/doc/git/contrib/credential/libsecret"
    cd $libsecret_path
    sudo make
    git config --global credential.helper $libsecret_path/git-credential-libsecret
    cd "$HOME"
fi

###########
# Wireguard
###########

if [[ "$fresh_install" == true ]]; then
    sudo apt install -y wireguard
    # resolvconf is a service in Mint Xia
    sudo apt install -y natpmpc
fi

##################
# General Programs
##################

if [[ "$fresh_install" == true ]]; then
    sudo apt install -y vlc
    sudo apt install -y hexchat
    sudo apt install -y libreoffice
    sudo apt install -y wordnet
    sudo apt install -y qbittorrent
    sudo apt install -y kolourpaint

    sudo apt remove -y drawing
    sudo apt remove -y mintupdate
    sudo apt remove -y timeshift
fi

##########
# Redshift
##########

if [[ "$fresh_install" == true ]]; then
    sudo apt install -y redshift-gtk
    sudo systemctl disable geoclue

    [ ! -d "$HOME/.config" ] && mkdir -p "$$HOME/.config"
    redshift_conf_file="$HOME/.config/redshift.conf"

    # lat and lon are set for zero to avoid dox
    echo "Writing Redshift configuration to $redshift_conf_file..."
    if cat <<'EOF' >"$redshift_conf_file"; then
[redshift]
temp-day=6500
temp-night=4000
adjustment-method=randr
location-provider=manual

[manual]
lat=00.0000
lon=00.0000
EOF
        echo "Successfully wrote to $redshift_conf_file"
    else
        echo "Error: Failed to write to $redshift_conf_file"
        exit 1
    fi
fi

##############
# Get Dotfiles
##############

dotfiles_url="https://github.com/mikejmcguirk/dotfiles"

if [[ "$fresh_install" == true ]]; then
    echo "Pulling in dotfiles"
    if [ -z "$dotfiles_url" ]; then
        echo "Error: dotfiles_url must be set."
        exit 1
    fi

    dotfile_dir="$HOME/.cfg"
    [ ! -d "$dotfile_dir" ] && mkdir -p "$dotfile_dir"
    git clone --bare $dotfiles_url "$dotfile_dir"
    git --git-dir="$dotfile_dir" --work-tree="$HOME" checkout main --force

    if ! grep -q ".bashrc_custom" "$HOME/.bashrc"; then
        cat <<'EOF' >>"$HOME/.bashrc"

if [ -f "$HOME/.bashrc_custom" ]; then
    . "$HOME/.bashrc_custom"
fi
EOF
    fi

    git --git-dir="$dotfile_dir" --work-tree="$HOME" ls-files | grep '\.sh$' | while read -r file; do
        chmod +x "$HOME/$file"
    done
fi

################
# Window Manager
################

if [[ "$fresh_install" == true ]]; then
    sudo apt install -y i3
    sudo apt install -y xautolock
    sudo apt install -y playerctl # Detect playing media to avoid screen lock

    sudo apt install -y easyeffects

    sudo apt install -y feh
    sudo apt install -y picom

    sudo apt install -y polybar

    sudo apt install -y mint-themes # Should already be there but just to be sure
fi

######
# rofi
######

if [[ "$fresh_install" == true ]]; then
    sudo apt install -y rofi
    sudo apt install -y maim  # Use rofi as a wrapper for screenshots
    sudo apt install -y xclip # For copying screenshots to clipboard
    sudo apt install -y jq    # To parse i3 window data for maim

    # We want to be able to reboot and shutdown from Rofi
    if ! getent group sudo >/dev/null; then
        echo "Error: The 'sudo' group does not exist on this system"
        echo "Please create the group or modify the script to use a different group/username"
        exit 1
    fi

    reboot_shutdown_file="/etc/sudoers.d/reboot-shutdown"
    if ! sudo touch "$reboot_shutdown_file"; then
        echo "Failed to create $reboot_shutdown_file"
        exit 1
    fi

    if ! echo "%sudo ALL=(ALL) NOPASSWD: /sbin/reboot, /sbin/shutdown" | sudo tee "$reboot_shutdown_file" >/dev/null; then
        echo "Failed to write to $reboot_shutdown_file"
        sudo rm -f "$reboot_shutdown_file"
        exit 1
    fi

    if ! sudo chmod 440 "$reboot_shutdown_file"; then
        echo "Failed to set permissions on $reboot_shutdown_file"
        sudo rm -f "$reboot_shutdown_file"
        exit 1
    fi

    if ! sudo visudo -c -f "$reboot_shutdown_file"; then
        echo "Syntax check failed for $reboot_shutdown_file"
        sudo rm -f "$reboot_shutdown_file"
        exit 1
    fi

    cat <<EOF >>"$HOME/.bashrc"

export PATH="\$PATH:/sbin"
EOF

    echo "Successfully configured $reboot_shutdown_file"
fi

#####################################
# i3lock-color (betterlockscreen dep)
#####################################

# NOTE: Would changes to this affect betterlockscreen?

i3lock_repo="https://github.com/Raymo111/i3lock-color"
i3lock_tag="2.13.c.5"

i3lock_update=false
for arg in "$@"; do
    if [[ "$arg" == "i3lock" || "$arg" == "all" ]]; then
        i3lock_update=true
        echo "Updating i3lock-color..."

        break
    fi
done

if [[ "$fresh_install" == true && "$i3lock_update" == true ]]; then
    echo "Cannot fresh install and update i3lock-color"
    exit 1
fi

if [[ "$fresh_install" == true && "$i3lock_update" != true ]]; then
    echo "Installing i3lock-color..."
fi

sudo apt remove -y i3lock

# deps
if [ "$fresh_install" == true ]; then
    sudo apt install -y autoconf
    sudo apt install -y gcc
    sudo apt install -y make
    sudo apt install -y pkg-config
    sudo apt install -y libpam0g-dev
    sudo apt install -y libcairo2-dev
    sudo apt install -y libfontconfig1-dev
    sudo apt install -y libxcb-composite0-dev
    sudo apt install -y libev-dev
    sudo apt install -y libx11-xcb-dev
    sudo apt install -y libxcb-xkb-dev
    sudo apt install -y libxcb-xinerama0-dev
    sudo apt install -y libxcb-randr0-dev
    sudo apt install -y libxcb-image0-dev
    sudo apt install -y libxcb-util0-dev
    sudo apt install -y libxcb-xrm-dev
    sudo apt install -y libxkbcommon-dev
    sudo apt install -y libxkbcommon-x11-dev
    sudo apt install -y libjpeg-dev
    sudo apt install -y libgif-dev
fi

i3_color_git_dir="$HOME/.local/bin/i3lock-color"
if [[ "$fresh_install" == true || "$i3lock_update" == true ]]; then
    [ ! -d "$i3_color_git_dir" ] && mkdir -p "$i3_color_git_dir"
    cd "$i3_color_git_dir" || {
        echo "Error: Cannot cd to $i3_color_git_dir"
        exit 1
    }
fi

if [ "$fresh_install" == true ]; then
    git clone "$i3lock_repo" "$i3_color_git_dir"
elif [ "$i3lock_update" == true ]; then
    git checkout --force master
    git pull
fi

i3_color_build_dir="$i3_color_git_dir/build"
if [[ "$fresh_install" == true || "$i3lock_update" == true ]]; then
    git checkout --force "$i3lock_tag" || {
        echo "Error: Cannot checkout $i3lock_tag"
        exit 1
    }
    ./install-i3lock-color.sh
    # for betterlockscreen
    mv "$i3_color_build_dir/i3lock" "$i3_color_build_dir/i3lock-color"

    cd "$HOME"
fi

if [[ "$fresh_install" == true ]]; then
    cat <<EOF >>"$HOME/.bashrc"

export PATH="\$PATH:$i3_color_build_dir"
EOF
fi

####################################
# ImageMagick (betterlockscreen dep)
####################################

# NOTE: Would changes to this affect betterlockscreen?

magick_repo="https://github.com/ImageMagick/ImageMagick"
magick_tag="7.1.2-1"
magick_update=false
for arg in "$@"; do
    if [[ "$arg" == "magick" || "$arg" == "all" ]]; then
        magick_update=true
        echo "Updating ImageMagick..."

        break
    fi
done

if [[ "$fresh_install" == true && "$magick_update" == true ]]; then
    echo "Cannot fresh install and update magick"
    exit 1
fi

magick_git_dir="$HOME/.local/bin/magick"
if [[ "$fresh_install" == true || "$magick_update" == true ]]; then
    [ ! -d "$magick_git_dir" ] && mkdir -p "$magick_git_dir"
    cd "$magick_git_dir" || {
        echo "Error: Cannot cd to $magick_git_dir"
        exit 1
    }
fi

if [[ "$fresh_install" == true ]]; then
    git clone $magick_repo "$magick_git_dir"
elif [[ "$magick_update" == true ]]; then
    git checkout --force main
    git pull
fi

if [[ "$fresh_install" == true || "$magick_update" == true ]]; then
    git checkout --force "$magick_tag" || {
        echo "Error: Cannot checkout $magick_tag"
        exit 1
    }
    ./configure
    make
    sudo make install
    sudo ldconfig /usr/local/lib

    cd "$HOME"
fi

##################
# betterlockscreen
##################

# "https://github.com/betterlockscreen/betterlockscreen"
# The URL is outlined for readability. If the install/update command needs changed, handle below
bls_url="https://raw.githubusercontent.com/betterlockscreen/betterlockscreen/main/install.sh"
bls_tag="4.4.0"
bls_update=false
for arg in "$@"; do
    if [[ "$arg" == "bls" || "$arg" == "all" ]]; then
        bls_update=true
        echo "Updating betterlockscreen..."

        break
    fi
done

if [[ "$fresh_install" == true && "$bls_update" != true ]]; then
    echo "Installing betterlockscreen..."
fi

# deps
if [[ "$fresh_install" == true ]]; then
    sudo apt install -y feh # for wallpaper
    sudo apt install -y bc
    sudo apt install -y xautolock
fi

# Note: The install script will fail if it fails to find any of the deps, including
# i3lock-color and ImageMagick
if [[ "$fresh_install" == true || "$bls_update" == true ]]; then
    if [ -z "$bls_url" ]; then
        echo "bls_url not set. Exiting..."
        exit 1
    fi
    wget $bls_url -O - -q | bash -s user $bls_tag
fi

#########
# Spotify
#########

# TODO: Prefs file is incorrect
# https://www.spotify.com/de-en/download/linux/
# Check directions for updated key
spotify_key="https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg"
spotify_update=false
for arg in "$@"; do
    if [[ "$arg" == "spotify" || "$arg" == "all" ]]; then
        spotify_update=true
        echo "Updating Spotify key..."

        break
    fi
done

if [[ "$fresh_install" == true && "$spotify_update" != true ]]; then
    echo "Installing Spotify..."
fi

if [[ "$fresh_install" == true ]]; then
    spotify_repo="deb https://repository.spotify.com stable non-free"
    echo "$spotify_repo" | sudo tee /etc/apt/sources.list.d/spotify.list
fi

if [[ "$fresh_install" == true || "$spotify_update" == true ]]; then
    sudo curl -sS $spotify_key | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
    sudo apt update

    sudo apt install -y spotify-client

    username="$USER"
    spotify_prefs_dir="$HOME/.config/spotify/Users/${username}-user"
    [ ! -d "$spotify_prefs_dir" ] && mkdir -p "$spotify_prefs_dir"
    prefs_file="$spotify_prefs_dir/prefs"
    spotify_ui_setting="ui.track_notifications_enabled=false"

    if [ -f "$prefs_file" ]; then
        if grep -q "$spotify_ui_setting" "$prefs_file"; then
            echo "The line '$spotify_ui_setting' already exists in $prefs_file. Skipping..."
        else
            echo "Appending '$spotify_ui_setting' to $prefs_file..."
            echo "$spotify_ui_setting" >>"$prefs_file"
        fi
    else
        echo "Creating $prefs_file and adding the configuration line..."
        if ! touch "$prefs_file"; then
            echo "Error: Failed to create $prefs_file. Check permissions."
            exit 1
        fi
        echo "$spotify_ui_setting" >"$prefs_file"
    fi

    echo "Spotify preferences updated successfully."
fi

###############
# Brave Browser
###############

if [[ "$fresh_install" == true ]]; then
    curl -fsS https://dl.brave.com/install.sh | sh
    sudo apt remove -y firefox
fi

#####
# fzf
#####

fzf_repo="https://github.com/junegunn/fzf"
fzf_tag="v0.65.1"
fzf_update=false
for arg in "$@"; do
    if [[ "$arg" == "fzf" || "$arg" == "all" ]]; then
        fzf_update=true
        echo "Updating fzf..."

        break
    fi
done

fzf_git_dir="$HOME/.local/bin/fzf"
if [[ "$fresh_install" == true || "$fzf_update" == true ]]; then
    [ ! -d "$fzf_git_dir" ] && mkdir -p "$fzf_git_dir"
    cd "$fzf_git_dir" || {
        echo "Error: Cannot cd to $fzf_git_dir"
        exit 1
    }
fi

if [[ "$fresh_install" == true ]]; then
    git clone $fzf_repo "$fzf_git_dir"
elif [[ "$fzf_update" == true ]]; then
    git checkout --force master
    git pull
fi

if [[ "$fresh_install" == true || "$fzf_update" == true ]]; then
    git checkout --force "$fzf_tag" || {
        echo "Error: Cannot checkout $fzf_tag"
        exit 1
    }

    bash install --key-bindings --completion
    cd "$HOME"
fi

#######
# words
#######

words_repo="https://github.com/dwyl/english-words"
words_update=false
for arg in "$@"; do
    if [[ "$arg" == "words" || "$arg" == "all" ]]; then
        words_update=true
        echo "Updating words..."

        break
    fi
done

if [[ "$fresh_install" == true ]]; then
    sudo apt install wordnet
fi

words_git_dir="$HOME/.local/bin/words"
if [[ "$fresh_install" == true || "$words_update" == true ]]; then
    [ ! -d "$words_git_dir" ] && mkdir -p "$words_git_dir"
    cd "$words_git_dir" || {
        echo "Error: Cannot cd to $words_git_dir"
        exit 1
    }
fi

if [[ "$fresh_install" == true ]]; then
    git clone $words_repo "$words_git_dir"
elif [[ "$words_update" == true ]]; then
    git checkout --force master
    git pull
fi

########
# Neovim
########

# Dumb hack
sudo apt remove -y neovim
bad_neovim_dir="$HOME/.config/neovim"
if [ -d "$bad_neovim_dir" ]; then
    rm -rf "$bad_neovim_dir"
fi

# https://github.com/neovim/neovim/releases
# NOTE: Check the instructions as well as the tar URL in case they change
# nvim_url="https://github.com/neovim/neovim/releases/download/v0.11.2/nvim-linux-x86_64.tar.gz"
nvim_url="https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz"
# nvim_url="https://github.com/neovim/neovim/releases/download/v0.11.3/nvim-linux-x86_64.tar.gz"
nvim_tar=$(basename "$nvim_url")
nvim_config_repo="https://github.com/mikejmcguirk/Neovim-Win10-Lazy"

nvim_update=false
for arg in "$@"; do
    if [[ "$arg" == "nvim" || "$arg" == "all" ]]; then
        nvim_update=true
        echo "Updating Nvim..."

        break
    fi
done

nvim_root_dir="/opt"
nvim_install_dir="$nvim_root_dir/nvim-linux-x86_64"

if [[ "$fresh_install" == true ]]; then
    sudo apt install -y xclip # For copy/paste
fi

if [[ "$fresh_install" == true || "$nvim_update" == true ]]; then
    if [ -z "$nvim_url" ] || [ -z "$nvim_tar" ]; then
        echo "Error: nvim_url and nvim_tar must be set"
        exit 1
    fi

    if [ -d "$nvim_install_dir" ]; then
        echo "Removing existing Nvim installation at $nvim_install_dir..."
        sudo rm -rf $nvim_install_dir
    else
        echo "No existing Nvim installation found at $nvim_install_dir"
    fi

    nvim_tar_dir="$HOME/.local"
    [ ! -d "$nvim_tar_dir" ] && mkdir -p "$nvim_tar_dir"

    curl -LO --output-dir "$nvim_tar_dir" "$nvim_url"
    sudo tar -C $nvim_root_dir -xzf "$nvim_tar_dir/$nvim_tar"
    rm "$nvim_tar_dir/$nvim_tar"
fi

if [[ "$fresh_install" == true ]]; then
    if [ -z "$nvim_config_repo" ]; then
        echo "No Nvim config repo to clone. Exiting..."
        exit 1
    fi

    nvim_conf_dir="$HOME/.config/nvim"
    [ ! -d "$nvim_conf_dir" ] && mkdir -p "$nvim_conf_dir"

    git clone $nvim_config_repo "$nvim_conf_dir"

    cat <<EOF >>"$HOME/.bashrc"

export PATH="\$PATH:$nvim_install_dir/bin"
EOF
fi

######
# Btop
######

# https://github.com/aristocratos/btop
btop_url="https://github.com/aristocratos/btop/releases/download/v1.4.4/btop-x86_64-linux-musl.tbz"
btop_file=$(basename "$btop_url")

btop_update=false
for arg in "$@"; do
    if [[ "$arg" == "btop" || "$arg" == "all" ]]; then
        btop_update=true
        echo "Updating Btop..."

        break
    fi
done

btop_install_dir="/opt/btop"

if [[ "$fresh_install" == true || "$btop_update" == true ]]; then
    if [ -z "$btop_url" ] || [ -z "$btop_file" ]; then
        echo "Error: btop_url and btop_file must be set"
        exit 1
    fi

    if [ -d "$btop_install_dir" ]; then
        echo "Removing existing Btop installation at $btop_install_dir..."
        sudo rm -rf "$btop_install_dir"
    else
        echo "No existing Btop installation found at $btop_install_dir"
    fi

    sudo wget -P "/opt" "$btop_url"
    sudo tar xjvf "/opt/$btop_file" -C "/opt/"
    cd $btop_install_dir
    sudo bash "$btop_install_dir/install.sh"
    cd "$HOME"
    sudo rm "/opt/$btop_file"
fi

if [[ "$fresh_install" == true ]]; then
    cat <<EOF >>"$HOME/.bashrc"

export PATH="\$PATH:$btop_install_dir/bin"
EOF
fi

################
# Install Lua LS
################

# https://github.com/LuaLS/lua-language-server
lua_ls_url="https://github.com/LuaLS/lua-language-server/releases/download/3.15.0/lua-language-server-3.15.0-linux-x64.tar.gz"
lua_ls_file=$(basename "$lua_ls_url")

lua_ls_update=false
for arg in "$@"; do
    if [[ "$arg" == "lua_ls" || "$arg" == "all" ]]; then
        lua_ls_update=true
        echo "Updating Lua LS..."

        break
    fi
done

lua_ls_install_dir="$HOME/.local/bin/lua_ls"

if [[ "$fresh_install" == true || "$lua_ls_update" == true ]]; then
    if [ -z "$lua_ls_url" ] || [ -z "$lua_ls_file" ]; then
        echo "Error: lua_ls_url and lua_ls_file must be set"
        exit 1
    fi

    if [ -d "$lua_ls_install_dir" ]; then
        echo "Removing existing lua_ls installation at $lua_ls_install_dir..."
        rm -rf "$lua_ls_install_dir"
    else
        echo "No existing lua_ls installation found at $lua_ls_install_dir"
    fi

    # Files are in the top level of the tar
    wget -P "$lua_ls_install_dir" $lua_ls_url
    tar xzf "$lua_ls_install_dir/$lua_ls_file" -C "$lua_ls_install_dir"
    rm "$lua_ls_install_dir/$lua_ls_file"
fi

if [[ "$fresh_install" == true ]]; then
    cat <<EOF >>"$HOME/.bashrc"

export PATH="\$PATH:$lua_ls_install_dir/bin"
EOF
fi

##########
# Obsidian
##########

# https://obsidian.md/download
obsidian_url="https://github.com/obsidianmd/obsidian-releases/releases/download/v1.9.10/obsidian_1.9.10_amd64.deb"
obsidian_file=$(basename "$obsidian_url")

obsidian_update=false
for arg in "$@"; do
    if [[ "$arg" == "obsidian" || "$arg" == "all" ]]; then
        obsidian_update=true
        echo "Updating Obsidian..."

        break
    fi
done

if [[ "$fresh_install" == true && "$obsidian_update" != true ]]; then
    echo "Installing Obsidian..."
fi

if [[ "$fresh_install" == true || "$obsidian_update" == true ]]; then
    if [ -z "$obsidian_url" ] || [ -z "$obsidian_file" ]; then
        echo "Error: obsidian_url and obsidian_file must be set"
        exit 1
    fi

    curl -LO --output-dir "$HOME/.local" "$obsidian_url" || {
        echo "Obsidian curl failed"
        exit 1
    }
    sudo apt install -y "$HOME/.local/$obsidian_file" || {
        echo "Unable to install Obsidian Deb file"
        exit 1
    }
    rm "$HOME/.local/$obsidian_file" || {
        echo "Unable to delete Obsidian Deb file"
        exit 1
    }
fi

##################
# Python Ecosystem
##################

if [[ "$fresh_install" == true ]]; then
    sudo apt install -y python3-full
    sudo apt install -y python3-pip
    sudo apt install -y pipx

    pipx ensurepath # Adds ~/.local/bin to path
    # Add pipx completions
    cat <<'EOF' >>"$HOME/.bashrc"

eval "$(register-python-argcomplete pipx)"
EOF

    pipx install nvitop
    # pipx install beautysh
    pipx runpip beautysh install setuptools
    pipx install ruff
    pipx install python-lsp-server[all]
fi

pipx upgrade-all

######################
# Javascript Ecosystem
######################

# https://github.com/nvm-sh/nvm
# Check that the install cmd is up to date as well
nvm_install_url="https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh"
nvm_update=false
for arg in "$@"; do
    if [[ "$arg" == "nvm" || "$arg" == "all" ]]; then
        nvm_update=true
        echo "Updating Nvm..."

        break
    fi
done

if [[ "$fresh_install" == true || "$nvm_update" == true ]]; then
    if [ -z "$nvm_install_url" ]; then
        echo "nvim_install_url must be set"
        exit 1
    fi

    wget -qO- $nvm_install_url | bash
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

nvm install --lts
nvm alias default lts/*

npm i -g npm@latest

npm i -g "typescript-language-server"@latest
npm i -g "typescript"@latest
npm i -g "eslint"@latest
npm i -g "prettier"@latest
npm i -g "vscode-langservers-extracted"@latest
npm i -g "bash-language-server"@latest

##############
# Go Ecosystem
##############

# https://go.dev/doc/install
go_dl_url="https://go.dev/dl/go1.25.0.linux-amd64.tar.gz"
go_tar=$(basename "$go_dl_url")

go_update=false
for arg in "$@"; do
    if [[ "$arg" == "go" || "$arg" == "all" ]]; then
        go_update=true
        echo "Updating Go..."

        break
    fi
done

if [ "$fresh_install" = true ] && [ "$go_update" != true ]; then
    echo "Installing Go..."
fi

go_install_dir="/usr/local/go"

if [[ "$fresh_install" == true || "$go_update" == true ]]; then
    if [ -z "$go_dl_url" ] || [ -z "$go_tar" ]; then
        echo "Error: go_dl_url and go_tar must be set."
        exit 1
    fi

    if [ -d "$go_install_dir" ]; then
        echo "Removing existing Go installation at $go_install_dir..."
        sudo rm -rf $go_install_dir
    else
        echo "No existing Go installation found at $go_install_dir"
    fi

    go_dl_dir="$HOME/.local"
    wget -P "$go_dl_dir" "$go_dl_url"
    sudo tar -C /usr/local -xzf "$go_dl_dir/$go_tar"
    rm "$go_dl_dir/$go_tar"
fi

go_install_bin=$go_install_dir/bin
export PATH=$PATH:$go_install_bin
export GOPATH=$(go env GOPATH)
export PATH=$PATH:$GOPATH/bin

if [[ "$fresh_install" == true ]]; then
    echo "Adding Go paths to $HOME/.bashrc..."
    cat <<EOF >>"$HOME/.bashrc"

# Go environment setup
export PATH=\$PATH:$go_install_bin
export GOPATH=\$(go env GOPATH)
export PATH=\$PATH:\$GOPATH/bin
EOF
fi

go install mvdan.cc/gofumpt@latest
go install mvdan.cc/sh/v3/cmd/shfmt@latest
go install golang.org/x/tools/gopls@latest
go install github.com/nametake/golangci-lint-langserver@latest
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

#########
# Discord
#########

discord_url="https://discord.com/api/download?platform=linux&format=deb"
discord_update=false
for arg in "$@"; do
    if [[ "$arg" == "discord" || "$arg" == "all" ]]; then
        discord_update=true
        echo "Updating Discord..."

        break
    fi
done

if [ "$fresh_install" = true ] && [ "$discord_update" != true ]; then
    echo "Installing Discord..."
fi

if [[ "$fresh_install" == true || "$discord_update" == true ]]; then
    if [ -z "$discord_url" ]; then
        echo "Error: discord_url must be set."
        exit 1
    fi

    discord_dl_dir="$HOME/.local"
    [ ! -d "$discord_dl_dir" ] && mkdir -p "$discord_dl_dir"

    deb_file="$discord_dl_dir/discord_deb.deb"
    echo "Downloading Discord .deb from $discord_url..."

    if ! curl -L -o "$deb_file" "$discord_url"; then
        echo "Unable to download Discord .deb, continuing..."
    else
        file_type=$(file -b "$deb_file")
        if [[ "$file_type" =~ "Debian binary package" ]]; then
            echo "It's a deb file! Installing..."

            if sudo apt install -y "$deb_file"; then
                echo "Discord installed successfully"
            else
                echo "Unable to install Discord .deb, continuing..."
            fi
        else
            echo "Downloaded file is not a .deb package (type: $file_type)."
            echo "Removing and continuing..."
        fi
    fi

    rm -f "$deb_file"
fi

###############
# Add Nerd Font
###############

# https://www.nerdfonts.com/font-downloads
# Cousine version: 1.211
nerd_font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/Cousine.zip"
nerd_font_filename=$(basename "$nerd_font_url")

nerd_font_update=false
for arg in "$@"; do
    if [[ "$arg" == "nerd_font" || "$arg" == "all" ]]; then
        nerd_font_update=true
        echo "Updating Nerd Font..."

        break
    fi
done

if [[ "$fresh_install" == true || "$nerd_font_update" != true ]]; then
    echo "Installing Nerd Font..."
fi

if [[ "$fresh_install" == true || "$nerd_font_update" == true ]]; then
    fonts_dir="$HOME/.fonts"
    [ ! -d "$fonts_dir" ] && mkdir -p "$fonts_dir"

    if [ -z "$nerd_font_url" ]; then
        echo "Error: nerd_font_url must be set."
        exit 1
    fi

    wget -P "$fonts_dir" $nerd_font_url
    unzip -o "$fonts_dir/$nerd_font_filename" -d "$fonts_dir"
    rm "$fonts_dir/$nerd_font_filename"
fi

#########
# Ghostty
#########

ghostty_repo="https://github.com/ghostty-org/ghostty"
ghostty_tag="v1.1.3"
ghostty_dir="$HOME/.local/bin/ghostty-git"

zig_link="https://ziglang.org/download/0.13.0/zig-linux-x86_64-0.13.0.tar.xz"
ziglang_dir="/opt/ziglang"
zig_file=$(basename $zig_link)
zig_filepath=$ziglang_dir/"$zig_file"
zig_dir=$(basename "$zig_filepath" .tar.xz)

ghostty_update=false
for arg in "$@"; do
    if [[ "$arg" == "ghostty" || "$arg" == "all" ]]; then
        ghostty_update=true
        echo "Updating Ghostty..."

        break
    fi
done

zig_update=false
for arg in "$@"; do
    if [[ "$arg" == "zig" || "$arg" == "all" ]]; then
        zig_update=true
        echo "Updating zig..."

        break
    fi
done

if [ "$fresh_install" = true ]; then
    echo "Installing Ghostty..."
    echo "Installing zig..."

    # Could be repeats, but here for insurance/documentation
    sudo apt install -y libgtk-4-dev
    sudo apt install -y libadwaita-1-dev
    sudo apt install -y git
    sudo apt install -y blueprint-compiler
    sudo apt install -y gettext
    # ThePrimeagen has these included
    sudo apt install -y llvm
    sudo apt install -y lld
    sudo apt install -y llvm-dev
    sudo apt install -y liblld-dev
    sudo apt install -y clang
    sudo apt install -y libclang-dev
    sudo apt install -y libglib2.0-dev
    # Other stuff that might help
    sudo apt install -y libegl1-mesa-dev
    sudo apt install -y libvulkan-dev

    [ ! -d "$ziglang_dir" ] && sudo mkdir -p "$ziglang_dir"
    [ ! -d "$ghostty_dir" ] && mkdir -p "$ghostty_dir"
fi

if [ "$fresh_install" = true ] || [ "$zig_update" = true ]; then
    sudo wget -P $ziglang_dir $zig_link
    sudo tar -Jxf "$zig_filepath" -C "$ziglang_dir"
    sudo rm "$zig_filepath"
fi

if [ "$fresh_install" = true ] || [ "$zig_update" = true ] || [ "$ghostty_update" = true ]; then
    export PATH="$PATH:$ziglang_dir/$zig_dir"
    if ! zig version; then
        echo "Error: zig is not accessible or failed to run."
        exit 1
    fi
fi

if [ "$fresh_install" = true ] || [ "$ghostty_update" = true ]; then
    cd "$ghostty_dir" || {
        echo "Error: Cannot cd to $ghostty_dir"
        exit 1
    }
fi

if [ "$fresh_install" = true ]; then
    git clone $ghostty_repo .
fi

if [ "$ghostty_update" = true ]; then
    git checkout --force main
    git pull
fi

if [ "$fresh_install" = true ] || [ "$ghostty_update" = true ]; then
    git checkout --force "$ghostty_tag"
    # This will send the built file to ~/.local/bin
    rm -rf "$HOME/.cache/zig"
    zig build -p "$HOME/.local" -Doptimize=ReleaseFast

    cd "$HOME"
fi

######
# Tmux
######

if [ "$fresh_install" = true ]; then
    sudo apt install -y bison
    sudo apt install -y libncurses-dev
    sudo apt install -y libevent-dev
    sudo apt install -y automake
    sudo apt install -y autoconf
fi

tmux_url="https://github.com/tmux/tmux"
tmux_branch="tmux-3.5a"
tpm_repo="https://github.com/tmux-plugins/tpm"
tmux_power_repo="https://github.com/wfxr/tmux-power"

if [ -z "$tmux_url" ] || [ -z "$tmux_branch" ]; then
    echo "Error: tmux_url and tmux_branch must be set"
    exit 1
fi

tmux_update=false
for arg in "$@"; do
    if [[ "$arg" == "tmux" || "$arg" == "all" ]]; then
        if [[ "$fresh_install" == true ]]; then
            echo "Cannot do a fresh install and a tmux update at the same time"
            exit 1
        fi

        tmux_update=true
        echo "Updating tmux..."
        break
    fi
done

if [ "$fresh_install" = true ] && [ "$tmux_update" != true ]; then
    echo "Installing tmux..."
fi

tmux_git_dir="$HOME/.local/bin/tmux"
[ ! -d "$tmux_git_dir" ] && mkdir -p "$tmux_git_dir"

if [[ "$fresh_install" == true ]]; then
    git clone $tmux_url "$tmux_git_dir"
fi

cd "$tmux_git_dir" || {
    echo "Error: Cannot cd to $tmux_git_dir"
    exit 1
}

if [[ "$tmux_update" == true ]]; then
    git checkout --force master
    git pull
fi

if [ "$fresh_install" = true ] || [ "$tmux_update" = true ]; then
    git checkout --force "$tmux_branch" || {
        echo "Error: Cannot checkout $tmux_branch"
        exit 1
    }
    sh autogen.sh
    ./configure && make

    echo "tmux build complete"
fi

cd "$HOME" || {
    echo "Error: Cannot cd to $HOME"
    exit 1
}

if [[ "$fresh_install" == true ]]; then
    cat <<EOF >>"$HOME/.bashrc"

export PATH="\$PATH:$tmux_git_dir"
EOF
fi

tmux_plugins_dir="$HOME/.config/tmux/plugins"
[ ! -d "$tmux_plugins_dir" ] && mkdir -p "$tmux_plugins_dir"
tpm_dir="$tmux_plugins_dir/tpm"
power_dir="$tmux_plugins_dir/tmux-power"

if [ "$fresh_install" = true ] || [ "$tmux_update" = true ]; then
    if [ -z "$tpm_repo" ] || [ -z $tmux_power_repo ]; then
        echo "Error: tpm_repo and tmux_power_repo must be set"
        exit 1
    fi
fi

if [[ "$fresh_install" == true ]]; then
    git clone $tpm_repo "$tpm_dir"
    git clone $tmux_power_repo "$power_dir"
fi

# FUTURE: Can't the plugin manager just handle this?
if [[ "$tmux_update" == true ]]; then
    cd "$power_dir" || {
        echo "Error: Cannot cd to $power_dir"
        exit 1
    }
    git checkout --force master
    git pull
    cd "$HOME" || {
        echo "Error: Cannot cd to $HOME"
        exit 1
    }
fi

#############
# Apt Cleanup
#############

sudo apt autoremove -y
sudo apt autoclean -y

################
# Rust Ecosystem
################

# Rust is added last because it takes the longest (insert Rust comp times meme here)
# If you do this in the middle of the install, the sudo "session" might time out

# Rust URL
# Check curl cmd as well
rustup_url="https://sh.rustup.rs"
if [ "$fresh_install" = true ]; then
    echo "Installing rustup..."

    if [ -z "$rustup_url" ]; then
        echo "Error: rustup_url must be set"
        exit 1
    fi

    curl --proto '=https' --tlsv1.2 -sSf $rustup_url | sh
else
    rustup update
fi

rust_bin_dir="$HOME/.cargo/bin"
cargo_bin="$rust_bin_dir/cargo"
if [[ "$fresh_install" == true ]]; then
    rustup_bin="$rust_bin_dir/rustup"

    "$rustup_bin" toolchain install nightly
    #I don't know why, but rust-analyzer doesn't work unless you do this
    "$rustup_bin" component add rust-analyzer
    "$cargo_bin" install --features lsp --locked taplo-cli
    "$cargo_bin" install --features luajit stylua
    "$cargo_bin" install tokei
    "$cargo_bin" install flamegraph
    "$cargo_bin" install --locked tree-sitter-cli
    "$cargo_bin" install --features 'pcre2' ripgrep # For Perl Compatible Regex
    sudo apt install -y libssl-dev
    "$cargo_bin" install cargo-update
else
    $cargo_bin install-update -a
fi

#########
# Wrap Up
#########

# Have had to run these before to make function keys work properly on Linux Mint
# echo "options hid_apple fnmode=2" | sudo tee /etc/modprobe.d/hid_apple.conf
# sudo update-initramfs -u

what_happened="Update"
if [[ "$fresh_install" == true ]]; then
    what_happened="Install"
fi
echo "$what_happened script complete"
echo "Reboot to ensure all changes take effect"
