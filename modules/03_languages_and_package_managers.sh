#!/bin/bash
# --- MODULE 03: Languages (Go, Node via FNM, Python via uv) ---

set -Eeuo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$BASE_DIR/lib/utils.sh"

section "Development Languages"
echo -e "${CYAN}Installing modern language toolchains...${RESET}"

# 1. Golang (Official Fedora Repo)
run_step "Install Go" "sudo dnf install -y golang"

# 2. FNM (Fast Node Manager — Rust-based, replaces nvm)
if command -v fnm &> /dev/null; then
    echo -e "${GREEN}FNM is already installed.${RESET}"
else
    run_step "Install FNM (Node.js version manager)" "curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell"
    echo -e "${YELLOW}Note: FNM installed to \$HOME/.local/share/fnm. Shell init configured in module 06.${RESET}"
fi

# 3. uv (Astral's ultra-fast Python manager — replaces pip, venv, and conda)
if command -v uv &> /dev/null; then
    echo -e "${GREEN}uv is already installed.${RESET}"
else
    run_step "Install uv (Python manager)" "curl -LsSf https://astral.sh/uv/install.sh | sh"
    echo -e "${YELLOW}Note: uv installed. Use 'uv python install 3.x' to install Python versions.${RESET}"
fi
