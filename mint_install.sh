#!/bin/bash

# TODO: Audit that this script works on a VM (last: unknown)
# - Needs to be a flag to skip big installs like LLVM
# TODO: Check if my version of Mint is still in its support window
# TODO: Move anything that's install based to build from source based
# TODO: See about using star tags. Maybe get the current tag in here, then the star tag, and see
# if an update is needed
# TODO: Fresh install should take args
# MAYBE: Outline the git repo stuff, since most of the logic is common. Apply it to place where
# it is not if possible

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

sudo apt update
sudo apt upgrade -y

if [[ "$fresh_install" == true ]]; then
    # shellcheck disable=SC1091 # shellcheck does not properly resolve $HOME
    . "$HOME/mint_install/bootstrap.sh"
fi

#####################################
# i3lock-color (betterlockscreen dep)
#####################################

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

# NOTE: Only update this every other tag or so, due to the frequency of new versions and the length
# of the build times.

magick_repo="https://github.com/ImageMagick/ImageMagick"
magick_tag="7.1.2-29"
magick_update=false
for arg in "$@"; do
    if [[ "$arg" == "magick" || "$arg" == "all" ]]; then
        magick_update=true
        echo "Updating ImageMagick..."
        break
    fi
done

[[ "$fresh_install" == true ]] && magick_update=true

magick_git_dir="$HOME/.local/bin/magick"
if [[ "$magick_update" == true ]]; then
    mkdir -p "$magick_git_dir"
    cd "$magick_git_dir" || {
        echo "Error: Cannot cd to $magick_git_dir"
        exit 1
    }

    if [[ ! -d .git ]]; then
        git clone --depth 1 --branch "$magick_tag" "$magick_repo" .
    else
        git fetch --tags --force origin
        git checkout --force "$magick_tag" || {
            echo "Error: Cannot checkout $magick_tag"
            exit 1
        }
    fi

    ./configure
    make -j"$(nproc)"
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

# Note: The install script will fail if it fails to find any of the deps, including
# i3lock-color and ImageMagick
if [[ "$fresh_install" == true || "$bls_update" == true ]]; then
    if [ -z "$bls_url" ]; then
        echo "bls_url not set. Exiting..."
        exit 1
    fi
    wget $bls_url -O - -q | bash -s user $bls_tag
fi

##################
# Python Ecosystem
##################

pipx upgrade-all

#########
# Spotify
#########

# TODO: Prefs file is incorrect
# https://www.spotify.com/de-en/download/linux/
# Check directions for updated key
spotify_key="https://download.spotify.com/debian/pubkey_5384CE82BA52C83A.asc"
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
# Brave Browser
###############

if [[ "$fresh_install" == true ]]; then
    sudo apt remove -y firefox
fi

# Just always do this since the keys can update
curl -fsS https://dl.brave.com/install.sh | sh

##########################################
# Frequently Updated Repos. Check Weekly #
##########################################

#####
# fzf
#####

sudo apt remove fzf

fzf_repo="https://github.com/junegunn/fzf"
fzf_tag="v0.74.2"
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

    # Because I had previously neglected to remove the package version, trying --update-rc
    # again to see if it works properly
    bash install --key-bindings --completion --update-rc
    cd "$HOME"
fi

########
# Neovim
########

nvim_repo="https://github.com/neovim/neovim"
nvim_tag="master"

# Dumb hack
sudo apt remove -y neovim
bad_neovim_dir="$HOME/.config/neovim"
if [ -d "$bad_neovim_dir" ]; then
    rm -rf "$bad_neovim_dir"
fi

if [[ "$fresh_install" == true ]]; then
    sudo apt install ninja-build gettext cmake curl build-essential git
fi

if [ -z "$nvim_repo" ] || [ -z "$nvim_tag" ]; then
    echo "Error: nvim_url and nvim_tag must be set"
    exit 1
fi

nvim_update=false
for arg in "$@"; do
    if [[ "$arg" == "nvim" || "$arg" == "all" ]]; then
        if [[ "$fresh_install" == true ]]; then
            echo "Cannot do a fresh install and a nvim update at the same time"
            exit 1
        fi

        nvim_update=true
        echo "Updating nvim..."
        break
    fi
done

if [ "$fresh_install" = true ] && [ "$nvim_update" != true ]; then
    echo "Installing nvim..."
fi

nvim_git_dir="$HOME/.local/bin/neovim"
[ ! -d "$nvim_git_dir" ] && mkdir -p "$nvim_git_dir"

if [[ "$fresh_install" == true ]]; then
    git clone $nvim_repo "$nvim_git_dir"
fi

cd "$nvim_git_dir" || {
    echo "Error: Cannot cd to $nvim_git_dir"
    exit 1
}

if [[ "$nvim_update" == true ]]; then
    git checkout --force master
    git pull
fi

if [ "$fresh_install" = true ] || [ "$nvim_update" = true ]; then
    git checkout --force "$nvim_tag" || {
        echo "Error: Cannot checkout $nvim_tag"
        exit 1
    }

    # rm -rf .deps build
    echo "Setting build type"
    make CMAKE_BUILD_TYPE=Release
    echo "Building"
    sudo make install

    echo "nvim build complete"
fi

cd "$HOME" || {
    echo "Error: Cannot cd to $HOME"
    exit 1
}

##############
# Go Ecosystem
##############

# https://go.dev/dl/
go_dl_url="https://go.dev/dl/go1.26.5.linux-amd64.tar.gz"
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

######
# Btop
######

# https://github.com/aristocratos/btop
btop_url="https://github.com/aristocratos/btop/releases/download/v1.4.7/btop-x86_64-unknown-linux-musl.tar.gz"
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
    sudo tar xzf "/opt/$btop_file" -C "/opt/"
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

###############
# Lua Ecosystem
###############

if [[ "$fresh_install" == true ]]; then
    sudo apt install build-essential libreadline-dev unzip
fi

# https://luajit.org/status.html
luajit_repo="https://luajit.org/git/luajit.git"
# NOTE: The tag is regularly updated with fixes/backports
luajit_tag="v2.1"

luajit_update=false
for arg in "$@"; do
    if [[ "$arg" == "luajit" || "$arg" == "all" ]]; then
        if [[ "$fresh_install" == true ]]; then
            echo "Cannot do a fresh install and a luajit update at the same time"
            exit 1
        fi

        luajit_update=true
        echo "Updating luajit..."
        break
    fi
done

if [ "$fresh_install" = true ] && [ "$luajit_update" != true ]; then
    echo "Installing luajit..."
fi

luajit_git_dir="$HOME/.local/bin/luajit"
[ ! -d "$luajit_git_dir" ] && mkdir -p "$luajit_git_dir"

if [[ "$fresh_install" == true ]]; then
    git clone $luajit_repo "$luajit_git_dir"
fi

cd "$luajit_git_dir" || {
    echo "Error: Cannot cd to $luajit_git_dir"
    exit 1
}

if [[ "$luajit_update" == true ]]; then
    git checkout --force master
    git pull
fi

if [ "$fresh_install" = true ] || [ "$luajit_update" = true ]; then
    git checkout --force "$luajit_tag" || {
        echo "Error: Cannot checkout $luajit_tag"
        exit 1
    }

    make
    sudo make install

    echo "luajit build complete"
fi

cd "$HOME" || {
    echo "Error: Cannot cd to $HOME"
    exit 1
}

######################
# Javascript Ecosystem
######################

# https://github.com/nvm-sh/nvm
# Check that the install cmd is up to date as well
nvm_install_url="https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.6/install.sh"
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
        echo "nvm_install_url must be set"
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
npm i -g @vtsls/language-server #This is apparently the preferred version now?
npm i -g "typescript"@latest
npm i -g "eslint"@latest
npm i -g "prettier"@latest
npm i -g "vscode-langservers-extracted"@latest
npm i -g "bash-language-server"@latest

###############
# Add Nerd Font
###############

# https://www.nerdfonts.com/font-downloads
# Cousine version: 1.211
nerd_font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.0/Cousine.zip"
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

# NOTE: The build command is currently altered due to a problem build dep. Per the issue below, a
# branch will be cut to address, and the build command needs to be reverted
# https://github.com/ghostty-org/ghostty/issues/9606

ghostty_repo="https://github.com/ghostty-org/ghostty"
ghostty_tag="v1.3.1"
ghostty_dir="$HOME/.local/bin/ghostty-git"

zig_link="https://ziglang.org/download/0.15.2/zig-x86_64-linux-0.15.2.tar.xz"
ziglang_dir="/opt/ziglang"
zig_file=$(basename $zig_link)
zig_filepath=$ziglang_dir/"$zig_file"
zig_dir=$(basename "$zig_filepath" .tar.xz)

blueprint_repo="https://gitlab.gnome.org/GNOME/blueprint-compiler.git"
blueprint_tag="v0.16.0"

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

blueprint_update=false
for arg in "$@"; do
    if [[ "$arg" == "blueprint" || "$arg" == "all" ]]; then
        blueprint_update=true
        echo "Updating blueprint-compiler..."
        break
    fi
done

if [ "$fresh_install" = true ]; then
    echo "Installing Ghostty..."
    echo "Installing zig..."
    echo "Installing blueprint-compiler..."

    # Could be repeats, but here for insurance/documentation
    sudo apt install -y libgtk-4-dev
    sudo apt install -y libgtk4-layer-shell-dev
    sudo apt install -y libadwaita-1-dev
    sudo apt install -y libxml2-utils
    sudo apt install -y git
    # sudo apt install -y blueprint-compiler # Repo version is out of date
    sudo apt install -y pkg-config
    sudo apt install -y gettext
    # ThePrimeagen has these included
    # sudo apt install -y llvm
    # sudo apt install -y lld
    # sudo apt install -y llvm-dev
    # sudo apt install -y liblld-dev
    # sudo apt install -y clang
    # sudo apt install -y libclang-dev
    # Other stuff that might help
    # sudo apt install -y libegl1-mesa-dev
    # sudo apt install -y libvulkan-dev

    # For blueprint-compiler
    sudo apt install -y ninja-build
    sudo apt install -y meson
    sudo apt install -y libglib2.0-dev

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

blueprint_git_dir="$HOME/.local/bin/blueprint-compiler"
[ ! -d "$blueprint_git_dir" ] && mkdir -p "$blueprint_git_dir"
if [[ "$fresh_install" == true ]]; then
    git clone $blueprint_repo "$blueprint_git_dir"
fi

if [ "$fresh_install" = true ] || [ "$blueprint_update" = true ]; then
    cd "$blueprint_git_dir" || {
        echo "Error: Cannot cd to $blueprint_git_dir"
        exit 1
    }
fi

if [[ "$blueprint_update" == true ]]; then
    git checkout --force main
    git pull
fi

if [ "$fresh_install" = true ] || [ "$blueprint_update" = true ]; then
    git checkout --force "$blueprint_tag" || {
        echo "Error: Cannot checkout $blueprint_tag"
        exit 1
    }

    rm -rf _build
    meson _build
    sudo ninja -C _build install
    sudo ldconfig

    echo "blueprint build complete"
fi

cd "$HOME" || {
    echo "Error: Cannot cd to $HOME"
    exit 1
}

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

sudo apt install patchelf

if [ "$fresh_install" = true ] || [ "$ghostty_update" = true ]; then
    git checkout --force "$ghostty_tag"
    # This will send the built file to ~/.local/bin
    rm -rf "$HOME/.cache/zig"

    # I don't know anymore why `-p "$HOME/.local` is present
    # build gtk layer shell since it is not packaged (yet?) with Mint 22.1
    zig build -p "$HOME/.local" -fno-sys=gtk4-layer-shell -Doptimize=ReleaseFast
    # zig build -p "$HOME/.local" -Doptimize=ReleaseFast
    # zig build -p "$HOME/.local" -Demit-themes=false -fno-sys=gtk4-layer-shell -Doptimize=ReleaseFast

    # https://github.com/ghostty-org/ghostty/issues/9631
    cd "$HOME/.local/bin"
    BINARY="ghostty"

    echo "Current RPATH:"
    patchelf --print-rpath "$BINARY"
    CURRENT_RPATH=$(patchelf --print-rpath "$BINARY")

    NEW_RPATH=$(echo "$CURRENT_RPATH" | sed "s|\.zig-cache/|${ghostty_dir}/.zig-cache/|g")
    echo "New absolute RPATH:"
    echo "$NEW_RPATH"

    cp -a "$BINARY" "$BINARY.bak.$(date +%Y%m%d-%H%M%S)"
    patchelf --set-rpath "$NEW_RPATH" "$BINARY"

    echo "New Ghostty rpath:"
    patchelf --print-rpath "$BINARY"

    cd "$HOME"
fi

######
# Tmux
######

tmux_url="https://github.com/tmux/tmux"
tmux_branch="3.7b"
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

#############
# Apt Cleanup
#############

# Cleanup apt before updating Rust and anything LLVM related. Because the build times are so
# long, the sudo-session might time out.

sudo apt autoremove -y
sudo apt autoclean -y

################
# Rust Ecosystem
################

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
    "$cargo_bin" install --locked typst-cli
    "$cargo_bin" install typstyle --locked
    "$cargo_bin" install flamegraph
    "$cargo_bin" install vimcats --features=cli
    "$cargo_bin" install --locked tree-sitter-cli
    "$cargo_bin" install --features 'pcre2' ripgrep # For Perl Compatible Regex
    sudo apt install -y libssl-dev

    # "$cargo_bin" install emmylua_ls
    # "$cargo_bin" install emmylua_check
    # "$cargo_bin" install emmylua_doc_cli

    "$cargo_bin" install cargo-update
    "$cargo_bin" install --locked --git https://github.com/Feel-ix-343/markdown-oxide.git markdown-oxide
else
    $cargo_bin install-update -a
fi

if [[ "$fresh_install" == true ]]; then
    sudo apt install build-essential libreadline-dev unzip
fi

##########
# Tinymist
##########

tinymist_repo="https://github.com/Myriad-Dreamin/tinymist.git"
tinymist_tag="v0.15.2"
tinymist_update=false
for arg in "$@"; do
    if [[ "$arg" == "tinymist" || "$arg" == "all" ]]; then
        if [[ "$fresh_install" == true ]]; then
            echo "Cannot do a fresh install and a tinymist update at the same time"
            exit 1
        fi

        tinymist_update=true
        echo "Updating tinymist..."
        break
    fi
done

if [ "$fresh_install" = true ] && [ "$tinymist_update" != true ]; then
    echo "Installing tinymist..."
fi

tinymist_git_dir="$HOME/.local/bin/tinymist"
[ ! -d "$tinymist_git_dir" ] && mkdir -p "$tinymist_git_dir"

if [[ "$fresh_install" == true ]]; then
    git clone $tinymist_repo "$tinymist_git_dir"
fi

cd "$tinymist_git_dir" || {
    echo "Error: Cannot cd to $tinymist_git_dir"
    exit 1
}

if [[ "$tinymist_update" == true ]]; then
    git checkout --force main
    git pull
fi

if [ "$fresh_install" = true ] || [ "$tinymist_update" = true ]; then
    git checkout --force "$tinymist_tag" || {
        echo "Error: Cannot checkout $tinymist_tag"
        exit 1
    }

    "$cargo_bin" install --path crates/tinymist-cli --locked tinymist-cli
    echo "tinymist build complete"
fi

cd "$HOME" || {
    echo "Error: Cannot cd to $HOME"
    exit 1
}

#########
# Emmylua
#########

emmylua_ls_repo="https://github.com/EmmyLuaLs/emmylua-analyzer-rust"
emmylua_ls_tag="main"
emmylua_ls_update=false
for arg in "$@"; do
    if [[ "$arg" == "emmylua_ls" || "$arg" == "all" ]]; then
        if [[ "$fresh_install" == true ]]; then
            echo "Cannot do a fresh install and a emmylua_ls update at the same time"
            exit 1
        fi

        emmylua_ls_update=true
        echo "Updating emmylua_ls..."
        break
    fi
done

if [ "$fresh_install" = true ] && [ "$emmylua_ls_update" != true ]; then
    echo "Installing emmylua_ls..."
fi

emmylua_ls_git_dir="$HOME/.local/bin/emmylua_ls"
[ ! -d "$emmylua_ls_git_dir" ] && mkdir -p "$emmylua_ls_git_dir"

if [[ "$fresh_install" == true ]]; then
    git clone $emmylua_ls_repo "$emmylua_ls_git_dir"
fi

cd "$emmylua_ls_git_dir" || {
    echo "Error: Cannot cd to $emmylua_ls_git_dir"
    exit 1
}

if [[ "$emmylua_ls_update" == true ]]; then
    git checkout --force main
    git pull
fi

if [ "$fresh_install" = true ] || [ "$emmylua_ls_update" = true ]; then
    git checkout --force "$emmylua_ls_tag" || {
        echo "Error: Cannot checkout $emmylua_ls_tag"
        exit 1
    }

    "$cargo_bin" install --path crates/emmylua_ls --locked emmylua_ls
    "$cargo_bin" install --path crates/emmylua_check --locked emmylua_check
    "$cargo_bin" install --path crates/emmylua_formatter --locked emmylua_formatter
    "$cargo_bin" install --path crates/emmylua_doc_cli --locked emmylua_doc_cli
    echo "emmylua_ls build complete"
fi

cd "$HOME" || {
    echo "Error: Cannot cd to $HOME"
    exit 1
}

#############
# C Ecosystem
#############

# TODO: For VM Tests I think there needs to be a way to skip this one. Takes hours even on a real
# computer.
# Last because clangd takes a while to build

llvm_repo="https://github.com/llvm/llvm-project/"
llvm_tag="llvmorg-22.1.8"
llvm_update=false
for arg in "$@"; do
    if [[ "$arg" == "llvm" || "$arg" == "all" ]]; then
        if [[ "$fresh_install" == true ]]; then
            echo "Cannot do a fresh install and a llvm update at the same time"
            exit 1
        fi

        llvm_update=true
        echo "Updating llvm..."
        break
    fi
done

if [ "$fresh_install" = true ] && [ "$llvm_update" != true ]; then
    echo "Installing llvm..."
fi

llvm_git_dir="$HOME/.local/bin/llvm"
[ ! -d "$llvm_git_dir" ] && mkdir -p "$llvm_git_dir"

if [[ "$fresh_install" == true ]]; then
    git clone $llvm_repo "$llvm_git_dir"
fi

cd "$llvm_git_dir" || {
    echo "Error: Cannot cd to $llvm_git_dir"
    exit 1
}

if [[ "$llvm_update" == true ]]; then
    git checkout --force main
    git pull
fi

if [ "$fresh_install" = true ] || [ "$llvm_update" = true ]; then
    git checkout --force "$llvm_tag" || {
        echo "Error: Cannot checkout $llvm_tag"
        exit 1
    }

    llvm_build_dir="$llvm_git_dir/build"
    [ ! -d "$llvm_build_dir" ] && mkdir -p "$llvm_build_dir"
    cd "$llvm_build_dir"

    # cmake "$llvm_git_dir/llvm/" -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra"
    # Compile non-native architectures for the benefit of Odin
    cmake ../llvm \
        -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra" \
        -DLLVM_TARGETS_TO_BUILD="X86;AArch64;ARM;RISCV;WebAssembly"

    # cd "$llvm_build_dir"
    # cmake --build "$llvm_build_dir" --target clang clangd llvm-config
    # ninja -C "$llvm_build_dir" clang clangd llvm-config
    ninja
    echo "llvm build complete"
fi

if [[ "$fresh_install" == true ]]; then
    cat <<EOF >>"$HOME/.bashrc"
export PATH="\$PATH:$llvm_git_dir/build/bin"
EOF
fi

cd "$HOME" || {
    echo "Error: Cannot cd to $HOME"
    exit 1
}

##################
# Odin Ecosystem #
##################

odin_repo="https://github.com/odin-lang/Odin"
odin_tag="dev-2026-07a"
odin_update=false
for arg in "$@"; do
    # TODO: Restore functionality on all. Issue is the hack for architecture flags
    if [[ "$arg" == "odin" ]]; then
        if [[ "$fresh_install" == true ]]; then
            echo "Cannot do a fresh install and an odin update at the same time"
            exit 1
        fi
        odin_update=true
        echo "Updating odin..."
        break
    fi
done

if [ "$fresh_install" = true ] && [ "$odin_update" != true ]; then
    echo "Installing odin..."
fi

odin_git_dir="$HOME/.local/bin/odin"
[ ! -d "$odin_git_dir" ] && mkdir -p "$odin_git_dir"
if [[ "$fresh_install" == true ]]; then
    git clone "$odin_repo" "$odin_git_dir"
fi

cd "$odin_git_dir" || {
    echo "Error: Cannot cd to $odin_git_dir"
    exit 1
}

if [[ "$odin_update" == true ]]; then
    git checkout --force master
    git pull
fi

if [ "$fresh_install" = true ] || [ "$odin_update" = true ]; then
    git checkout --force "$odin_tag" || {
        echo "Error: Cannot checkout $odin_tag"
        exit 1
    }

    git lfs install
    git lfs pull

    export LLVM_CONFIG="$HOME/.local/bin/llvm/build/bin/llvm-config"

    # Change line build_odin.sh 128 (Linux line) to:
    # LDFLAGS="$LDFLAGS -lstdc++ -ldl $($LLVM_CONFIG --libs core native aarch64 arm riscv webassembly passes --system-libs --libfiles)"
    make release-native

    echo "Odin build complete"
fi

# Make it available in the current shell right now
# export PATH="$PATH:$HOME/.local/bin/odin"
# Make it permanent
# echo 'export PATH="$PATH:$HOME/.local/bin/odin"' >> ~/.bashrc

if [[ "$fresh_install" == true ]]; then
    cat <<EOF >>"$HOME/.bashrc"
export PATH="\$PATH:$odin_git_dir"
EOF
fi

cd "$HOME" || {
    echo "Error: Cannot cd to $HOME"
    exit 1
}

ols_repo="https://github.com/DanielGavin/ols"
ols_tag="dev-2026-06"
ols_update=false
for arg in "$@"; do
    # TODO: Restore functionality on all once main Odin install is fixed.
    if [[ "$arg" == "ols" ]]; then
        if [[ "$fresh_install" == true ]]; then
            echo "Cannot do a fresh install and an ols update at the same time"
            exit 1
        fi

        ols_update=true
        echo "Updating ols..."
        break
    fi
done

if [ "$fresh_install" = true ] && [ "$ols_update" != true ]; then
    echo "Installing ols..."
fi

ols_git_dir="$HOME/.local/bin/ols"
[ ! -d "$ols_git_dir" ] && mkdir -p "$ols_git_dir"
if [[ "$fresh_install" == true ]]; then
    git clone "$ols_repo" "$ols_git_dir"
fi

cd "$ols_git_dir" || {
    echo "Error: Cannot cd to $ols_git_dir"
    exit 1
}

if [[ "$ols_update" == true ]]; then
    git checkout --force master
    git pull
fi

if [ "$fresh_install" = true ] || [ "$ols_update" = true ]; then
    git checkout --force "$ols_tag" || {
        echo "Error: Cannot checkout $ols_tag"
        exit 1
    }

    # Requires the odin binary to be on PATH
    ./build.sh
    ./odinfmt.sh

    echo "ols build complete"
fi

# Make it available in the current shell right now
# export PATH="$PATH:$HOME/.local/bin/ols"
# Make it permanent
# echo 'export PATH="$PATH:$HOME/.local/bin/ols"' >> ~/.bashrc

if [[ "$fresh_install" == true ]]; then
    cat <<EOF >>"$HOME/.bashrc"
export PATH="\$PATH:$ols_git_dir"
EOF
fi

cd "$HOME" || {
    echo "Error: Cannot cd to $HOME"
    exit 1
}

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
