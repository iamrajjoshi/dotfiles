#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

symlink() {
    local src="$1" dst="$2"
    if [[ -f "$dst" && ! -L "$dst" ]]; then
        echo "Backing up $dst -> ${dst}.backup"
        mv "$dst" "${dst}.backup"
    fi
    ln -sf "$src" "$dst"
    echo "Linked $dst -> $src"
}

echo "=== dotfiles installer ==="
echo "Source: $DOTFILES_DIR"
echo

# Fish
echo "--- Fish ---"
mkdir -p ~/.config/fish
symlink "${DOTFILES_DIR}/fish/config.fish"    ~/.config/fish/config.fish
symlink "${DOTFILES_DIR}/fish/alias.fish"     ~/.config/fish/alias.fish
symlink "${DOTFILES_DIR}/fish/git.fish"       ~/.config/fish/git.fish
symlink "${DOTFILES_DIR}/fish/fish_plugins"   ~/.config/fish/fish_plugins

# Zsh
echo "--- Zsh ---"
symlink "${DOTFILES_DIR}/zsh/.zshrc"          ~/.zshrc
symlink "${DOTFILES_DIR}/zsh/.aliases.zsh"    ~/.aliases.zsh

# Starship
echo "--- Starship ---"
mkdir -p ~/.config
symlink "${DOTFILES_DIR}/starship.toml"       ~/.config/starship.toml

# Tmux
echo "--- Tmux ---"
symlink "${DOTFILES_DIR}/tmux/tmux.conf"      ~/.tmux.conf

# Ghostty
echo "--- Ghostty ---"
mkdir -p ~/.config/ghostty
symlink "${DOTFILES_DIR}/ghostty/config"      ~/.config/ghostty/config

# Zed
echo "--- Zed ---"
mkdir -p ~/.config/zed
symlink "${DOTFILES_DIR}/zed/settings.json"   ~/.config/zed/settings.json

# Git
echo "--- Git ---"
symlink "${DOTFILES_DIR}/.gitconfig"          ~/.gitconfig

echo
echo "=== dotfiles linked ==="

# Install Fisher if missing
if command -v fish >/dev/null 2>&1; then
    if ! fish -c 'functions -q fisher' 2>/dev/null; then
        echo "Installing Fisher..."
        fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher && fisher update'
    fi
fi

# Install Starship if missing
if ! command -v starship >/dev/null 2>&1; then
    echo "Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh
fi

# Install TPM if missing
if [[ ! -d ~/.tmux/plugins/tpm ]]; then
    echo "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi
