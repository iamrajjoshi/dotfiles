# Homebrew (macOS only)
if [[ "$(uname)" == "Darwin" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Oh-My-Zsh
export ZSH="${HOME}/.oh-my-zsh"
ZSH_THEME=""
plugins=(git direnv zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# Editor
export EDITOR="zed --wait"

# Aliases
source ~/.aliases.zsh

# Starship prompt
eval "$(starship init zsh)"

# Local overrides (work-specific, machine-specific)
[[ -f ~/.zshrc_local ]] && source ~/.zshrc_local
