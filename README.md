# dotfiles

## todo
- [ ] Add install script for wanted software for debian
- [ ] Add install script for wanted software for Arch
- [ ] Add script for setting up dotfiles with stow
- [ ] Add script for cloning essential repositories
- [ ] Add dotfiles for zsh / ohmyzsh
- ~/.oh-my-zsh/custom/aliases.zsh
- ~/.oh-my-zsh/custom/gpg.zsh
- ~/.zshrc
- [ ] Add dotfiles for git
- ~/.gitconfig
- ~/project/dignitas/.gitconfig
- [ ] Add dotfiles for openvpn
- ~/.openvpn/template-vpn.sh

## wanted software

- [x] bitwarden cli
- [ ] docker -  debian done
- [ ] git -  debian done
- [ ] gnupg -  debian done
- [ ] jetbrains toolbox - tar download with version in url
- [ ] openvpn -  debian done
- [ ] ssh -  debian done
- [ ] zsh -  debian done
- [x] ohmyzsh
- [ ] hyprland -  debian done
- [ ] spotify -  debian done
- [x] discord
- [x] firefox
- [ ] chromium -  debian done
- [x] obsidian
- [ ] neovim - debian done
- [ ] fastfetch - debian done
- [ ] waybar - debian done
- [ ] Java in docker
- [ ] nodejs in docker
- [ ] composer in docker
- [ ] php in docker
- [ ] python in docker
- [ ] pip in docker
- [x] bruno
- [ ] Ghostty
- [ ] Tmux
- [ ] font 'PT mono'

## future wishlist
- [ ] Ladybird

## Project structure

- private
  - dotfiles
  - home-server
  - curriculum-vitae
  - zettelkasten
  - homelab
- students
  - *current school year* (ex 2025-2026)
    - wp1
    - wp2
    - wp3
    - wp4
- workshops
    - wp1
    - wp2
    - wp3
    - wp4
- presentations
    - wp1
    - wp2
    - wp3
    - wp4
- dignitas
    - own git config
- s15h
    - open-gtd
- games
    - howtoavoidmeetings
    - openraam

## Yubikey ssh
To use yubikey as ssh you need to add this to:

```
export GPG_TTY="$(tty)"
SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
export SSH_AUTH_SOCK
gpgconf --launch gpg-agent
```

Import the public key with
``gpg --import gpg-publickey``

Validate with ``gpg --import gpg-publickey``

part from the .bashrc file to your own .bashrc file

You will also need scdeamon to be installed


## remaining setup
### ssh in jetbrains ui
To enable use of gpg agent in ssh actions in jetbrains ui elements we need to start up the application with the SSH_AUTH_SOCK variable set.
There are aliases for this available in bash_aliases but to make them work we need [the toolbox to create shell scripts](https://www.jetbrains.com/help/idea/working-with-the-ide-features-from-command-line.html#generate-shell-scripts)
Make sure the toolbox has writing permissions on the selected folder
