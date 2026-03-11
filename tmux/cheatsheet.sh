#!/usr/bin/env bash
# Tmux cheatsheet popup — called by: bind ? display-popup -E ...

# Dracula palette
BLUE='\033[38;2;73;186;255m'
MAGENTA='\033[38;2;252;76;180m'
CYAN='\033[38;2;139;233;253m'
GRAY='\033[38;2;85;85;85m'
FG='\033[38;2;235;236;230m'
DIM='\033[2m'
BOLD='\033[1m'
R='\033[0m'

printf "\n"
printf "${MAGENTA}${BOLD}              TMUX CHEATSHEET${R}\n"
printf "${GRAY}             ─────────────────${R}\n"
printf "\n"
printf "  ${BLUE}${BOLD}BASICS${R}\n"
printf "  ${CYAN}Ctrl+A${R}${FG}               Prefix key${R}\n"
printf "  ${CYAN}prefix + r${R}${FG}           Reload config${R}\n"
printf "  ${CYAN}prefix + ?${R}${FG}           This cheatsheet${R}\n"
printf "\n"
printf "  ${BLUE}${BOLD}WINDOWS${R}\n"
printf "  ${CYAN}prefix + c${R}${FG}           New window (same dir)${R}\n"
printf "  ${CYAN}prefix + n / p${R}${FG}       Next / previous window${R}\n"
printf "  ${CYAN}prefix + 1-9${R}${FG}         Jump to window #${R}\n"
printf "  ${CYAN}prefix + ,${R}${FG}           Rename window${R}\n"
printf "  ${CYAN}prefix + X${R}${FG}           Kill window${R}\n"
printf "\n"
printf "  ${BLUE}${BOLD}PANES${R}\n"
printf "  ${CYAN}prefix + \\\\${R}${FG}           Split vertical${R}\n"
printf "  ${CYAN}prefix + -${R}${FG}           Split horizontal${R}\n"
printf "  ${CYAN}prefix + arrows${R}${FG}      Navigate panes${R}\n"
printf "  ${CYAN}prefix + Shift+arrow${R}${FG} Resize (5 cells)${R}\n"
printf "  ${CYAN}prefix + x${R}${FG}           Kill pane${R}\n"
printf "  ${CYAN}prefix + q${R}${FG}           Show pane numbers${R}\n"
printf "  ${CYAN}prefix + z${R}${FG}           Toggle zoom${R}\n"
printf "\n"
printf "  ${BLUE}${BOLD}SESSIONS & WORKTREES${R}\n"
printf "  ${CYAN}prefix + w${R}${FG}           Worktree switcher${R}\n"
printf "  ${CYAN}prefix + s${R}${FG}           Session list${R}\n"
printf "  ${CYAN}prefix + d${R}${FG}           Detach${R}\n"
printf "\n"
printf "  ${BLUE}${BOLD}WORKTREE SWITCHER${R}\n"
printf "  ${CYAN}Enter${R}${FG}                Switch to worktree${R}\n"
printf "  ${CYAN}Ctrl+N${R}${FG}               Create worktree${R}\n"
printf "  ${CYAN}Alt+N${R}${FG}                Create (branch)${R}\n"
printf "  ${CYAN}Ctrl+D${R}${FG}               Delete worktree${R}\n"
printf "\n"
printf "${GRAY}${DIM}            press any key to close${R}\n"

read -rsn1
