#!/bin/bash
# This script prepares a new system to use a YubiKey with GnuPG for SSH authentication.

# Exit immediately if a command exits with a non-zero status.
set -e

# set working directory to script directory
cd "$(dirname "$0")"
SCRIPT_DIR="$(pwd)"
DOTFILES_ROOT="$(cd .. && pwd)"

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
    chmod +x ./arch/install_all.sh
    ./arch/install_all.sh
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

GPG_EXPORT_DIR="$DOTFILES_ROOT/configs/gpg"
if [ -d "$GPG_EXPORT_DIR" ]; then
    mapfile -d '' local_gpg_exports < <(find "$GPG_EXPORT_DIR" -maxdepth 1 -type f -name '*.asc' -print0 | sort -z)
    if [ ${#local_gpg_exports[@]} -gt 0 ]; then
        info "Importing local GPG key updates from $GPG_EXPORT_DIR..."
        gpg --import "${local_gpg_exports[@]}" || error "Failed to import local GPG key updates."
    fi
fi

# --- Stow configs ---
if [ ! -d ~/fonts ]; then
    mkdir ~/fonts
fi

cd "$DOTFILES_ROOT"
stow -vv -t ~ --ignore='^project$' configs

PROJECT_CONFIG_DIR="$DOTFILES_ROOT/configs/project"
if [ -d "$PROJECT_CONFIG_DIR" ]; then
    if [ -L "$HOME/project" ]; then
        info "Removing stowed ~/project symlink so repositories stay outside the dotfiles repo."
        rm "$HOME/project"
    fi

    mkdir -p "$HOME/project"
    for package_dir in "$PROJECT_CONFIG_DIR"/*; do
        [ -d "$package_dir" ] || continue
        package_name="$(basename "$package_dir")"
        mkdir -p "$HOME/project/$package_name"
        stow -vv -d "$PROJECT_CONFIG_DIR" -t "$HOME/project/$package_name" "$package_name"
    done
fi

BASH_GPG_HOOK_START="# dotfiles-gpg-agent-start"
if ! grep -qF "$BASH_GPG_HOOK_START" "$HOME/.bashrc" 2>/dev/null; then
    cat >> "$HOME/.bashrc" <<'EOF'

# dotfiles-gpg-agent-start
if [ -r "$HOME/.config/shell/gpg-agent.sh" ]; then
    . "$HOME/.config/shell/gpg-agent.sh"
fi
# dotfiles-gpg-agent-end
EOF
fi

cd "$SCRIPT_DIR"
info "Clone repositories..."
chmod +x ./generic/clone_repositories.sh
./generic/clone_repositories.sh
