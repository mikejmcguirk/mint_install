cat <<EOF >>"$HOME/.bashrc"

alias mint-install="bash \$HOME/mint_install/mint_install.sh"
EOF

##################
# System Hardening
##################

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

###########
# Utilities
###########

sudo apt install -y fd-find
sudo apt install -y inotify-tools
sudo apt install -y vim
sudo apt install -y sqlite3
sudo apt install -y virtualbox

sudo apt install -y ninja-build
sudo apt install -y shellcheck

# perf would be installed here if needed
echo "kernel.perf_event_paranoid = -1" | sudo tee /etc/sysctl.conf

#####
# Git
#####

sudo apt install -y git-all

git config --global user.name "Mike J. McGuirk"
git config --global user.email "mike.j.mcguirk@gmail.com"
git config --global init.defaultBranch master

# Rebase can do goofy stuff
git config --global pull.rebase false

# libsecret-1-0 already installed
sudo apt install -y libsecret-1-dev
libsecret_path="/usr/share/doc/git/contrib/credential/libsecret"
cd "$libsecret_path" || {
    echo "Error: Cannot cd to $libsecret_path"
    exit 1
}

sudo make
git config --global credential.helper $libsecret_path/git-credential-libsecret
cd "$HOME" || {
    echo "Error: Cannot cd to $HOME"
    exit 1
}

sudo apt install git-lfs

###########
# Wireguard
###########

sudo apt install -y wireguard
# resolvconf is a service in Mint Xia
sudo apt install -y natpmpc

##################
# General Programs
##################

sudo apt install -y vlc
sudo apt install -y hexchat
sudo apt install -y libreoffice
sudo apt install -y wordnet
sudo apt install -y qbittorrent
sudo apt install -y kolourpaint
sudo apt install -y unrar

sudo apt remove -y drawing
sudo apt remove -y mintupdate
sudo apt remove -y timeshift

##########
# Redshift
##########

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

##############
# Get Dotfiles
##############

dotfiles_url="https://github.com/mikejmcguirk/dotfiles"

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

################
# Window Manager
################

sudo apt install -y i3
sudo apt install -y xautolock
sudo apt install -y playerctl # Detect playing media to avoid screen lock

sudo apt install -y easyeffects

sudo apt install -y feh
sudo apt install -y picom

sudo apt install -y polybar

sudo apt install -y mint-themes # Should already be there but just to be sure

######
# rofi
######

sudo apt install -y rofi
sudo apt install -y maim  # Use rofi as a wrapper for screenshots
sudo apt install -y xsel  # Preferred by Neovim
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

#####################
# i3lock-color Deps #
#####################

sudo apt remove -y i3lock

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

#########################
# betterlockscreen Deps #
#########################

sudo apt install -y feh # for wallpaper
sudo apt install -y bc
sudo apt install -y xautolock

##################
# Python Ecosystem
##################

sudo apt install -y python3-full
sudo apt install -y python3-pip
sudo apt install -y pipx

pipx ensurepath # Adds ~/.local/bin to path
# Add pipx completions
cat <<'EOF' >>"$HOME/.bashrc"

eval "$(register-python-argcomplete pipx)"
EOF

pipx install nvitop
# TODO: What is happening here?
# pipx install beautysh
pipx runpip beautysh install setuptools
pipx install ruff
pipx install python-lsp-server[all]
pipx inject python-lsp-server pylsp-mypy
pipx install ty

#############
# Tmux Deps #
#############

sudo apt install -y bison
sudo apt install -y libncurses-dev
sudo apt install -y libevent-dev
sudo apt install -y automake
sudo apt install -y autoconf
