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

## GPG key
### subkey renewal
estimated Time required: 15 minutes.
subkey renewal only pushes expiration date forward.
There is no need to adjust keys on remote hosts and the yubikeys can remain the same.

1. Insert usb drive and check label with ```sudo dmesg | tail```
2. decrypt and mount usb drive
```bash
sudo cryptsetup luksOpen /dev/sda1 gnupg-secrets
# Check if the device label is correct (/dev/sdaX)

sudo mkdir -p /mnt/encrypted-storage

sudo mount /dev/mapper/gnupg-secrets /mnt/encrypted-storage
```
3. Create new temporary working directory and copy gpg keys to it
```bash
export GNUPGHOME=$(mktemp -d -t $(date +%Y.%m.%d)-XXXX)

cp -avi /mnt/encrypted-storage/gnupg_202112191956_CsF/* $GNUPGHOME/
```
4. Set the identity env variable and set the key variables
```bash
export IDENTITY="Sietze van den Bergh <sietze@s15h.nl>"
export KEYID=$(gpg -k --with-colons "$IDENTITY" | \
    awk -F: '/^pub:/ { print $5; exit }')

export KEYFP=$(gpg -k --with-colons "$IDENTITY" | \
    awk -F: '/^fpr:/ { print $10; exit }')

echo $KEYID $KEYFP
```
5. Set the certify pass. It's in bitwarden
```bash
export CERTIFY_PASS=ABCD-0123-IJKL-4567-QRST-UVWX
````
6. Set the new expiration date
```bash
export EXPIRATION=2027-02-01
```

7. Do the renewal
```bash
echo "$CERTIFY_PASS" | \
    gpg --batch --pinentry-mode=loopback \
        --passphrase-fd 0 --quick-set-expire "$KEYFP" "$EXPIRATION" \
    $(gpg -K --with-colons | awk -F: '/^fpr:/ { print $10 }' | tail -n "+2" | tr "\n" " ")
```
8. Export the updated public key:
```bash
gpg --armor --export $KEYID | sudo tee ~/$KEYID-$(date +%F).asc
```
Copy it from the home folder to this repo and commit it.

9. Then on every machine where the key is used, import it
```bash
gpg --import ~/dotfiles/*.asc
```

10. (optional) Upload the key
```bash
gpg --send-key $KEYID
```

11. unmount and close usb drive
```bash
sudo umount /mnt/encrypted-storage
sudo cryptsetup luksClose gnupg-secrets
```
