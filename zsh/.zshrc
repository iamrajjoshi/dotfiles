# Homebrew (macOS only)
if [[ "$(uname)" == "Darwin" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv zsh)"
fi

# User-installed command-line tools, including Claude Code
typeset -U path
path=("$HOME/.local/bin" $path)

# Oh-My-Zsh
export ZSH="${HOME}/.oh-my-zsh"
ZSH_THEME=""
plugins=(git direnv zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# Editor
export EDITOR="code --wait"

# Claude Code
export CLAUDE_CODE_NO_FLICKER=1

# Aliases
source ~/.aliases.zsh

# Starship prompt
eval "$(starship init zsh)"

# Local overrides (work-specific, machine-specific)
[[ -f ~/.zshrc_local ]] && source ~/.zshrc_local

# Project Node versions (.nvmrc / .node-version), shared with Fish.
if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --use-on-cd --shell zsh)"
fi
