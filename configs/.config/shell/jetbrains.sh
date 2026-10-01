# JetBrains IDE aliases with GPG agent SSH support
# These aliases launch JetBrains IDEs with SSH_AUTH_SOCK set so that
# GPG-agent-backed SSH keys work inside the IDE UI (e.g. VCS operations).
#
# Prerequisites:
#   - JetBrains Toolbox must have shell scripts enabled
#     https://www.jetbrains.com/help/idea/working-with-the-ide-features-from-command-line.html#generate-shell-scripts
#   - gpg-agent.sh must be sourced (handled by the dotfiles bash hook)

alias datagrip-ssh='SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)" datagrip &'
alias phpstorm-ssh='SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)" phpstorm &'
alias goland-ssh='SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)" goland &'
alias pycharm-ssh='SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)" pycharm &'
alias webstorm-ssh='SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)" webstorm &'
alias intellij-ssh='SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)" idea &'
