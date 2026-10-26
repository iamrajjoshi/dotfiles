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
DOTFILES_USE_TMUX=1 DOTFILES_USE_WILLOW=0 brew bundle install

# Install a default Node LTS for fnm (project files select other versions)
fnm install --lts

# 4. Install Oh-My-Zsh + plugins
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# 5. Restore configs (shells, terminals, editors, and git)
./install.sh --tmux --no-willow

# 6. (Optional) Add work overrides
# See: https://github.com/iamrajjoshi/work-dotfiles
```

After step 5, open a new terminal — Starship prompt, all aliases, and both shells should work.

## Node Versions

Fish and Zsh use `fnm` with automatic switching from `.nvmrc` or `.node-version`.
Install the default Node LTS after installing the Brewfile:

```bash
fnm install --lts
```

The first installed version becomes the default; use `fnm default <version>` to
change it. Install a project's required version with `fnm install` from that
project. Homebrew Node remains installed for packages such as Gloss; development
shells prefer the fnm-selected version. Old NVM installations can remain on disk,
but these shell configs do not load NVM.

## Terminal Features

Choose tmux and Willow independently during installation. Pass matching choices
to Homebrew when installing packages (`DOTFILES_USE_TMUX=1` or `0`,
`DOTFILES_USE_WILLOW=1` or `0`) and then to the installer:

```bash
DOTFILES_USE_TMUX=1 DOTFILES_USE_WILLOW=0 brew bundle install
```

Homebrew defaults to including tmux and excluding Willow. These environment
variables select packages; the setup flags below select terminal integration:

```bash
./install.sh --tmux --no-willow
```

A new machine defaults to tmux on and Willow off. Choices are saved in
`~/.config/dotfiles/features.conf`; rerunning setup without flags reuses them.
Explicit flags override saved choices. All combinations are supported:

```bash
./scripts/configure-features.sh --tmux --no-willow   # Current setup
./scripts/configure-features.sh --no-tmux --no-willow
./scripts/configure-features.sh --tmux --willow
./scripts/configure-features.sh --no-tmux --willow
```

The feature-only command updates Ghostty and tmux without touching shell, editor,
Git, Sublime, iTerm2, or other app preferences. It never installs packages, changes
your account's login shell, kills sessions, or enables agent hooks. Install tmux
before `--tmux`; install `iamrajjoshi/tap/willow` before `--willow`. Missing enabled
dependencies stop setup before writing any configuration. Willow controls its tmux
widget and picker only when tmux is also enabled; the Willow choice is still saved
when tmux is off. Agent hooks remain separate and are not enabled by this flag.

The shell is taken from your account's login shell on the first run and then saved.
Override it explicitly when needed:

```bash
./scripts/configure-features.sh --tmux --no-willow --shell /opt/homebrew/bin/fish
```

Shared Ghostty appearance lives in `ghostty/config`. The generated local config
adds tmux startup and tmux-specific keyboard shortcuts together only when tmux is
on. With tmux off, Ghostty launches the selected shell and uses its native tab and
pane shortcuts. The generated `~/.tmux.conf` loads the shared theme and selected
shell, with the optional `tmux/willow.conf` layer. Enabling/disabling tmux takes
effect in new Ghostty windows; existing sessions are left running. TPM is installed
by the full installer only when tmux is on.

Existing unmanaged configs and symlinks are preserved as `.before-features`
backups (numbered when necessary); rerunning with the same choices is idempotent.
Do not edit generated wrappers directly: change the shared source or rerun with
flags. To test flag behavior without touching your home or installing anything:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -p 'test_features.py'
```

## Structure

```
shell/aliases.sh      # Canonical aliases (zsh/bash compatible)
fish/                 # Fish shell configs
zsh/                  # Zsh configs (Starship, Oh-My-Zsh)
tmux/tmux.conf        # Shared tmux config (optional willow.conf layer)
ghostty/config        # Shared Ghostty appearance; tmux.conf contains tmux bindings
iterm2/               # Portable iTerm2 preferences and Default/Raj profiles
terminal/             # Clear Dark Terminal profile
rectangle/            # Rectangle shortcuts and related behavior
sublime/              # Sublime Text preferences and package manifest
zed/settings.json     # Zed editor settings
zed/keymap.json       # Zed key bindings
starship.toml         # Shared Starship prompt
.gitconfig            # Git config (includes ~/.gitconfig_local)
Brewfile              # Homebrew packages
install.sh            # Dotfiles installer with terminal feature flags
scripts/configure-features.sh # Terminal-only feature configuration
```

## Config Layering

Both shells support local overrides for work-specific config:

- **Zsh:** `~/.zshrc_local` sourced at end of `.zshrc`
- **Fish:** `~/.config/fish/local.fish` sourced at end of `config.fish`
- **Git:** `~/.gitconfig_local` included via `.gitconfig`

On a personal machine without local overrides, everything works standalone.

## Application Preferences

- **iTerm2:** legacy preferences remain in this repo for reference; setup does not apply them.
- **Terminal:** `install.sh` merges the Clear Dark profile into Terminal and selects it for startup and new windows.
- **Rectangle:** `install.sh` restores the saved shortcuts, including intentionally disabled half-screen shortcuts.
- **Sublime Text:** the app remains in the Brewfile. Setup leaves its preferences alone; the saved preferences and package manifest remain available for manual use.

Quit Terminal and Rectangle before running `install.sh`, then reopen them afterward.

## macOS Settings

### Dock animation speed

```bash
defaults write com.apple.dock autohide-time-modifier -float 0.15; killall Dock
```
