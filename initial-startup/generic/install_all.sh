#!/usr/bin/env bash

set -euo pipefail

install_desktop_app() {
  local app_id="$1"
  local label="$2"
  local binary="${3:-}"

  if [ -n "$binary" ] && command -v "$binary" >/dev/null 2>&1; then
    echo "$label already installed."
  elif flatpak info "$app_id" >/dev/null 2>&1; then
    echo "$label already installed."
  else
    flatpak install -y flathub "$app_id"
  fi
}

install_desktop_app com.bitwarden.desktop "Bitwarden"
install_desktop_app com.usebruno.Bruno "Bruno"
install_desktop_app org.mozilla.firefox "Firefox" firefox
install_desktop_app md.obsidian.Obsidian "Obsidian"
install_desktop_app dev.zed.Zed "Zed" zed

# install oh my zsh
if [ ! -d ~/.oh-my-zsh ]; then
  printf 'y\n' | RUNZSH=no \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "Oh My Zsh already installed."
fi
