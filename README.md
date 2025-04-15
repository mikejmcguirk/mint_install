Linux Mint Xia install script with using i3

## Features

This script manages installations and updates for the following:

- i3-color
- ImageMagick
- betterlockscreen
- Spotify
- Brave
- Neovim
- btop
- Lua LS
- Obsidian
- nvm
- Go Ecosystem
- Discord
- Nerd Font
- Ghostty build from source
- tmux
- Rust ecosystem

## Notes

- This is my personal script that uses my personal dotfiles. It may not be best for you
  - In particular, some of the scripting is based on my personal hardware, including the xrandr configuration
- This script removes multiple default Mint programs

## Script Directions

- Install Linux Mint as normal
  - This installation assumes you select install media drivers
- Once you have booted into Mint, open a terminal and run the following:

```bash
cd $HOME
sudo apt install -y git
git clone https://github.com/mikejmcguirk/mint_install.git
bash mint_install/mint_install.sh
# Select fresh install at the prompt
# Because the script is not run as sudo, it might not pull in all kernel updates
# The Rust install at the end requires manual confirmation
# Reboot at the end as directed
```

## Post-Install

- Run the following to set the i3 wallpaper:

```bash
betterlockscreen -u "$HOME/.config/wallpaper/alena-aenami-rooflinesgirl-1k-2-someday.jpg" --fx dim
```

- This script removes timesync. You will need to come up with your own backup solution
- The dotfiles pull in configs for an EasyEffects highpass filter. This can be manually enabled/disabled as needed
- Any GUI application settings not addressed by the dotfiles need to be handled manually
- The default redshift config does not use Geoclue and has no latitude and longitude set. Must be updated manually

## Known Issues

- On my system, DPMS activates after 20 minutes regardless of what settings I use. I have not been able to find a config file or session that causes this. Unsure if this is a hardware level config thing

## Future Improvements

- Further SSH hardening/stronger cryptography requirements
