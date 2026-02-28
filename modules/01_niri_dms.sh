#!/bin/bash
# --- MODULE 01: Niri + DMS ---

set -Eeuo pipefail

# Source the utilities so we can use run_step and colors
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$BASE_DIR/lib/utils.sh"

run_step "Enable COPR repo: avengemedia/dms" "sudo dnf copr enable -y avengemedia/dms"
run_step "Enable COPR repo: scottames/ghostty" "sudo dnf copr enable -y scottames/ghostty"

run_step "System update (dnf update -y)" "sudo dnf update -y"

run_step "Install core compositor packages (niri, xwayland-satellite)" "sudo dnf install -y niri xwayland-satellite"

run_step "Install Dank Material Shell (DMS)" "sudo dnf install -y dms"

run_step "Install Ghostty terminal and support tools" "sudo dnf install -y ghostty wl-clipboard pavucontrol blueman google-roboto-fonts google-roboto-condensed-fonts fontawesome-fonts matugen xdg-desktop-portal-gtk qt5-qtwayland qt6-qtwayland"

run_step "Initialize DMS Configs" "dms setup"