#!/bin/bash
# --- MODULE 05: Modern CLI Utilities ---

set -Eeuo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$BASE_DIR/lib/utils.sh"

section "Modern CLI Replacements"
echo -e "${CYAN}Installing high-performance terminal utilities...${RESET}"

CLI_PACKAGES=(
    "fzf"           # Fuzzy finder
    "ripgrep"       # Faster grep (rg)
    "eza"           # Better ls — icons, git integration, tree view
    "bat"           # Better cat — syntax highlighting, line numbers
    "zoxide"        # Smarter cd — learns your most-used directories
    "fd-find"       # Faster find — simpler syntax, respects .gitignore
    "tealdeer"      # Fast tldr pages (concise man replacements)
    "jq"            # CLI JSON processor
    "btop"          # Beautiful resource monitor
    "lazygit"       # Terminal Git UI
    "stow"          # Dotfile symlink manager
    "xh"            # Fast, friendly HTTP client (curl alternative)
    "git-delta"     # Beautiful git diff viewer — syntax highlighting, side-by-side
    "dust"          # Modern disk usage analyzer (du replacement)
)

run_step "Install CLI Tools" "sudo dnf install -y ${CLI_PACKAGES[*]}"

# tealdeer needs a first-time cache download
run_step "Update tldr cache" "tldr --update || true"
