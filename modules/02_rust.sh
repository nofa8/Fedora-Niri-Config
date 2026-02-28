#!/bin/bash
# --- MODULE 02: Rust Toolchain ---

set -Eeuo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$BASE_DIR/lib/utils.sh"

section "Rust Toolchain Installation"
echo -e "${CYAN}Installing Rust via official rustup script...${RESET}"

# Check if Rust is already installed
if command -v rustc &> /dev/null; then
    echo -e "${GREEN}Rust is already installed. Updating...${RESET}"
    run_step "Update Rust" "rustup update"
else
    # Install silently using the -y flag so it doesn't pause for user input
    run_step "Install Rust Toolchain" "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"

    # Source cargo environment so subsequent modules can use Rust tools
    if [ -f "$HOME/.cargo/env" ]; then
        source "$HOME/.cargo/env"
    elif [ -d "$HOME/.cargo/bin" ]; then
        export PATH="$HOME/.cargo/bin:$PATH"
    fi
    echo -e "${YELLOW}Note: Rust has been installed to \$HOME/.cargo${RESET}"
fi

# Install essential development components
section "Rust Development Components"
echo -e "${CYAN}Installing rust-analyzer, clippy, and rustfmt...${RESET}"
run_step "Install Rust Components" "rustup component add rust-analyzer clippy rustfmt"