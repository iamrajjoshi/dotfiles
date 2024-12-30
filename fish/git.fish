# Git abbreviations
abbr -a ga 'git add .'
abbr -a gp 'git pull'
abbr -a gca 'git commit --amend'
abbr -a gcm 'git commit -m'
abbr -a gco 'git checkout'
abbr -a gcoo 'git branch | fzf | xargs git checkout'
abbr -a gmb 'git checkout -b'
abbr -a gs 'git status'
abbr -a gucm 'git reset --soft HEAD^'
abbr -a paid 'git push'
abbr -a gpu 'git push'
abbr -a gdb 'git branch -D (git branch | fzf --multi)'
abbr -a gl 'git checkout -'
abbr -a glist 'git branch | fzf --height 40% --reverse | xargs git checkout'

# Git checkout master/main function
function gmas
    if git rev-parse --verify --quiet master >/dev/null
        git checkout master $argv
    else if git rev-parse --verify --quiet main >/dev/null
        git checkout main $argv
    else if test (count $argv) -eq 0
        echo "Neither master nor main branch exists"
    else
        git checkout $argv
    end
end

# Git commit functions
function gcm-feat
    git commit -m ":sparkles: feat: $argv"
end

function gcm-fix
    git commit -m ":bug: fix: $argv"
end

function gcm-docs
    git commit -m ":books: docs: $argv"
end

function gcm-ref
    git commit -m ":recycle: ref: $argv"
end

function gcm-chore
    git commit -m ":wrench: chore: $argv"
end

function gcm-nit
    git commit -m ":mag: nit: $argv"
end

function gcm-test
    git commit -m ":test_tube: test: $argv"
end

# Pytest functions
function pt
    if test (count $argv) -eq 0
        echo "Usage: pt <file_path>"
    else
        pytest $argv
    end
end

function ptk
    if test (count $argv) -lt 2
        echo "Usage: ptk <file_path> <test_name>"
    else
        set -l file_path $argv[1]
        set -e argv[1]
        pytest -vs -k "$argv" $file_path
    end
end

function ptlf
    if test (count $argv) -eq 0
        echo "Usage: ptlf <file_path>"
    else
        pytest -vs --lf $argv
    end
end
