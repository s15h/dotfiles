sudo apt update

sudo apt install -y \
chromium-browser \
discord \
firefox \
git \
gnupg2 \
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
