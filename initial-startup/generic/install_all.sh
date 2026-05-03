#!/usr/bin/env bash

set -euo pipefail

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

ensure_local_bin_dir() {
  mkdir -p "$HOME/.local/bin"
}

ensure_bun_on_path() {
  export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"

  case ":$PATH:" in
    *":$BUN_INSTALL/bin:"*)
      ;;
    *)
      export PATH="$BUN_INSTALL/bin:$PATH"
      ;;
  esac
}

local_bin_path() {
  printf '%s/.local/bin/%s\n' "$HOME" "$1"
}

install_binary_from_url() {
  local target_name="$1"
  local download_url="$2"
  local target_path
  local temp_dir
  local temp_path

  ensure_local_bin_dir
  target_path="$(local_bin_path "$target_name")"
  temp_dir="$(mktemp -d)"
  temp_path="$temp_dir/$target_name"

  trap 'rm -rf "$temp_dir"' RETURN
  curl -fsSL "$download_url" -o "$temp_path"
  chmod +x "$temp_path"
  install -m 0755 "$temp_path" "$target_path"
}

refresh_application_shortcuts() {
  mkdir -p "$HOME/.local/share/applications"

  if command_exists update-desktop-database; then
    update-desktop-database "$HOME/.local/share/applications"
  fi
}

ensure_flathub_remote() {
  if ! command_exists flatpak; then
    echo "Flatpak is not installed."
    return 1
  fi

  if ! flatpak remotes --columns=name | grep -qx 'flathub'; then
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  fi
}

install_flatpak_command_wrapper() {
  local wrapper_name="$1"
  local app_id="$2"
  local flatpak_command="${3:-$wrapper_name}"
  local wrapper_path="$HOME/.local/bin/$wrapper_name"
  local current_command=""

  if current_command="$(command -v "$wrapper_name" 2>/dev/null)"; then
    if [ "$current_command" != "$wrapper_path" ]; then
      return 0
    fi
  fi

  mkdir -p "$(dirname "$wrapper_path")"
  cat >"$wrapper_path" <<EOF
#!/usr/bin/env bash
exec flatpak run --command=$flatpak_command $app_id "\$@"
EOF
  chmod +x "$wrapper_path"
}

copy_flatpak_icons() {
  local app_id="$1"
  local install_location="$2"
  local icon_source
  local icon_target
  local icons_root="$install_location/files/share/icons"

  while IFS= read -r -d '' icon_source; do
    icon_target="$HOME/.local/share/icons/${icon_source#"$icons_root"/}"
    mkdir -p "$(dirname "$icon_target")"
    cp "$icon_source" "$icon_target"
  done < <(find "$icons_root" -type f -path "*/apps/$app_id.*" -print0 2>/dev/null)
}

install_flatpak_desktop_entry() {
  local app_id="$1"
  local install_location
  local desktop_source
  local desktop_target
  local exec_line
  local exec_args=""
  local replacement_exec

  install_location="$(flatpak info --show-location "$app_id")"
  desktop_source="$install_location/files/share/applications/$app_id.desktop"
  if [ ! -f "$desktop_source" ]; then
    desktop_source="$(find "$install_location/files/share/applications" -maxdepth 1 -type f -name '*.desktop' | head -n 1)"
  fi

  if [ -z "${desktop_source:-}" ] || [ ! -f "$desktop_source" ]; then
    echo "No desktop entry found for $app_id."
    return 1
  fi

  exec_line="$(sed -n 's/^Exec=//p' "$desktop_source" | head -n 1)"
  if [ -n "$exec_line" ] && [ "${exec_line#* }" != "$exec_line" ]; then
    exec_args="${exec_line#* }"
  fi

  replacement_exec="Exec=flatpak run $app_id"
  if [ -n "$exec_args" ]; then
    replacement_exec="$replacement_exec $exec_args"
  fi

  mkdir -p "$HOME/.local/share/applications"
  desktop_target="$HOME/.local/share/applications/$(basename "$desktop_source")"
  awk -v replacement_exec="$replacement_exec" '
    BEGIN { replaced = 0 }
    /^Exec=/ {
      print replacement_exec
      replaced = 1
      next
    }
    { print }
    END {
      if (!replaced) {
        print replacement_exec
      }
    }
  ' "$desktop_source" >"$desktop_target"

  copy_flatpak_icons "$app_id" "$install_location"
}

install_flatpak_app() {
  local app_id="$1"
  local label="$2"

  if flatpak info "$app_id" >/dev/null 2>&1; then
    echo "$label already installed."
  else
    flatpak install -y flathub "$app_id"
  fi
}

install_flatpak_gui_app() {
  local app_id="$1"
  local label="$2"

  install_flatpak_app "$app_id" "$label"
  install_flatpak_desktop_entry "$app_id"
}

install_desktop_app() {
  local app_id="$1"
  local label="$2"
  local binary="${3:-}"

  if [ -n "$binary" ] && command_exists "$binary"; then
    echo "$label already installed."
    return 0
  fi

  install_flatpak_app "$app_id" "$label"
}

install_bun() {
  local bun_bin="$HOME/.bun/bin/bun"

  if command_exists bun || [ -x "$bun_bin" ]; then
    ensure_bun_on_path
    echo "Bun already installed."
    return 0
  fi

  curl -fsSL https://bun.sh/install | bash
  ensure_bun_on_path
}

cleanup_legacy_pi_install() {
  rm -f "$HOME/.local/bin/pi"
  rm -f "$HOME/.local/bin/pi-ai"
  rm -f "$HOME/.local/share/applications/pi-ai.desktop"
  rm -rf "$HOME/.local/share/pi-ai"

  ensure_bun_on_path
  if command_exists bun; then
    bun remove -g @mariozechner/pi-coding-agent >/dev/null 2>&1 || true
  fi
}

install_crush() {
  install_bun
  cleanup_legacy_pi_install

  if command_exists omarchy-npx-install; then
    omarchy-npx-install @charmland/crush crush
  else
    bun add -g @charmland/crush >/dev/null
  fi
}

install_kubectl() {
  local kubectl_path

  kubectl_path="$(local_bin_path kubectl)"
  if command_exists kubectl || [ -x "$kubectl_path" ]; then
    echo "kubectl already installed."
    return 0
  fi

  install_binary_from_url kubectl "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
}

install_talosctl() {
  local talosctl_path

  talosctl_path="$(local_bin_path talosctl)"
  if command_exists talosctl || [ -x "$talosctl_path" ]; then
    echo "talosctl already installed."
    return 0
  fi

  install_binary_from_url talosctl "https://github.com/siderolabs/talos/releases/latest/download/talosctl-linux-amd64"
}

install_zenkit_web_app() {
  if command_exists omarchy-webapp-install; then
    omarchy-webapp-install "zenkit" https://app.zenkit.com "https://www.google.com/s2/favicons?domain=https://app.zenkit.com&sz=128"
  else
    echo "omarchy-webapp-install not available; skipping zenkit web app."
  fi
}

ensure_flathub_remote

install_flatpak_gui_app com.bitwarden.desktop "Bitwarden"
install_flatpak_command_wrapper bw com.bitwarden.desktop bw
install_flatpak_gui_app com.usebruno.Bruno "Bruno"
install_desktop_app org.mozilla.firefox "Firefox" firefox
if flatpak info org.mozilla.firefox >/dev/null 2>&1; then
  install_flatpak_desktop_entry org.mozilla.firefox
fi
install_flatpak_gui_app md.obsidian.Obsidian "Obsidian"
install_flatpak_gui_app dev.zed.Zed "Zed"
install_crush
install_kubectl
install_talosctl
install_zenkit_web_app
refresh_application_shortcuts

# install oh my zsh
if [ ! -d ~/.oh-my-zsh ]; then
  printf 'y\n' | RUNZSH=no \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "Oh My Zsh already installed."
fi
