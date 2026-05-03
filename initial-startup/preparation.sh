#!/bin/bash
# This script prepares a new system to use a YubiKey with GnuPG for SSH authentication.
# Run without arguments to execute all steps.
# Run with one or more step names to execute only those steps:
#   ./preparation.sh install_os_packages install_generic_packages
#   ./preparation.sh stow_configs
#   ./preparation.sh import_gpg_keys clone_repositories

# Exit immediately if a command exits with a non-zero status.
set -e

# set working directory to script directory
cd "$(dirname "$0")"
SCRIPT_DIR="$(pwd)"
DOTFILES_ROOT="$(cd .. && pwd)"
GPG_PRIMARY_KEY_FINGERPRINT="A5396EB208B1AF337D9CCF8D462680667361F6A4"

# --- Helper Functions ---
info() {
    echo "[INFO] $1"
}

warn() {
    echo "[WARN] $1" >&2
}

error() {
    echo "[ERROR] $1" >&2
    exit 1
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

set_dotfiles_origin_to_ssh() {
    local current_remote ssh_remote

    if ! git -C "$DOTFILES_ROOT" config user.signingkey >/dev/null 2>&1; then
        return 0
    fi

    if ! current_remote="$(git -C "$DOTFILES_ROOT" remote get-url origin 2>/dev/null)"; then
        return 0
    fi

    case "$current_remote" in
        git@github.com:*)
            return 0
            ;;
        https://github.com/*)
            ssh_remote="${current_remote#https://github.com/}"
            ssh_remote="git@github.com:${ssh_remote}"
            ;;
        *)
            return 0
            ;;
    esac

    git -C "$DOTFILES_ROOT" remote set-url origin "$ssh_remote"
    info "Updated dotfiles origin to SSH: $ssh_remote"
}

find_active_signing_subkey() {
    local key_listing

    key_listing="$(gpg --list-secret-keys --with-colons --fingerprint "$GPG_PRIMARY_KEY_FINGERPRINT" 2>/dev/null || true)"
    if [ -z "$key_listing" ]; then
        key_listing="$(gpg --list-keys --with-colons --fingerprint "$GPG_PRIMARY_KEY_FINGERPRINT" 2>/dev/null || true)"
    fi

    awk -F: '
        BEGIN {
            best_created = -1
            candidate = 0
        }
        /^(sub|ssb):/ {
            candidate = 0
            validity = $2
            created = $6 + 0
            expires = ($7 == "" ? 32503680000 : $7) + 0
            can_sign = index($12, "s") > 0

            if (validity !~ /[erdi]/ && can_sign && expires > systime()) {
                candidate = 1
                candidate_created = created
            }

            next
        }
        /^fpr:/ && candidate {
            if (candidate_created >= best_created) {
                best_created = candidate_created
                best_fingerprint = $10
            }

            candidate = 0
        }
        END {
            if (best_fingerprint != "") {
                print best_fingerprint "!"
            }
        }
    ' <<<"$key_listing"
}

refresh_gpg_smartcard_state() {
    info "Refreshing GPG smartcard state..."

    if command_exists gpg-connect-agent; then
        if gpg-connect-agent "scd serialno" "learn --force" /bye >/dev/null 2>&1; then
            if gpg --card-status >/dev/null 2>&1; then
                info "GPG smartcard state refreshed."
                return 0
            fi
        fi
    fi

    if gpg --card-status >/dev/null 2>&1; then
        info "GPG smartcard state refreshed."
        return 0
    fi

    warn "Could not read the GPG smartcard. Insert the YubiKey and rerun preparation if Git signing stays unavailable."
    return 1
}

configure_git_signing_key() {
    local signing_key
    local signing_config_path="$HOME/.config/git/signingkey.gitconfig"

    info "Configuring Git commit signing key..."
    mkdir -p "$(dirname "$signing_config_path")"
    signing_key="$(find_active_signing_subkey)"

    if [ -z "$signing_key" ]; then
        if [ -f "$signing_config_path" ]; then
            warn "No usable signing subkey detected; keeping existing Git signing key config."
        else
            warn "No usable signing subkey detected; Git signing key was not configured."
        fi
        return 1
    fi

    cat >"$signing_config_path" <<EOF
[user]
	signingkey = $signing_key
EOF

    info "Configured Git signing key: $signing_key"
}

# --- Step Functions ---

detect_os() {
    if [ -f /etc/os-release ]; then
        # freedesktop.org and systemd
        . /etc/os-release
        OS=$ID
        ID_LIKE=${ID_LIKE:-}
    else
        error "Cannot detect operating system."
    fi
}

install_os_packages() {
    info "Installing OS-specific packages..."

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

    info "OS-specific packages installed."
}

install_generic_packages() {
    info "Installing generic packages..."

    chmod +x ./generic/install_all.sh
    ./generic/install_all.sh

    chmod +x ./generic/configure_apps.sh
    ./generic/configure_apps.sh

    info "Generic packages installed."
}

import_gpg_keys() {
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

    refresh_gpg_smartcard_state || true
}

stow_configs() {
    info "Stowing configs..."

    if [ ! -d ~/fonts ]; then
        mkdir ~/fonts
    fi

    cd "$DOTFILES_ROOT"
    stow -vv -t ~ --ignore='^project$' configs
    configure_git_signing_key || true
    set_dotfiles_origin_to_ssh

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

    append_bash_hooks

    info "Configs stowed."
}

append_bash_hooks() {
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

    BASH_BUN_HOOK_START="# dotfiles-bun-start"
    if ! grep -qF "$BASH_BUN_HOOK_START" "$HOME/.bashrc" 2>/dev/null; then
        cat >> "$HOME/.bashrc" <<'EOF'

# dotfiles-bun-start
if [ -r "$HOME/.config/shell/bun.sh" ]; then
    . "$HOME/.config/shell/bun.sh"
fi
# dotfiles-bun-end
EOF
    fi
}

clone_repositories() {
    cd "$SCRIPT_DIR"
    info "Cloning repositories..."
    chmod +x ./generic/clone_repositories.sh
    ./generic/clone_repositories.sh
}

bootstrap_logins() {
    cd "$SCRIPT_DIR"
    info "Bootstrapping supported logins..."
    chmod +x ./generic/bootstrap_logins.sh
    ./generic/bootstrap_logins.sh
}

# --- Main ---
main() {
    detect_os

    if [ $# -eq 0 ]; then
        # Run all steps (default behavior, backward-compatible)
        install_os_packages
        install_generic_packages
        import_gpg_keys
        stow_configs
        clone_repositories
        bootstrap_logins
    else
        # Run only the requested steps
        for step in "$@"; do
            case "$step" in
                detect_os)           ;;
                install_os_packages)     install_os_packages ;;
                install_generic_packages) install_generic_packages ;;
                import_gpg_keys)         import_gpg_keys ;;
                stow_configs)            stow_configs ;;
                clone_repositories)      clone_repositories ;;
                bootstrap_logins)        bootstrap_logins ;;
                *)
                    echo "Unknown step: $step" >&2
                    echo "Available steps: detect_os install_os_packages install_generic_packages import_gpg_keys stow_configs clone_repositories bootstrap_logins" >&2
                    exit 1
                    ;;
            esac
        done
    fi

    info "Preparation complete."
}

main "$@"
