#!/usr/bin/env bash

set -euo pipefail

info() {
  echo "[INFO] $1"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

desktop_entry_path() {
  local desktop_name="$1"
  local dir

  for dir in \
    "$HOME/.local/share/applications" \
    "$HOME/.local/share/flatpak/exports/share/applications" \
    "/var/lib/flatpak/exports/share/applications" \
    "/usr/local/share/applications" \
    "/usr/share/applications"; do
    if [ -f "$dir/$desktop_name" ]; then
      printf '%s\n' "$dir/$desktop_name"
      return 0
    fi
  done

  return 1
}

find_desktop_entry() {
  local desktop_name

  for desktop_name in "$@"; do
    if desktop_entry_path "$desktop_name" >/dev/null; then
      printf '%s\n' "$desktop_name"
      return 0
    fi
  done

  return 1
}

install_web_launcher() {
  local app_name="$1"
  local app_url="$2"
  local icon_url="$3"
  local applications_dir="$HOME/.local/share/applications"
  local icon_dir="$applications_dir/icons"
  local icon_path="$icon_dir/$app_name.png"
  local desktop_file="$applications_dir/$app_name.desktop"

  mkdir -p "$applications_dir" "$icon_dir"
  curl -fsSL -o "$icon_path" "$icon_url"

  cat >"$desktop_file" <<EOF
[Desktop Entry]
Version=1.0
Name=$app_name
Comment=$app_name
Exec=xdg-open $app_url
Terminal=false
Type=Application
Icon=$icon_path
StartupNotify=true
EOF

  chmod +x "$desktop_file"
}

install_pi_dev() {
  local icon_url="https://www.google.com/s2/favicons?domain=pi.dev&sz=128"

  if command_exists omarchy-webapp-install; then
    omarchy-webapp-install "pi.dev" "https://pi.dev" "$icon_url"
  else
    install_web_launcher "pi.dev" "https://pi.dev" "$icon_url"
  fi
}

set_firefox_as_default_browser() {
  local firefox_desktop

  if ! command_exists xdg-settings || ! command_exists xdg-mime; then
    info "xdg-utils not available; skipping Firefox default browser setup."
    return
  fi

  if ! firefox_desktop=$(find_desktop_entry firefox.desktop org.mozilla.firefox.desktop org.mozilla.Firefox.desktop); then
    info "Firefox desktop entry not found; skipping default browser setup."
    return
  fi

  xdg-settings set default-web-browser "$firefox_desktop"
  xdg-mime default "$firefox_desktop" x-scheme-handler/http
  xdg-mime default "$firefox_desktop" x-scheme-handler/https

  info "Firefox set as the default browser."
}

set_bitwarden_as_default_password_manager() {
  local bitwarden_desktop
  local bitwarden_desktop_path
  local mime_types_line
  local mime_type
  local did_set_handler=false

  if ! command_exists xdg-mime; then
    info "xdg-mime not available; skipping Bitwarden handler setup."
    return
  fi

  if ! bitwarden_desktop=$(find_desktop_entry com.bitwarden.desktop.desktop bitwarden.desktop com.bitwarden.desktop); then
    info "Bitwarden desktop entry not found; skipping password manager setup."
    return
  fi

  bitwarden_desktop_path="$(desktop_entry_path "$bitwarden_desktop")"

  if ! mime_types_line="$(grep '^MimeType=' "$bitwarden_desktop_path")"; then
    info "Bitwarden is installed and 1Password will be removed."
    return
  fi

  IFS=';' read -r -a declared_mime_types <<< "${mime_types_line#MimeType=}"
  for mime_type in "${declared_mime_types[@]}"; do
    case "$mime_type" in
      x-scheme-handler/bitwarden*)
        xdg-mime default "$bitwarden_desktop" "$mime_type"
        did_set_handler=true
        ;;
    esac
  done

  if [ "$did_set_handler" = true ]; then
    info "Bitwarden set as the preferred password manager."
  else
    info "Bitwarden is installed and 1Password will be removed."
  fi
}

remove_pacman_packages_if_installed() {
  local package
  local packages_to_remove=()

  if ! command_exists pacman; then
    return
  fi

  for package in "$@"; do
    if pacman -Q "$package" >/dev/null 2>&1; then
      packages_to_remove+=("$package")
    fi
  done

  if [ "${#packages_to_remove[@]}" -gt 0 ]; then
    sudo pacman -Rns --noconfirm "${packages_to_remove[@]}"
  fi
}

remove_flatpak_apps_if_installed() {
  local app_id
  local apps_to_remove=()

  if ! command_exists flatpak; then
    return
  fi

  for app_id in "$@"; do
    if flatpak info "$app_id" >/dev/null 2>&1; then
      apps_to_remove+=("$app_id")
    fi
  done

  if [ "${#apps_to_remove[@]}" -gt 0 ]; then
    flatpak uninstall -y --delete-data "${apps_to_remove[@]}"
  fi
}

remove_web_apps() {
  local app_name
  local applications_dir="$HOME/.local/share/applications"
  local icon_dir="$applications_dir/icons"

  if command_exists omarchy-webapp-remove; then
    omarchy-webapp-remove "$@"
    return
  fi

  for app_name in "$@"; do
    rm -f "$applications_dir/$app_name.desktop"
    rm -f "$icon_dir/$app_name.png"
  done
}

refresh_application_shortcuts() {
  mkdir -p "$HOME/.local/share/applications"

  if command_exists update-desktop-database; then
    update-desktop-database "$HOME/.local/share/applications"
  fi

  if command_exists omarchy-restart-walker; then
    omarchy-restart-walker
  fi
}

install_pi_dev
set_firefox_as_default_browser
set_bitwarden_as_default_password_manager

remove_pacman_packages_if_installed \
  1password-beta \
  1password-cli \
  libreoffice-fresh \
  xournalpp

remove_flatpak_apps_if_installed \
  com.onepassword.OnePassword \
  com.google.Chrome \
  com.google.ChromeDev \
  com.github.xournalpp.xournalpp \
  org.libreoffice.LibreOffice \
  org.libreoffice.LibreOffice.BundledExtension.Voikko \
  org.libreoffice.LibreOffice.Help \
  org.libreoffice.LibreOffice.Locale \
  us.zoom.Zoom

remove_web_apps \
  "Basecamp" \
  "ChatGPT" \
  "Figma" \
  "Fizzy" \
  "Google Contacts" \
  "Google Maps" \
  "Google Messages" \
  "Google Photos" \
  "HEY" \
  "WhatsApp" \
  "X" \
  "Zoom"

refresh_application_shortcuts
