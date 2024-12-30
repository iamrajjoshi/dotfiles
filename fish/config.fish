source ~/.config/fish/alias.fish

# Disable the fish greeting message
set fish_greeting ""

# Set up brew
eval "$(/opt/homebrew/bin/brew shellenv)"


# Starship prompt
starship init fish | source
