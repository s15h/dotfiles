sudo apt update

sudo apt install -y \
chromium-browser \
discord \
firefox \
git \
gnupg2 \
hyprland \
neovim \
openvpn \
pcscd \
pcsc-tools \
pinentry-tty \
openssh-client \
tmux \
yubikey-manager \
zsh

# install discord
echo "Installing discord"
chmod +x ./debian/install_discord.sh
./debian/install_discord.sh

# install docker
echo "Installing docker"
chmod +x ./debian/install_docker.sh
./debian/install_docker.sh

# install spotify
echo "Installing spotify"
chmod +x ./debian/install_spotify.sh
./debian/install_spotify.sh
