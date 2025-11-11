sudo apt update

sudo apt install -y \
git \
gnupg2 \
pcscd \
pcsc-tools \
yubikey-manager \
openssh-client \
pinentry-tty \
zsh \
openvpn \
discord \
firefox \
chromium-browser \
neovim \
tmux -y\

# install docker
chmod +x ./debian/install_docker.sh
./debian/install_docker.sh
