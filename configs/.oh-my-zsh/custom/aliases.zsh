alias yubikey-switch='gpg-connect-agent "scd serialno" "learn --force" /bye'
alias composer='docker run --rm --interactive --tty --user "$(id -u):$(id -g)" --volume $PWD:/app --volume ${COMPOSER_HOME:-$HOME/.composer}:/tmp composer'
alias docker-compose='docker compose'
alias ec2-list-all='aws ec2 describe-instances --query '\''Reservations[].Instances[].[PrivateIpAddress,PrivateDnsName,InstanceId,Tags[?Key==`Name`].Value[]]'\'' --output text | sed '\''$!N;s/\n/ /'\'''
alias bw="flatpak run --command=bw com.bitwarden.desktop"

# IDEs with gpg agent
alias datagrip-ssh='SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)" datagrip &'
alias phpstorm-ssh='SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)" phpstorm &'
alias goland-ssh='SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket) goland &'
alias pycharm-ssh='SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket) pycharm &'
alias webstorm-ssh='SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket) webstorm &'
alias intellij-ssh='SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket) idea &'
