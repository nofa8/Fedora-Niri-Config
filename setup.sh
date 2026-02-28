#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════
#  setup.sh — Orchestrator for Niri + Dank Material Shell Environment
# ═══════════════════════════════════════════════════════════════════════
#  Usage:
#    ./setup.sh              Run full setup interactively
#    ./setup.sh --yes        Skip confirmation prompt
#    ./setup.sh --only 3     Run only module 3
#    ./setup.sh --dry-run    Print commands without executing
#    ./setup.sh --help       Show usage
# ═══════════════════════════════════════════════════════════════════════

set -Eeuo pipefail

# ─── Resolve paths ────────────────────────────────────────────────────
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -f "$BASE_DIR/lib/utils.sh" ]]; then
    echo "ERROR: lib/utils.sh not found. Is the project structure intact?"
    echo "Expected at: $BASE_DIR/lib/utils.sh"
    exit 1
fi
source "$BASE_DIR/lib/utils.sh"

# ─── Module manifest ─────────────────────────────────────────────────
# Each entry: "filename|description"
MODULES=(
    "01_niri_dms.sh|Niri + DMS (Compositor & Desktop)"
    "02_rust.sh|Rust Toolchain"
    "03_languages_and_package_managers.sh|Go, Node (FNM) & Python (uv)"
    "04_containers_and_kubernetes.sh|Podman & Kubernetes"
    "05_modern_cli_utils.sh|Modern CLI Utilities"
    "06_shell_and_prompt.sh|Zsh, OhMyZsh & Starship"
)
TOTAL=${#MODULES[@]}

# ─── Parse arguments ─────────────────────────────────────────────────
AUTO_YES=false
ONLY_MODULE=""
export DRY_RUN="false"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --yes|-y)
            AUTO_YES=true
            shift
            ;;
        --only)
            if [[ -z "${2:-}" || ! "$2" =~ ^[0-9]+$ ]]; then
                echo -e "${RED}Error: --only requires a module number (1-${TOTAL})${RESET}"
                exit 1
            fi
            ONLY_MODULE="$2"
            if (( ONLY_MODULE < 1 || ONLY_MODULE > TOTAL )); then
                echo -e "${RED}Error: module number must be between 1 and ${TOTAL}${RESET}"
                exit 1
            fi
            shift 2
            ;;
        --dry-run)
            export DRY_RUN="true"
            shift
            ;;
        --help|-h)
            echo "Usage: ./setup.sh [OPTIONS]"
            echo
            echo "Options:"
            echo "  --yes, -y      Skip confirmation prompt"
            echo "  --only N       Run only module N (1-${TOTAL})"
            echo "  --dry-run      Print commands without executing"
            echo "  --help, -h     Show this help"
            echo
            echo "Modules:"
            for i in "${!MODULES[@]}"; do
                local_num=$((i + 1))
                local_desc="${MODULES[$i]#*|}"
                printf "  %d. %s\n" "$local_num" "$local_desc"
            done
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${RESET}"
            echo "Use --help for usage."
            exit 1
            ;;
    esac
done

# ─── Setup logging ───────────────────────────────────────────────────
LOG_DIR="$HOME/.local/share/setup/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/setup-$(date '+%Y%m%d-%H%M%S').log"

# Tee all output (stdout + stderr) to both terminal and log file
exec > >(tee -a "$LOG_FILE") 2>&1

echo -e "${DIM}Log: ${LOG_FILE}${RESET}"

# ─── Cleanup trap (flush tee, kill sudo keep-alive) ──────────────────
SUDO_KEEPALIVE_PID=""
cleanup() {
    # Kill sudo keep-alive if running
    if [[ -n "$SUDO_KEEPALIVE_PID" ]] && kill -0 "$SUDO_KEEPALIVE_PID" 2>/dev/null; then
        kill "$SUDO_KEEPALIVE_PID" 2>/dev/null
    fi
    # Give tee a moment to flush remaining output to the log file
    sleep 0.3
}
trap cleanup EXIT

# ═════════════════════════════════════════════════════════════════════
#  PHASE 1 — Pre-flight Checks
# ═════════════════════════════════════════════════════════════════════

banner

section "Pre-flight Checks"

# 1a. Root guard
if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}${BOLD}✖ Do not run this script as root.${RESET}"
    echo -e "${YELLOW}  Modules use 'sudo' internally where needed.${RESET}"
    echo -e "${YELLOW}  Running as root breaks per-user installs (Rust, FNM, uv, etc.)${RESET}"
    exit 1
fi
echo -e "${GREEN}✔ Not running as root${RESET}"

# 1b. Fedora detection
MIN_FEDORA_VERSION=43
if [[ -f /etc/os-release ]]; then
    # shellcheck source=/dev/null
    source /etc/os-release
    if [[ "${ID:-}" != "fedora" ]]; then
        echo -e "${YELLOW}⚠ Warning: This is designed for Fedora but detected: ${ID:-unknown}${RESET}"
        echo -e "${YELLOW}  Proceeding anyway, but some packages may not be available.${RESET}"
    else
        echo -e "${GREEN}✔ Fedora detected (${PRETTY_NAME:-Fedora})${RESET}"
        # Version check
        if [[ -n "${VERSION_ID:-}" ]] && (( VERSION_ID < MIN_FEDORA_VERSION )); then
            echo -e "${YELLOW}⚠ Warning: This was built for Fedora ${MIN_FEDORA_VERSION}+, you are on Fedora ${VERSION_ID}${RESET}"
            echo -e "${YELLOW}  Some packages or COPR repos may not be available for your version.${RESET}"
        fi
    fi
else
    echo -e "${YELLOW}⚠ Warning: Cannot detect OS (/etc/os-release not found)${RESET}"
fi

# 1c. Internet connectivity (uses fedoraproject.org — works behind restrictive firewalls)
echo -ne "${DIM}  Checking internet connectivity...${RESET}"
if curl -s --head --max-time 5 https://fedoraproject.org > /dev/null 2>&1; then
    echo -e "\r${GREEN}✔ Internet connectivity OK${RESET}              "
else
    echo -e "\r${RED}${BOLD}✖ No internet connection detected.${RESET}  "
    echo -e "${YELLOW}  Most modules require network access. Please connect and retry.${RESET}"
    exit 1
fi

# 1d. Sudo warmup — ask for password once, keep alive in background
if [[ "$DRY_RUN" != "true" ]]; then
    echo -e "${DIM}  Requesting sudo credentials (needed by modules)...${RESET}"
    if sudo -v 2>/dev/null; then
        echo -e "${GREEN}✔ Sudo credentials cached${RESET}"
        # Keep-alive: refresh sudo timestamp every 55s until this script exits
        ( while true; do sudo -n true 2>/dev/null; sleep 55; done ) &
        SUDO_KEEPALIVE_PID=$!
    else
        echo -e "${YELLOW}⚠ Could not cache sudo. Modules may prompt for password individually.${RESET}"
    fi
fi

# 1e. Dry-run notice
if [[ "$DRY_RUN" == "true" ]]; then
    echo
    echo -e "${YELLOW}${BOLD}════════════════════════════════════════════════════════════${RESET}"
    echo -e "${YELLOW}${BOLD}  DRY-RUN MODE — Commands will be printed, not executed${RESET}"
    echo -e "${YELLOW}${BOLD}════════════════════════════════════════════════════════════${RESET}"
fi

echo

# ═════════════════════════════════════════════════════════════════════
#  PHASE 2 — Module Manifest & Confirmation
# ═════════════════════════════════════════════════════════════════════

section "Installation Plan"

if [[ -n "$ONLY_MODULE" ]]; then
    idx=$((ONLY_MODULE - 1))
    desc="${MODULES[$idx]#*|}"
    echo -e "${WHITE}  Running single module:${RESET}"
    echo -e "  ${BOLD}${GREEN}[ ${ONLY_MODULE} ]${RESET}  ${desc}"
else
    echo -e "${WHITE}  The following modules will be installed in order:${RESET}"
    echo
    for i in "${!MODULES[@]}"; do
        num=$((i + 1))
        desc="${MODULES[$i]#*|}"
        echo -e "  ${BOLD}${GREEN}[ ${num} ]${RESET}  ${desc}"
    done
fi

echo
echo -e "${DIM}─────────────────────────────────────────────────────────────${RESET}"

if [[ "$AUTO_YES" != "true" && "$DRY_RUN" != "true" ]]; then
    echo -ne "${BOLD}${WHITE}  Press ENTER to begin installation (Ctrl+C to abort): ${RESET}"
    read -r
fi

echo

# ═════════════════════════════════════════════════════════════════════
#  PHASE 3 — Sequential Module Execution
# ═════════════════════════════════════════════════════════════════════

# Results tracking
declare -a RESULTS_STATUS
declare -a RESULTS_TIME
declare -a RESULTS_NAME
SETUP_START=$(date +%s)

# ─── Environment Refresh ─────────────────────────────────────────────
# Modules run as child processes (bash "$path") for isolation — a module
# calling `exit 1` won't kill this orchestrator, and variable collisions
# are impossible.
#
# The trade-off: child processes don't inherit PATH changes made by
# earlier modules. For example, if Module 02 installs Rust, Module 03
# won't see `cargo` unless we refresh the orchestrator's PATH.
#
# This function re-loads known tool environments into the orchestrator.
# Since child processes inherit exported variables, subsequent modules
# will see the updated PATH.
refresh_env() {
    # Rust / Cargo
    if [[ -f "$HOME/.cargo/env" ]]; then
        source "$HOME/.cargo/env"
    fi

    # Local binaries (uv, pip, etc.)
    if [[ -d "$HOME/.local/bin" && ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        export PATH="$HOME/.local/bin:$PATH"
    fi

    # FNM (Fast Node Manager) — needs eval for shim setup, not just PATH
    if command -v fnm >/dev/null 2>&1; then
        eval "$(fnm env --use-on-cd)"
    elif [[ -f "$HOME/.local/share/fnm/fnm" ]]; then
        export PATH="$HOME/.local/share/fnm:$PATH"
        eval "$("$HOME/.local/share/fnm/fnm" env --use-on-cd)"
    fi

    # Go
    if [[ -d "/usr/local/go/bin" && ":$PATH:" != *":/usr/local/go/bin:"* ]]; then
        export PATH="/usr/local/go/bin:$PATH"
    fi
    if [[ -d "$HOME/go/bin" && ":$PATH:" != *":$HOME/go/bin:"* ]]; then
        export PATH="$HOME/go/bin:$PATH"
    fi
}

run_module() {
    local idx="$1"
    local file="${MODULES[$idx]%%|*}"
    local desc="${MODULES[$idx]#*|}"
    local num=$((idx + 1))
    local module_path="$BASE_DIR/modules/$file"

    RESULTS_NAME+=("$desc")

    # Verify module exists
    if [[ ! -f "$module_path" ]]; then
        echo -e "${RED}${BOLD}✖ Module not found: ${module_path}${RESET}"
        RESULTS_STATUS+=("MISSING")
        RESULTS_TIME+=("—")
        return 1
    fi

    module_header "$num" "$TOTAL" "$desc"

    local start_time
    start_time=$(date +%s)

    # Run the module as an isolated child process
    # DRY_RUN is exported and inherited by the child's run_step in utils.sh
    if bash "$module_path"; then
        local end_time
        end_time=$(date +%s)
        local duration=$(( end_time - start_time ))
        local formatted
        formatted=$(elapsed_time "$duration")

        echo -e "${GREEN}${BOLD}✔ Module ${num} completed${RESET} ${DIM}(${formatted})${RESET}"
        RESULTS_STATUS+=("✔ PASS")
        RESULTS_TIME+=("$formatted")

        # Refresh the orchestrator's PATH so the next module sees
        # any tools this module just installed
        refresh_env
        return 0
    else
        local end_time
        end_time=$(date +%s)
        local duration=$(( end_time - start_time ))
        local formatted
        formatted=$(elapsed_time "$duration")

        echo -e "${RED}${BOLD}✖ Module ${num} failed${RESET} ${DIM}(${formatted})${RESET}"
        RESULTS_STATUS+=("✖ FAIL")
        RESULTS_TIME+=("$formatted")
        return 1
    fi
}

# Execute modules
FAILURE_COUNT=0

if [[ -n "$ONLY_MODULE" ]]; then
    # Single module mode
    idx=$((ONLY_MODULE - 1))
    if ! run_module "$idx"; then
        FAILURE_COUNT=$((FAILURE_COUNT + 1))
    fi
else
    # Full sequential execution
    for i in "${!MODULES[@]}"; do
        if ! run_module "$i"; then
            FAILURE_COUNT=$((FAILURE_COUNT + 1))
        fi
    done
fi

# ═════════════════════════════════════════════════════════════════════
#  PHASE 4 — Summary Report
# ═════════════════════════════════════════════════════════════════════

SETUP_END=$(date +%s)
TOTAL_DURATION=$(( SETUP_END - SETUP_START ))
TOTAL_FORMATTED=$(elapsed_time "$TOTAL_DURATION")

echo
echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${CYAN}║${RESET}  ${BOLD}${WHITE}Setup Summary${RESET}"
echo -e "${BOLD}${CYAN}╠════════════════════════════════════════════════════════════╣${RESET}"

for i in "${!RESULTS_NAME[@]}"; do
    local_status="${RESULTS_STATUS[$i]}"
    local_name="${RESULTS_NAME[$i]}"
    local_time="${RESULTS_TIME[$i]}"

    if [[ "$local_status" == "✔ PASS" ]]; then
        echo -e "${BOLD}${CYAN}║${RESET}  ${GREEN}${local_status}${RESET}  ${WHITE}${local_name}${RESET}  ${DIM}(${local_time})${RESET}"
    else
        echo -e "${BOLD}${CYAN}║${RESET}  ${RED}${local_status}${RESET}  ${WHITE}${local_name}${RESET}  ${DIM}(${local_time})${RESET}"
    fi
done

echo -e "${BOLD}${CYAN}╠════════════════════════════════════════════════════════════╣${RESET}"
echo -e "${BOLD}${CYAN}║${RESET}  ${DIM}Total time: ${TOTAL_FORMATTED}${RESET}"
echo -e "${BOLD}${CYAN}║${RESET}  ${DIM}Log file:   ${LOG_FILE}${RESET}"
echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════╝${RESET}"
echo

if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}${BOLD}This was a dry run. No changes were made to your system.${RESET}"
    echo -e "${YELLOW}Run without --dry-run to install for real.${RESET}"
elif [[ $FAILURE_COUNT -gt 0 ]]; then
    echo -e "${RED}${BOLD}⚠ ${FAILURE_COUNT} module(s) failed.${RESET}"
    echo -e "${YELLOW}  Check the log file for details: ${LOG_FILE}${RESET}"
    echo -e "${YELLOW}  Re-run a failed module with: ./setup.sh --only N${RESET}"
    exit 1
else
    echo -e "${GREEN}${BOLD}✔ All modules completed successfully!${RESET}"
    echo
    echo -e "${WHITE}${BOLD}Next steps:${RESET}"
    echo -e "${CYAN}  1.${RESET} Log out and back in for Zsh to take effect"
    echo -e "${CYAN}  2.${RESET} Select ${BOLD}Niri${RESET} as your session at the login screen"
    echo -e "${CYAN}  3.${RESET} Open ${BOLD}Ghostty${RESET} and enjoy your new environment 🚀"
    echo
fi
