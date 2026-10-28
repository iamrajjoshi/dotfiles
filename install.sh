#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# Install shell dependencies before validating enabled terminal features.
SKIP_DEPS=0
FEATURE_ARGS=()
USE_TMUX=1
USE_WILLOW=0
[[ ! -f "$HOME/.config/dotfiles/features.conf" ]] || source "$HOME/.config/dotfiles/features.conf"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-deps) SKIP_DEPS=1 ;;
        --tmux) USE_TMUX=1; FEATURE_ARGS+=("$1") ;;
        --no-tmux) USE_TMUX=0; FEATURE_ARGS+=("$1") ;;
        --willow) USE_WILLOW=1; FEATURE_ARGS+=("$1") ;;
        --no-willow) USE_WILLOW=0; FEATURE_ARGS+=("$1") ;;
        --shell)
            [[ $# -ge 2 ]] || { echo '--shell requires a path' >&2; exit 2; }
            FEATURE_ARGS+=("$1" "$2"); shift ;;
        --help|-h)
            echo 'Usage: ./install.sh [--skip-deps] [--tmux|--no-tmux] [--willow|--no-willow] [--shell /absolute/path]'
            echo 'Install shell tools and shared configs on macOS or Debian/Ubuntu Linux.'
            echo '--skip-deps reuses installed tools. The installer does not change your login shell.'
            exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
    shift
done
OS="$(uname -s)"
case "$OS" in Darwin|Linux) ;; *) echo "Unsupported operating system: $OS" >&2; exit 1 ;; esac
export PATH="$HOME/.local/bin:$HOME/.bun/bin:$PATH"
if [[ "$SKIP_DEPS" == 0 ]]; then
    DOTFILES_USE_TMUX="$USE_TMUX" DOTFILES_USE_WILLOW="$USE_WILLOW" "$DOTFILES_DIR/scripts/install-dependencies.sh"
fi
# Resolve Homebrew once instead of hardcoding Intel or Apple Silicon paths.
if [[ "$OS" == Darwin ]]; then
    BREW_BIN="$(command -v brew)"
    mkdir -p "$HOME/.config/dotfiles"
    printf '%q shellenv fish | source\n' "$BREW_BIN" > "$HOME/.config/dotfiles/homebrew.fish"
    printf 'eval "$(%q shellenv zsh)"\n' "$BREW_BIN" > "$HOME/.config/dotfiles/homebrew.sh"
fi
"${DOTFILES_DIR}/scripts/configure-features.sh" "${FEATURE_ARGS[@]}"
source "$HOME/.config/dotfiles/features.conf"

symlink() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then return; fi
    if [[ -e "$dst" || -L "$dst" ]]; then
        local backup="${dst}.backup" n=0
        while [[ -e "$backup" || -L "$backup" ]]; do
            n=$((n + 1)); backup="${dst}.backup.$n"
        done
        echo "Backing up $dst -> $backup"
        mv "$dst" "$backup"
    fi
    ln -s "$src" "$dst"
    echo "Linked $dst -> $src"
}

restore_terminal_profile() {
    local profile_path="$1"
    local terminal_preferences_file
    terminal_preferences_file="$(mktemp -t raj-dotfiles-terminal)"

    if ! defaults export com.apple.Terminal "$terminal_preferences_file" >/dev/null 2>&1; then
        plutil -create xml1 "$terminal_preferences_file"
    fi

    /usr/libexec/PlistBuddy -c "Add :'Window Settings' dict" "$terminal_preferences_file" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Delete :'Window Settings':'Clear Dark'" "$terminal_preferences_file" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :'Window Settings':'Clear Dark' dict" "$terminal_preferences_file"
    /usr/libexec/PlistBuddy -c "Merge '$profile_path' :'Window Settings':'Clear Dark'" "$terminal_preferences_file"

    for key in "Default Window Settings" "Startup Window Settings"; do
        /usr/libexec/PlistBuddy -c "Delete :'$key'" "$terminal_preferences_file" 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Add :'$key' string 'Clear Dark'" "$terminal_preferences_file"
    done

    if ! defaults import com.apple.Terminal "$terminal_preferences_file" >/dev/null; then
        rm -f "$terminal_preferences_file"
        return 1
    fi
    rm -f "$terminal_preferences_file"
}

echo "=== dotfiles installer ==="
echo "Source: $DOTFILES_DIR"
echo

# Fish
echo "--- Fish ---"
mkdir -p ~/.config/fish
symlink "${DOTFILES_DIR}/fish/colors.fish"    ~/.config/fish/colors.fish
symlink "${DOTFILES_DIR}/fish/config.fish"    ~/.config/fish/config.fish
symlink "${DOTFILES_DIR}/fish/alias.fish"     ~/.config/fish/alias.fish
symlink "${DOTFILES_DIR}/fish/git.fish"       ~/.config/fish/git.fish

# Zsh
echo "--- Zsh ---"
symlink "${DOTFILES_DIR}/zsh/.zshrc"          ~/.zshrc
symlink "${DOTFILES_DIR}/zsh/.aliases.zsh"    ~/.aliases.zsh

# Starship: private overrides are appended outside the source repository.
echo "--- Starship ---"
mkdir -p ~/.config
STARSHIP_LOCAL="$HOME/.config/dotfiles/starship.local.toml"
if [[ -f "$STARSHIP_LOCAL" ]]; then
    merged="$(mktemp)"
    cat "$DOTFILES_DIR/starship.toml" > "$merged"
    printf '\n' >> "$merged"
    cat "$STARSHIP_LOCAL" >> "$merged"
    if [[ ! -f "$HOME/.config/starship.toml" ]] || ! cmp -s "$merged" "$HOME/.config/starship.toml"; then
        # Back up the destination as a link before writing a generated file.
        if [[ -e "$HOME/.config/starship.toml" || -L "$HOME/.config/starship.toml" ]]; then
            backup="$HOME/.config/starship.toml.backup"
            n=0
            while [[ -e "$backup" || -L "$backup" ]]; do n=$((n + 1)); backup="$HOME/.config/starship.toml.backup.$n"; done
            mv "$HOME/.config/starship.toml" "$backup"
        fi
        cp "$merged" "$HOME/.config/starship.toml"
        chmod 600 "$HOME/.config/starship.toml"
    fi
    rm "$merged"
else
    symlink "${DOTFILES_DIR}/starship.toml" ~/.config/starship.toml
fi

# Shared file-list appearance.
symlink "${DOTFILES_DIR}/lsd/config.yaml" ~/.config/lsd/config.yaml

# Ghostty and tmux are generated by configure-features.sh above.

# Zed
echo "--- Zed ---"
mkdir -p ~/.config/zed
symlink "${DOTFILES_DIR}/zed/settings.json"   ~/.config/zed/settings.json
symlink "${DOTFILES_DIR}/zed/keymap.json"     ~/.config/zed/keymap.json

# Sublime and iTerm2 preferences are retained in the repo for manual use only.

if [[ "$OS" == Darwin ]]; then
    echo "--- Terminal ---"
    restore_terminal_profile "${DOTFILES_DIR}/terminal/Clear Dark.terminal"
    echo "Restored Clear Dark as Terminal's startup and default profile"
    echo "--- Rectangle ---"
    defaults import com.knollsoft.Rectangle "${DOTFILES_DIR}/rectangle/com.knollsoft.Rectangle.plist" >/dev/null
    echo "Restored Rectangle shortcuts"

    echo "--- Git ---"
    symlink "${DOTFILES_DIR}/.gitconfig" ~/.gitconfig
else
    echo 'Preserving Linux Git configuration (identity, credentials, and signing).'
fi

echo
echo "=== dotfiles linked ==="

# Fisher rewrites its plugin list, so detach legacy repo links before running it.
if [[ -L "$HOME/.config/fish/fish_plugins" ]]; then
    current_plugins="$(mktemp)"
    cat "$HOME/.config/fish/fish_plugins" > "$current_plugins"
    rm "$HOME/.config/fish/fish_plugins"
    cp "$current_plugins" "$HOME/.config/fish/fish_plugins"
    rm "$current_plugins"
fi

# Install Fisher if missing, then sync the declarative plugin list
if command -v fish >/dev/null 2>&1; then
    if ! fish -c 'functions -q fisher' 2>/dev/null; then
        echo "Installing Fisher..."
        fish -c 'curl -fsSL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher' </dev/null
    fi
    # Fisher tracks installed plugins separately from the declarative file.
    if fish -c 'fisher list' | grep -q '^acomagu/fish-async-prompt$'; then
        fish -c 'fisher remove acomagu/fish-async-prompt' </dev/null
    fi
    # Fisher rewrites fish_plugins; never let it write through a repo symlink.
    manifest="$HOME/.config/fish/fish_plugins"
    cp "$DOTFILES_DIR/fish/fish_plugins" "$manifest"
    echo "Syncing Fisher plugins..."
    fish -c 'fisher update' </dev/null
fi

# Install TPM if missing
if [[ "$USE_TMUX" == 1 && ! -d ~/.tmux/plugins/tpm ]]; then
    echo "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

if [[ "$USE_TMUX" == 1 ]]; then
    TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins/" "$HOME/.tmux/plugins/tpm/bin/install_plugins"
fi

"$DOTFILES_DIR/scripts/check-install.sh"
