#!/usr/bin/env bash

set -euo pipefail

CONFIG_FILE="${HOME}/.config/dotfiles/login-bootstrap.conf"
BITWARDEN_SESSION_WAS_SET="${BW_SESSION:-}"
BW_SESSION_VALUE=""
BW_UNLOCKED_IN_SCRIPT=false

info() {
  echo "[INFO] $1"
}

warn() {
  echo "[WARN] $1" >&2
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

trim() {
  local value="$1"

  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

bw_cli() {
  if command_exists bw; then
    bw "$@"
  elif command_exists flatpak && flatpak info com.bitwarden.desktop >/dev/null 2>&1; then
    flatpak run --command=bw com.bitwarden.desktop "$@"
  else
    return 1
  fi
}

has_active_config_entries() {
  [ -f "$CONFIG_FILE" ] && grep -Eqv '^[[:space:]]*(#|$)' "$CONFIG_FILE"
}

should_run_bootstrap() {
  case "${DOTFILES_BOOTSTRAP_LOGINS:-ask}" in
    always)
      return 0
      ;;
    never)
      return 1
      ;;
  esac

  if [ ! -t 0 ]; then
    info "No interactive terminal available; skipping login bootstrap."
    return 1
  fi

  printf "Run supported login bootstrap using Bitwarden? [y/N] "
  read -r answer

  case "$answer" in
    y|Y|yes|YES)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

bitwarden_status() {
  local status_output

  if ! status_output="$(bw_cli status 2>/dev/null)"; then
    return 1
  fi

  sed -n 's/.*"status":"\([^"]*\)".*/\1/p' <<<"$status_output"
}

ensure_bitwarden_session() {
  local status

  if ! bw_cli --version >/dev/null 2>&1; then
    warn "Bitwarden CLI is not available; skipping login bootstrap."
    return 1
  fi

  status="$(bitwarden_status || true)"

  if [ "$status" = "unauthenticated" ]; then
    info "Logging into Bitwarden CLI..."
    bw_cli login
  fi

  if [ -n "$BITWARDEN_SESSION_WAS_SET" ]; then
    BW_SESSION_VALUE="$BITWARDEN_SESSION_WAS_SET"
    export BW_SESSION="$BW_SESSION_VALUE"
  fi

  status="$(bitwarden_status || true)"
  if [ "$status" != "unlocked" ]; then
    info "Unlocking Bitwarden CLI..."
    BW_SESSION_VALUE="$(bw_cli unlock --raw)"
    export BW_SESSION="$BW_SESSION_VALUE"
    BW_UNLOCKED_IN_SCRIPT=true
  fi

  bw_cli sync >/dev/null
}

bitwarden_get_password() {
  local item_name="$1"

  BW_SESSION="$BW_SESSION_VALUE" bw_cli get password "$item_name"
}

bootstrap_github_cli() {
  local host="$1"
  local bitwarden_item="$2"
  local token

  if ! command_exists gh; then
    warn "GitHub CLI is not installed; skipping GitHub auth for $host."
    return 0
  fi

  if gh auth status --hostname "$host" >/dev/null 2>&1; then
    info "GitHub CLI is already authenticated for $host."
    return 0
  fi

  token="$(bitwarden_get_password "$bitwarden_item")"
  printf '%s' "$token" | gh auth login --hostname "$host" --git-protocol ssh --with-token
  info "Configured GitHub CLI authentication for $host."
}

bootstrap_docker_registry() {
  local registry="$1"
  local username="$2"
  local bitwarden_item="$3"
  local password

  if ! command_exists docker; then
    warn "Docker is not installed; skipping Docker auth for $registry."
    return 0
  fi

  password="$(bitwarden_get_password "$bitwarden_item")"
  printf '%s' "$password" | docker login "$registry" --username "$username" --password-stdin
  info "Configured Docker authentication for $registry."
}

process_config_file() {
  local raw_type
  local raw_target
  local raw_arg3
  local raw_arg4
  local raw_extra
  local type
  local target
  local arg3
  local arg4

  while IFS='|' read -r raw_type raw_target raw_arg3 raw_arg4 raw_extra; do
    if [ -z "${raw_type:-}" ]; then
      continue
    fi

    type="$(trim "$raw_type")"
    if [ -z "$type" ] || [[ "$type" == \#* ]]; then
      continue
    fi

    target="$(trim "${raw_target:-}")"
    arg3="$(trim "${raw_arg3:-}")"
    arg4="$(trim "${raw_arg4:-}")"

    if [ -n "${raw_extra:-}" ]; then
      warn "Skipping invalid login bootstrap entry: $type|$target|$arg3|$arg4|..."
      continue
    fi

    case "$type" in
      gh)
        if [ -z "$target" ] || [ -z "$arg3" ] || [ -n "$arg4" ]; then
          warn "Skipping invalid GitHub entry in $CONFIG_FILE."
          continue
        fi
        if ! bootstrap_github_cli "$target" "$arg3"; then
          warn "GitHub bootstrap failed for $target."
        fi
        ;;
      docker)
        if [ -z "$target" ] || [ -z "$arg3" ] || [ -z "$arg4" ]; then
          warn "Skipping invalid Docker entry in $CONFIG_FILE."
          continue
        fi
        if ! bootstrap_docker_registry "$target" "$arg3" "$arg4"; then
          warn "Docker bootstrap failed for $target."
        fi
        ;;
      *)
        warn "Unsupported login bootstrap type '$type' in $CONFIG_FILE."
        ;;
    esac
  done <"$CONFIG_FILE"
}

cleanup_bitwarden_session() {
  if [ "$BW_UNLOCKED_IN_SCRIPT" = true ]; then
    BW_SESSION="$BW_SESSION_VALUE" bw_cli lock >/dev/null 2>&1 || true
    unset BW_SESSION
  fi
}

main() {
  trap cleanup_bitwarden_session EXIT

  if ! has_active_config_entries; then
    info "No login bootstrap entries found in $CONFIG_FILE; skipping."
    return 0
  fi

  if ! should_run_bootstrap; then
    info "Skipping login bootstrap."
    return 0
  fi

  if ! ensure_bitwarden_session; then
    return 0
  fi

  process_config_file
}

main "$@"
