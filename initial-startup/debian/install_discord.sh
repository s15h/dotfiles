# install discord if it is not installed
if ! dpkg -l | grep discord; then
  wget -O discord.deb https://discord.com/api/download?platform=linux&format=deb
  sudo dpkg -i discord.deb
fi
