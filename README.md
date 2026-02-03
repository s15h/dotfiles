# dotfiles

Dotfiles for debian and arch
Tested on debian and omarchy


## installation
Step 0: insert yubikey
step 1: `git clone https://github.com/s15h/dotfiles.git`
step 2: `dotfiles/initial-startup/preperation.sh`

## todo
- [ ] Add cloning games/s15h repositories
- [ ] Add dotfiles for openvpn
- ~/.openvpn/template-vpn.sh

## Project structure

- private
  - dotfiles
  - home-server
  - curriculum-vitae
  - zettelkasten
  - homelab
- dignitas
    - own git config
- s15h
    - open-gtd
- games
    - howtoavoidmeetings
    - openraam

## Yubikey ssh
To use yubikey as ssh this is added in the .zshrc

```
export GPG_TTY="$(tty)"
SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
export SSH_AUTH_SOCK
gpgconf --launch gpg-agent
```

## remaining setup
### ssh in jetbrains ui
To enable use of gpg agent in ssh actions in jetbrains ui elements we need to start up the application with the SSH_AUTH_SOCK variable set.
There are aliases for this available in bash_aliases but to make them work we need [the toolbox to create shell scripts](https://www.jetbrains.com/help/idea/working-with-the-ide-features-from-command-line.html#generate-shell-scripts)
Make sure the toolbox has writing permissions on the selected folder
