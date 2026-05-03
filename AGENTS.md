# AGENTS.md

## Repository purpose
This repository is a personal Linux workstation bootstrap and dotfiles setup. The main entrypoint is `initial-startup/preparation.sh`, which installs OS-specific packages, installs shared desktop tooling, stows configs into `$HOME`, configures GPG/YubiKey-backed Git signing, clones default repositories into `~/project`, and can optionally bootstrap logins from Bitwarden.

## High-value commands
Only commands directly observed in the repository are listed here.

### Primary setup flow
- `./initial-startup/preparation.sh`
  - Main bootstrap entrypoint.
  - Detects Arch vs Debian-family systems from `/etc/os-release`.
  - Runs OS-specific installers, then generic installers/configuration.

### OS-specific installers
- `./initial-startup/arch/install_all.sh`
- `./initial-startup/debian/install_all.sh`
- `./initial-startup/debian/install_docker.sh`
- `./initial-startup/debian/install_ghostty.sh`
- `./initial-startup/debian/install_spotify.sh`

### Generic follow-up scripts
- `./initial-startup/generic/install_all.sh`
- `./initial-startup/generic/configure_apps.sh`
- `./initial-startup/generic/clone_repositories.sh`
- `./initial-startup/generic/bootstrap_logins.sh`

### Direct config deployment command
Observed in `initial-startup/preparation.sh`:

```bash
stow -vv -t ~ --ignore='^project$' configs
```

## Repository layout
- `initial-startup/`
  - Installation/bootstrap scripts.
  - `preparation.sh` orchestrates everything.
  - `arch/` and `debian/` contain package-manager-specific installers.
  - `generic/` contains cross-distro application install/config/bootstrap steps.
- `configs/`
  - Files meant to be stowed into `$HOME`.
  - `.config/shell/` contains reusable shell snippets for GPG agent and Bun PATH setup.
  - `.oh-my-zsh/custom/` sources those shell snippets and defines aliases.
  - `project/` contains per-workspace config that is stowed into `~/project/<name>` instead of directly into `$HOME`.
  - `gpg/` contains exported `.asc` public keys that are imported during setup.
- `README.md`
  - Human-facing install notes and YubiKey/GPG operational guidance.

## Architecture and control flow
`initial-startup/preparation.sh` is the control plane. Its observed flow is:

1. Detect OS from `/etc/os-release`.
2. Run `arch/install_all.sh` or `debian/install_all.sh`.
3. Run `generic/install_all.sh`.
4. Run `generic/configure_apps.sh`.
5. Import the public key from `https://github.com/s15h.gpg`.
6. Import any local `.asc` files from `configs/gpg/`.
7. Refresh GPG smartcard state and generate `~/.config/git/signingkey.gitconfig` from the newest usable signing subkey.
8. Stow `configs/` into `$HOME`, excluding `configs/project` from the main stow pass.
9. Re-stow each package inside `configs/project/` into `~/project/<package_name>`.
10. Append Bash hooks that source `~/.config/shell/gpg-agent.sh` and `~/.config/shell/bun.sh` if those hooks are not already present.
11. Run `generic/clone_repositories.sh`.
12. Run `generic/bootstrap_logins.sh`.

## Non-obvious repository conventions
### `configs/project` is intentionally special
`configs/project` is excluded from the root stow command and then re-stowed package-by-package into `~/project/<package_name>`. Do not treat it like ordinary home-directory dotfiles.

### `~/project` must be a real directory
`initial-startup/generic/clone_repositories.sh` exits with an error if `~/project` is a symlink. The preparation flow explicitly removes a stowed `~/project` symlink before cloning repositories.

### Shell initialization is split across stowed files
- Bash hooks are appended directly to `~/.bashrc` by `preparation.sh`.
- Zsh loads `configs/.oh-my-zsh/custom/gpg.zsh` and `bun.zsh`.
- Those Zsh files source the canonical scripts in `~/.config/shell/gpg-agent.sh` and `~/.config/shell/bun.sh`.

When changing shell behavior, keep the reusable logic in `configs/.config/shell/*.sh` and the shell-specific glue in the Oh My Zsh files.

### Git signing config is generated, not hand-edited
`configs/.gitconfig` includes `~/.config/git/signingkey.gitconfig`, and `preparation.sh` rewrites that file based on the latest usable signing subkey fingerprint, with a trailing `!`. If signing behavior changes, inspect both the generated include file and the key-discovery logic in `preparation.sh`.

### Per-workspace Git identity exists
There is a conditional include for `~/project/dignitas/` in `configs/.gitconfig`, which points to `configs/project/dignitas/.gitconfig` for alternate identity settings.

## Application/install behavior worth knowing
Observed package/app behavior:
- Debian installer uses `apt` and then delegates Docker, Ghostty, and Spotify setup to dedicated scripts.
- Arch installer uses `pacman` only.
- Generic installer ensures the Flathub remote exists, then installs Bitwarden, Bruno, Firefox, Obsidian, Zed, Crush, kubectl, talosctl, and Oh My Zsh.
- Bitwarden CLI access is expected to come from the Flatpak app via a wrapper script named `bw` in `~/.local/bin`.
- `generic/configure_apps.sh` also removes a set of existing apps/packages, including 1Password, Chrome, LibreOffice, Xournal++, Zoom, and several named web apps.

If you modify install behavior, inspect both `generic/install_all.sh` and `generic/configure_apps.sh`; they are complementary.

## Shell/code style patterns
Observed patterns across the shell scripts:
- Most executable scripts use `#!/usr/bin/env bash` plus `set -euo pipefail`.
- Helper functions are lower_snake_case (`command_exists`, `ensure_bitwarden_session`, `set_firefox_as_default_browser`).
- Small logging helpers (`info`, `warn`, sometimes `error`) are defined inline per script rather than shared.
- The repository mixes Bash and Zsh intentionally: `clone_repositories.sh` is Zsh, most other scripts are Bash.

Do not blindly convert scripts between Bash and Zsh; preserve the shell the file already uses.

## Login bootstrap behavior
`initial-startup/generic/bootstrap_logins.sh` reads `~/.config/dotfiles/login-bootstrap.conf` and supports only these observed entry formats:

```text
gh|<hostname>|<bitwarden item with token in the password field>
docker|<registry>|<username>|<bitwarden item with password or token in the password field>
```

Important observed behavior:
- The file is expected to contain Bitwarden item names/IDs, not raw secrets.
- The script prompts by default unless `DOTFILES_BOOTSTRAP_LOGINS` is set to `always` or `never`.
- If there is no interactive terminal, bootstrap is skipped.
- The script can use either a native `bw` binary or the Bitwarden Flatpak CLI command.

## External dependencies and network assumptions
The setup scripts rely heavily on network access and privileged package installation. Observed external dependencies include:
- GitHub (`https://github.com/s15h.gpg`, `git@github.com:s15h/default-repositories.git`)
- Azure DevOps host key scan (`ssh.dev.azure.com`)
- Docker apt repository
- Ghostty apt repository
- Spotify apt repository
- Flathub
- Bun install script
- Oh My Zsh install script

Repository cloning also assumes access to the private `s15h/default-repositories` repository.

## Testing and validation
No automated test suite, lint command, Makefile, package manifest, or CI workflow was found in this repository.

For changes here, validation is script- and flow-specific rather than test-suite-driven. Future agents should verify the exact script(s) they touch and keep changes grounded in the existing bootstrap flow.

## Documentation gotchas
- `README.md` refers to `preperation.sh` once, but the actual script in the repository is `initial-startup/preparation.sh`.
- The repository is not an application with a build step; most meaningful changes are to shell scripts and stowed config files.
