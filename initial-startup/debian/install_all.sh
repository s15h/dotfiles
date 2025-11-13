sudo apt update

sudo apt install -y \
chromium-browser \
fastfetch \
git \
gnupg2 \
hyprland \
neovim \
openvpn \
pcscd \
pcsc-tools \
pinentry-tty \
openssh-client \
stow \
tmux \
waybar \
yubikey-manager \
zsh

# install docker
echo "Installing docker"
chmod +x ./debian/install_docker.sh
./debian/install_docker.sh

#install ghostty
echo "Installing ghostty"
chmod +x ./debian/install_ghostty.sh
./debian/install_ghostty.sh

# install spotify
echo "Installing spotify"
chmod +x ./debian/install_spotify.sh
./debian/install_spotify.sh
