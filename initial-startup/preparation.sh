#!/bin/bash
# This script prepares a new system to use a YubiKey with GnuPG for SSH authentication.

# Exit immediately if a command exits with a non-zero status.
set -e

# set working directory to script directory
cd "$(dirname "$0")"

# --- Helper Functions ---
info() {
    echo "[INFO] $1"
}

error() {
    echo "[ERROR] $1" >&2
    exit 1
}

# --- OS Detection ---
if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$ID
    ID_LIKE=${ID_LIKE:-}
else
    error "Cannot detect operating system."
fi

# --- Package Installation ---
info "Detecting package manager and installing dependencies..."

if [[ "$OS" == "arch" || "$ID_LIKE" == "arch" ]]; then
    info "Arch Linux detected."
    sudo pacman -Syu --noconfirm --needed git gnupg pcsclite yubikey-manager openssh pinentry zsh docker openvpn discord firefox chromium neovim fastfetch wofi waybar ccid yubikey-personalization tmux
elif [[ "$OS" == "debian" || "$OS" == "ubuntu" || "$ID_LIKE" == "debian" || "$ID_LIKE" == "ubuntu" ]]; then
    info "Debian-based system detected."
    chmod +x ./debian/install_all.sh
    ./debian/install_all.sh
else
    error "Unsupported operating system: $OS"
fi

chmod +x ./generic/install_all.sh
./generic/install_all.sh

info "Dependencies installed successfully."

# --- GPG Key Import ---
info "Importing GPG public key from https://github.com/s15h.gpg..."
if curl -sL https://github.com/s15h.gpg | gpg --import -; then
    info "GPG key imported successfully."
else
    error "Failed to import GPG key."
fi

# --- Stow configs ---
if [ ! -d ~/fonts ]; then
    mkdir ~/fonts
fi

cd ../
stow -vv  -t ~ configs


info "Clone repositories..."
chmod +x ./generic/clone_repositories.sh
./generic/clone_repositories.sh
