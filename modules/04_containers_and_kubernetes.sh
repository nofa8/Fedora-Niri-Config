#!/bin/bash
# --- MODULE 04: Containers (Podman) & Kubernetes ---

set -Eeuo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$BASE_DIR/lib/utils.sh"

section "Cloud Native Tools"
echo -e "${CYAN}Installing container and orchestration tooling...${RESET}"

# Podman — daemonless, rootless OCI containers (native to Fedora)
run_step "Install Podman Suite" "sudo dnf install -y podman podman-compose"

# Kubernetes CLI tools
run_step "Install kubectl" "sudo dnf install -y kubernetes-client"
run_step "Install k9s (Terminal K8s UI)" "sudo dnf install -y k9s"
run_step "Install Helm (K8s package manager)" "sudo dnf install -y helm"

# kind — Kubernetes-in-Podman for local development clusters
if command -v kind &> /dev/null; then
    echo -e "${GREEN}kind is already installed.${RESET}"
else
    run_step "Install kind (K8s in Podman)" \
        "curl -Lo /tmp/kind https://kind.sigs.k8s.io/dl/v0.27.0/kind-linux-amd64 && chmod +x /tmp/kind && sudo mv /tmp/kind /usr/local/bin/kind"
fi
