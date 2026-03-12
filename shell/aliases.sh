# Canonical alias definitions (zsh/bash compatible)
# Sourced by both dotfiles/zsh/.aliases.zsh and directly

# Better ls
alias ls=lsd

# Git aliases
alias ga='git add .'
alias gb='git branch'
alias gp='git pull'
alias gca='git commit --amend'
alias gcm='git commit -m'
alias gco='git checkout'
alias gcoo='git branch | fzf | xargs git checkout'
alias gmb='git checkout -b'
alias gs='git status'
alias gucm='git reset --soft HEAD^'
alias paid='git push'
alias gpu='git push'
alias gdb='git branch -D $(git branch | fzf --multi)'
alias gl='git checkout -'
alias glist='git branch | fzf --height 40% --reverse | xargs git checkout'

alias gmas='_mas_helper "$@"'

_mas_helper() {
    if git rev-parse --verify --quiet master > /dev/null; then
        git checkout master "$@"
    elif git rev-parse --verify --quiet main > /dev/null; then
        git checkout main "$@"
    elif [ "$#" -eq 0 ]; then
        echo "Neither master nor main branch exists"
    else
        git checkout "$@"
    fi
}

# Emoji commit aliases
alias gcm-feat='f(){ git commit -m ":sparkles: feat: $*"; unset -f f; }; f'
alias gcm-fix='f(){ git commit -m ":bug: fix: $*"; unset -f f; }; f'
alias gcm-docs='f(){ git commit -m ":books: docs: $*"; unset -f f; }; f'
alias gcm-ref='f(){ git commit -m ":recycle: ref: $*"; unset -f f; }; f'
alias gcm-chore='f(){ git commit -m ":wrench: chore: $*"; unset -f f; }; f'
alias gcm-nit='f(){ git commit -m ":mag: nit: $*"; unset -f f; }; f'
alias gcm-test='f(){ git commit -m ":test_tube: test: $*"; unset -f f; }; f'
alias gcm-perf='f(){ git commit -m ":zap: perf: $*"; unset -f f; }; f'
alias gcm-style='f(){ git commit -m ":art: style: $*"; unset -f f; }; f'

# Pytest aliases
pt() {
    if [ $# -eq 0 ]; then
        echo "Usage: pt <file_path>"
    else
        pytest "$@"
    fi
}

ptk() {
    if [ $# -lt 2 ]; then
        echo "Usage: ptk <file_path> <test_name>"
    else
        local file_path="$1"
        shift
        pytest -vs -k "$*" "$file_path"
    fi
}

ptlf() {
    if [ $# -eq 0 ]; then
        echo "Usage: ptlf <file_path>"
    else
        pytest -vs --lf "$@"
    fi
}

# Tmux aliases
alias tls='tmux ls'
alias ta='tmux attach -d -t'

# Enable regexp highlighter for zsh-syntax-highlighting
if [ -n "$ZSH_VERSION" ]; then
    ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets regexp)
    ZSH_HIGHLIGHT_REGEXP+=('gcm-(feat|fix|docs|ref|chore|nit|test|perf|style)' 'fg=green,bold')
fi

# Help
alias_help() {
    NORMAL='\033[0;39m'
    GREEN='\033[0;32m'
    echo "Git aliases:
$GREEN gcm-feat$NORMAL  — :sparkles: Feat
$GREEN gcm-fix$NORMAL   — :bug: Fix
$GREEN gcm-docs$NORMAL  — :books: Docs
$GREEN gcm-ref$NORMAL   — :recycle: Ref
$GREEN gcm-chore$NORMAL — :wrench: Chore
$GREEN gcm-nit$NORMAL   — :mag: Nit
$GREEN gcm-test$NORMAL  — :test_tube: Test
$GREEN gcm-perf$NORMAL  — :zap: Perf
$GREEN gcm-style$NORMAL — :art: Style

Pytest aliases:
$GREEN pt$NORMAL    — Run pytest on a specific file (e.g., pt test_file.py)
$GREEN ptk$NORMAL   — Run a specific test in a file (e.g., ptk test_file.py test_name)
$GREEN ptlf$NORMAL  — Run last failed tests for a specific file (e.g., ptlf test_file.py)"
}

# Edit shortcuts
alias zshconfig="vim ~/.zshrc"
alias gitconfig="vim ~/.gitconfig"
alias aliases="vim ~/.aliases.zsh"
