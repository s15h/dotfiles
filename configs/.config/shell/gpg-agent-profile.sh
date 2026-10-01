# Set SSH_AUTH_SOCK for GUI applications (sourced from ~/.profile)
# This ensures GPG-agent-backed SSH keys work in apps like JetBrains IDEs
# that are launched from the desktop rather than a terminal.
#
# Unlike gpg-agent.sh, this file does no terminal interaction (no tty,
# no gpg-connect-agent) since it runs in the display manager context.

if command -v gpgconf >/dev/null 2>&1; then
    export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
fi
