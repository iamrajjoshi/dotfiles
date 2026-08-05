# Source canonical aliases (the :A modifier resolves the installed symlink)
DOTFILES_DIR="${${(%):-%x}:A:h:h}"
source "${DOTFILES_DIR}/shell/aliases.sh"
unset DOTFILES_DIR
