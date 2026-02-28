#!/bin/bash
# --- UTILITIES LIBRARY ---
# Contains shared variables and functions used across all modules.
# Sourced by both setup.sh and individual module scripts.

# Color helpers (fall back to safe values if not a TTY)
if [ -t 1 ]; then
    RED="\e[31m"
    GREEN="\e[32m"
    YELLOW="\e[33m"
    BLUE="\e[34m"
    MAGENTA="\e[35m"
    CYAN="\e[36m"
    WHITE="\e[97m"
    DIM="\e[2m"
    BOLD="\e[1m"
    RESET="\e[0m"
else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    MAGENTA=""
    CYAN=""
    WHITE=""
    DIM=""
    BOLD=""
    RESET=""
fi

# DRY_RUN is set by setup.sh --dry-run and exported to modules
DRY_RUN="${DRY_RUN:-false}"

# ─── Banner ───────────────────────────────────────────────────────────
banner() {
    echo
    echo -e "${MAGENTA}${BOLD}"
    cat <<'ASCII'
 _   _ ___ ___ _____   _  _____ __  __
| \ | |_ _/ __|_   _| / \|_   _|  \/  |
|  \| || |\\__ \ | |  / _ \ | | | |\/| |
| |\  || |___/ / | | / ___ \| | | |  | |
|_| \_|___|____| |_|/_/   \_\_| |_|  |_|
ASCII
    echo -e "${RESET}"
    echo -e "     ${CYAN}${BOLD}N I R I   +   D A N K   M A T E R I A L   S H E L L${RESET}"
    echo
    echo -e "${DIM}─────────────────────────────────────────────────────────────${RESET}"
    echo -e "${WHITE}  Modular Setup Environment — Fedora${RESET}"
    echo -e "${YELLOW}  This orchestrator will run isolated modules to prepare${RESET}"
    echo -e "${YELLOW}  your system as a professional development workstation.${RESET}"
    echo -e "${DIM}─────────────────────────────────────────────────────────────${RESET}"
    echo
}

# ─── Section Header (used within modules for individual steps) ────────
section() {
    local title="$1"
    echo -e "${MAGENTA}============================================================${RESET}"
    echo -e "${BOLD}${BLUE}>> ${title}${RESET}"
    echo -e "${MAGENTA}------------------------------------------------------------${RESET}"
}

# ─── Module Header (used by setup.sh for top-level module progress) ───
module_header() {
    local current="$1"
    local total="$2"
    local name="$3"
    echo
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║${RESET}  ${BOLD}${WHITE}[ ${current} / ${total} ]${RESET}  ${BOLD}${GREEN}${name}${RESET}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════╝${RESET}"
    echo
}

# ─── Run Step (core execution wrapper — handles dry-run) ──────────────
run_step() {
    local desc="$1"
    shift
    local cmd="$*"
    section "$desc"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}${BOLD}[DRY-RUN]${RESET} ${DIM}${cmd}${RESET}"
        echo -e "${GREEN}✔ Skipped (dry-run):${RESET} ${desc}"
        echo
        return 0
    fi

    echo -e "${YELLOW}→ Running:${RESET} ${cmd}"

    # Execute the command; allow it to fail and show error context
    if ! eval "$cmd"; then
        echo -e "${RED}${BOLD}✖ Step failed:${RESET} ${desc}"
        exit 1
    fi
    echo -e "${GREEN}✔ Completed:${RESET} ${desc}"
    echo
}

# ─── Elapsed Time Formatter ──────────────────────────────────────────
elapsed_time() {
    local seconds="$1"
    if (( seconds < 60 )); then
        echo "${seconds}s"
    else
        local mins=$(( seconds / 60 ))
        local secs=$(( seconds % 60 ))
        echo "${mins}m ${secs}s"
    fi
}