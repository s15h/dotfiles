# install bitwarden cli
if [ ! -f /usr/bin/bw ]; then
  flatpak install flathub com.bitwarden.desktop
else
  echo "Bitwarden CLI already installed."
fi

# install bruno
if [ ! -f /usr/bin/bruno ]; then
  flatpak install flathub com.usebruno.Bruno
else
  echo "Bruno already installed."
fi

# install discord
if [ ! -f /usr/bin/discord ]; then
  flatpak install flathub com.discordapp.Discord
else
  echo "Discord already installed."
fi

# install firefox
if [ ! -f /usr/bin/firefox ]; then
  flatpak install flathub org.mozilla.Firefox
else
  echo "Firefox already installed."
fi

#install obsidian flatpack
if [ ! -f /usr/bin/obsidian ]; then
  flatpak install flathub md.obsidian.Obsidian
else
  echo "Obsidian already installed."
fi

# install oh my zsh
if [ ! -d ~/.oh-my-zsh ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "Oh My Zsh already installed."
fi
