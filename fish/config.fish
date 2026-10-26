source ~/.config/fish/alias.fish

# Disable the fish greeting message
set fish_greeting ""

# Set up brew
/opt/homebrew/bin/brew shellenv fish | source

# User-installed command-line tools, including Claude Code
fish_add_path --global "$HOME/.local/bin"

# Starship prompt
starship init fish | source

# Local overrides (work-specific, machine-specific)
if test -f ~/.config/fish/local.fish
    source ~/.config/fish/local.fish
end
