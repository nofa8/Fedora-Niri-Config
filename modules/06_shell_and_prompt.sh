#!/bin/bash
# --- MODULE 06: Zsh + OhMyZsh + Starship + Shell Config ---

set -Eeuo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$BASE_DIR/lib/utils.sh"

# ============================================================
# PART 1: Install Zsh
# ============================================================
section "Shell Environment — Zsh"
echo -e "${CYAN}Installing Zsh...${RESET}"
run_step "Install Zsh" "sudo dnf install -y zsh"

# ============================================================
# PART 2: OhMyZsh + Plugins
# ============================================================
section "OhMyZsh Framework"
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo -e "${GREEN}OhMyZsh is already installed.${RESET}"
else
    run_step "Install OhMyZsh" \
        "sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" \"\" --unattended"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# zsh-autosuggestions — suggests commands as you type (from history)
if [ -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]; then
    echo -e "${GREEN}zsh-autosuggestions already installed.${RESET}"
else
    run_step "Install zsh-autosuggestions" \
        "git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
fi

# zsh-syntax-highlighting — colors valid/invalid commands in real-time
if [ -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ]; then
    echo -e "${GREEN}zsh-syntax-highlighting already installed.${RESET}"
else
    run_step "Install zsh-syntax-highlighting" \
        "git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
fi

# ============================================================
# PART 3: Starship Prompt
# ============================================================
section "Starship Cross-Shell Prompt"
if command -v starship &> /dev/null; then
    echo -e "${GREEN}Starship is already installed.${RESET}"
else
    run_step "Install Starship" "curl -sS https://starship.rs/install.sh | sh -s -- -y"
fi

# ============================================================
# PART 4: Configure .zshrc
# ============================================================
section "Configuring .zshrc"

# Ensure .zshrc exists (OhMyZsh creates one, but guard against edge cases)
touch "$HOME/.zshrc"

# Backup existing .zshrc if it hasn't been backed up already
if [ ! -f "$HOME/.zshrc.backup" ]; then
    run_step "Backup existing .zshrc" "cp $HOME/.zshrc $HOME/.zshrc.backup"
fi

# Only append our config block if it hasn't been added before
MARKER="# --- Niri+DMS Tool Inits ---"
if ! grep -qF "$MARKER" "$HOME/.zshrc" 2>/dev/null; then
    echo -e "${CYAN}Appending tool initializations to .zshrc...${RESET}"
    cat << 'EOF' >> "$HOME/.zshrc"

# --- Niri+DMS Tool Inits ---

# Path
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$HOME/.local/share/fnm:$PATH"

# FNM (Node.js version manager)
eval "$(fnm env --use-on-cd)"

# Zoxide (smart cd)
eval "$(zoxide init zsh)"

# Starship prompt
eval "$(starship init zsh)"

# uv shell completions
eval "$(uv generate-shell-completion zsh)"

# Aliases
alias cat='bat'
alias docker='podman'
alias k='kubectl'
alias kind='KIND_EXPERIMENTAL_PROVIDER=podman kind'

# --- End Niri+DMS Tool Inits ---
EOF
    echo -e "${GREEN}✔ .zshrc configured.${RESET}"
else
    echo -e "${GREEN}Tool init block already present in .zshrc. Skipping.${RESET}"
fi

# Update OhMyZsh plugins list in .zshrc
# Replace the default plugins=(git) with our curated list
if grep -q '^plugins=(git)$' "$HOME/.zshrc" 2>/dev/null; then
    run_step "Update OhMyZsh plugins" \
        "sed -i 's/^plugins=(git)$/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' $HOME/.zshrc"
fi

# ============================================================
# PART 5: Set Zsh as default shell
# ============================================================
section "Setting Default Shell"
CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
if [ "$CURRENT_SHELL" = "$(which zsh)" ]; then
    echo -e "${GREEN}Zsh is already the default shell.${RESET}"
else
    echo -e "${YELLOW}Changing default shell to Zsh...${RESET}"
    run_step "Set Zsh as default shell" "sudo chsh -s \$(which zsh) $USER"
    echo -e "${YELLOW}Note: Log out and back in for the shell change to take effect.${RESET}"
fi
