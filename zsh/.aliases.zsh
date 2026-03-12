# Source canonical aliases (resolves through symlink to dotfiles repo)
DOTFILES_DIR="$(cd "$(dirname "$(readlink -f "${(%):-%x}")")/.." && pwd)"
source "${DOTFILES_DIR}/shell/aliases.sh"
