# Homebrew's resolved path is generated per machine by the installer.
if test -f "$HOME/.config/dotfiles/homebrew.fish"
    source "$HOME/.config/dotfiles/homebrew.fish"
else if command -q brew
    brew shellenv fish | source
end

# User-installed CLIs take precedence over package-manager tools.
fish_add_path --global "$HOME/.local/bin" "$HOME/.bun/bin"

set fish_greeting ""

if status is-interactive
    source "$HOME/.config/fish/alias.fish"
    source "$HOME/.config/fish/colors.fish"

    # Project Node versions (.nvmrc / .node-version), shared with Zsh.
    if command -q fnm
        fnm env --use-on-cd --shell fish | source
    end

    if command -q starship
        starship init fish | source
    end

    # Work-specific and machine-specific overrides remain outside this repo.
    if test -f "$HOME/.config/fish/local.fish"
        source "$HOME/.config/fish/local.fish"
    end
end
