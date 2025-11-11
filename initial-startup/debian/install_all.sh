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
tmux -y\
yubikey-manager \
zsh

# install docker
chmod +x ./debian/install_docker.sh
./debian/install_docker.sh

# install spotify
chmod +x ./debian/install_spotify.sh
./debian/install_spotify.sh
