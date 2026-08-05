# dotfiles

Personal dev setup for macOS — fish + zsh + Starship.

## New Machine Setup

```bash
# 1. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Clone this repo
git clone git@github.com:iamrajjoshi/dotfiles.git ~/code/dotfiles

# 3. Install packages
cd ~/code/dotfiles
brew bundle install

# 4. Install Oh-My-Zsh + plugins
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# 5. Restore configs (shells, terminals, editors, and git)
./install.sh

# 6. (Optional) Add work overrides
# See: https://github.com/iamrajjoshi/work-dotfiles
```

After step 5, open a new terminal — Starship prompt, all aliases, and both shells should work.

## Structure

```
shell/aliases.sh      # Canonical aliases (zsh/bash compatible)
fish/                 # Fish shell configs
zsh/                  # Zsh configs (Starship, Oh-My-Zsh)
tmux/tmux.conf        # Tmux config
ghostty/config        # Ghostty terminal config
iterm2/               # Portable iTerm2 preferences and Raj profile
sublime/              # Sublime Text preferences and package manifest
zed/settings.json     # Zed editor settings
zed/keymap.json       # Zed key bindings
starship.toml         # Shared Starship prompt
.gitconfig            # Git config (includes ~/.gitconfig_local)
Brewfile              # Homebrew packages
install.sh            # Symlink installer
```

## Config Layering

Both shells support local overrides for work-specific config:

- **Zsh:** `~/.zshrc_local` sourced at end of `.zshrc`
- **Fish:** `~/.config/fish/local.fish` sourced at end of `config.fish`
- **Git:** `~/.gitconfig_local` included via `.gitconfig`

On a personal machine without local overrides, everything works standalone.

## Application Preferences

- **iTerm2:** `install.sh` configures iTerm2 to load the curated preferences in this repo. Restart iTerm2 after running it.
- **Sublime Text:** `install.sh` links the user preferences and Package Control manifest. On a new machine, choose **Tools → Install Package Control** once; Package Control will then restore JsPrettier.

## macOS Settings

### Dock animation speed

```bash
defaults write com.apple.dock autohide-time-modifier -float 0.15; killall Dock
```
