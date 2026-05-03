if command -v gpgconf >/dev/null 2>&1; then
    if gpg_tty="$(tty 2>/dev/null)"; then
        export GPG_TTY="$gpg_tty"
    fi

    export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
    gpgconf --launch gpg-agent >/dev/null 2>&1

    if command -v gpg-connect-agent >/dev/null 2>&1; then
        gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
    fi
fi
