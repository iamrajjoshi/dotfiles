#!/bin/bash
set -euo pipefail

export PATH="$HOME/.local/bin:$HOME/.bun/bin:$PATH"
mkdir -p "$HOME/.local/bin"
case "$(uname -s)" in
    Darwin)
        command -v brew >/dev/null || { echo 'Install Homebrew from https://brew.sh, then rerun ./install.sh.' >&2; exit 1; }
        packages=(fish zsh starship lsd fzf bat fd git git-lfs git-delta gh python3 curl)
        [[ "${DOTFILES_USE_TMUX:-1}" == 0 ]] || packages+=(tmux)
        [[ "${DOTFILES_USE_WILLOW:-0}" == 0 ]] || packages+=(iamrajjoshi/tap/willow)
        brew install "${packages[@]}"
        ;;
    Linux)
        command -v apt-get >/dev/null || { echo 'Automatic Linux dependencies require Debian/Ubuntu. Install tools manually and rerun with --skip-deps.' >&2; exit 1; }
        sudo_cmd=()
        [[ "$(id -u)" == 0 ]] || sudo_cmd=(sudo)
        packages=(fish zsh fzf bat fd-find git git-lfs curl python3 unzip lsd ripgrep jq)
        [[ "${DOTFILES_USE_TMUX:-1}" == 0 ]] || packages+=(tmux)
        "${sudo_cmd[@]}" apt-get update
        "${sudo_cmd[@]}" env DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}"
        # Debian names these executables differently from Homebrew.
        command -v bat >/dev/null || ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
        command -v fd >/dev/null || ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
        # Match the appearance and icons used by the shared macOS setup.
        case "$(lsd --version)" in
            'lsd 0.'*|'lsd 1.0.'*|'lsd 1.1.'*)
                arch="$(dpkg --print-architecture)"
                case "$arch" in amd64|arm64) ;; *) echo "No pinned lsd build for $arch" >&2; exit 1 ;; esac
                package="$(mktemp -d)/lsd_1.2.0_${arch}.deb"
                curl -fL "https://github.com/lsd-rs/lsd/releases/download/v1.2.0/lsd_1.2.0_${arch}.deb" -o "$package"
                "${sudo_cmd[@]}" env DEBIAN_FRONTEND=noninteractive apt-get install -y "$package"
                rm -f "$package"
                rmdir "$(dirname "$package")"
                ;;
        esac
        if ! command -v starship >/dev/null; then
            installer="$(mktemp)"
            curl -fsSL https://starship.rs/install.sh -o "$installer"
            sh "$installer" -y -b "$HOME/.local/bin"
            rm -f "$installer"
        fi
        ;;
    *) echo 'Supported systems: macOS and Debian/Ubuntu Linux.' >&2; exit 1 ;;
esac
