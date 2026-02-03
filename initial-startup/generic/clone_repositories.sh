#!/usr/bin/env zsh

# Ensure zsh-based GPG/SSH agent config is loaded for git clone.
if [[ -r "$HOME/.oh-my-zsh/custom/gpg.zsh" ]]; then
  source "$HOME/.oh-my-zsh/custom/gpg.zsh"
fi

# get fingerprint of github key
ssh-keyscan github.com >> ~/.ssh/known_hosts

# go to root level of project
cd ~/

# clone private repositories
git clone git@github.com:s15h/default-repositories.git

# get list of private from file
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_LIST="$SCRIPT_DIR/default-repositories/private.txt"
if [ ! -f "$REPO_LIST" ]; then
    echo "[ERROR] Repository list file not found: $REPO_LIST"
    exit 1
else
  if [ ! -d ~/project/private ]; then
    mkdir ~/project/private
  fi
  cd ~/project/private
  while read repo; do
    echo "Cloning $repo"
    git clone $repo
  done < $REPO_LIST
fi

REPO_LIST="$SCRIPT_DIR/default-repositories/dignitas.txt"
if [ ! -f "$REPO_LIST" ]; then
    echo "[ERROR] Repository list file not found: $REPO_LIST"
    exit 1
else
  if [ ! -d ~/project/dignitas ]; then
    mkdir ~/project/dignitas
  fi
  cd ~/project/dignitas
  while read repo; do
    echo "Cloning $repo"
    git clone $repo
  done < $REPO_LIST
fi

rm -rf "$SCRIPT_DIR"/default-repositories
