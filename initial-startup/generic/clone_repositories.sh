#!/usr/bin/env zsh

# Ensure GPG-backed SSH agent config is loaded for git clone.
if [[ -r "$HOME/.config/shell/gpg-agent.sh" ]]; then
  source "$HOME/.config/shell/gpg-agent.sh"
elif [[ -r "$HOME/.oh-my-zsh/custom/gpg.zsh" ]]; then
  source "$HOME/.oh-my-zsh/custom/gpg.zsh"
fi

# get fingerprint of github and azure devops
mkdir -p "$HOME/.ssh"
touch "$HOME/.ssh/known_hosts"
ssh-keyscan github.com >> "$HOME/.ssh/known_hosts"
ssh-keyscan ssh.dev.azure.com >> "$HOME/.ssh/known_hosts"

WORKSPACE_DIR="$HOME/project"
if [[ -L "$WORKSPACE_DIR" ]]; then
  echo "[ERROR] $WORKSPACE_DIR is a symlink. Re-run preparation so repositories are cloned outside the dotfiles repo."
  exit 1
fi

mkdir -p "$WORKSPACE_DIR"

REPO_LIST_ROOT="$(mktemp -d)"
trap 'rm -rf "$REPO_LIST_ROOT"' EXIT

# clone private repositories
git clone git@github.com:s15h/default-repositories.git "$REPO_LIST_ROOT/default-repositories"

# get list of private from file
REPO_LIST="$REPO_LIST_ROOT/default-repositories/private.txt"
if [ ! -f "$REPO_LIST" ]; then
    echo "[ERROR] Repository list file not found: $REPO_LIST"
    exit 1
else
  mkdir -p "$WORKSPACE_DIR/private"
  cd "$WORKSPACE_DIR/private"
  while IFS= read -r repo; do
    [[ -z "$repo" || "$repo" == \#* ]] && continue
    echo "Cloning $repo"
    git clone "$repo"
  done < "$REPO_LIST"
fi

REPO_LIST="$REPO_LIST_ROOT/default-repositories/dignitas.txt"
if [ ! -f "$REPO_LIST" ]; then
    echo "[ERROR] Repository list file not found: $REPO_LIST"
    exit 1
else
  mkdir -p "$WORKSPACE_DIR/dignitas"
  cd "$WORKSPACE_DIR/dignitas"
  while IFS= read -r repo; do
    [[ -z "$repo" || "$repo" == \#* ]] && continue
    echo "Cloning $repo"
    git clone "$repo"
  done < "$REPO_LIST"
fi

REPO_LIST="$REPO_LIST_ROOT/default-repositories/s15h.txt"
if [ -f "$REPO_LIST" ]; then
  mkdir -p "$WORKSPACE_DIR/s15h"
  cd "$WORKSPACE_DIR/s15h"
  while IFS= read -r repo; do
    [[ -z "$repo" || "$repo" == \#* ]] && continue
    echo "Cloning $repo"
    git clone "$repo"
  done < "$REPO_LIST"
fi

REPO_LIST="$REPO_LIST_ROOT/default-repositories/games.txt"
if [ -f "$REPO_LIST" ]; then
  mkdir -p "$WORKSPACE_DIR/games"
  cd "$WORKSPACE_DIR/games"
  while IFS= read -r repo; do
    [[ -z "$repo" || "$repo" == \#* ]] && continue
    echo "Cloning $repo"
    git clone "$repo"
  done < "$REPO_LIST"
fi
