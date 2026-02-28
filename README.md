<p align="center">
  <img src="https://img.shields.io/badge/Fedora-43-51A2DA?style=for-the-badge&logo=fedora&logoColor=white"/>
  <img src="https://img.shields.io/badge/Wayland-Niri-4B8BBE?style=for-the-badge&logo=wayland&logoColor=white"/>
  <img src="https://img.shields.io/badge/Shell-Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white"/>
</p>

<h1 align="center">🚀 Niri + Dank Material Shell</h1>
<h3 align="center">A modular provisioning framework for Fedora 43</h3>

<p align="center">
  Turn a fresh Fedora installation into a professional-grade development workstation<br/>
  with a modern tiling Wayland compositor and Material Design shell — in one command.
</p>

---

## What This Does

This project automates the full setup of a **Niri** (scrollable tiling Wayland compositor) + **Dank Material Shell** (Material You desktop experience) environment, along with a curated, opinionated developer toolchain.

Running `./setup.sh` will take a stock Fedora 43 system and install:

- 🖥️ A complete **Wayland desktop** (Niri + DMS + Ghostty terminal)
- 🦀 The **Rust toolchain** with IDE components
- 🐍 **Python** (via uv), **Node.js** (via FNM), and **Go**
- 🐳 **Podman** containers + full **Kubernetes** dev stack
- ⚡ 14 **modern CLI tools** replacing traditional Unix utilities
- 🐚 **Zsh** + OhMyZsh + **Starship** prompt with full tool integration

---

## Project Structure

```
Niri+DMS/
├── setup.sh                                 ← Entry point (orchestrator)
├── lib/
│   └── utils.sh                             ← Shared colors, run_step, headers
└── modules/
    ├── 01_niri_dms.sh                       ← Compositor & desktop
    ├── 02_rust.sh                           ← Rust + dev components
    ├── 03_languages_and_package_managers.sh  ← Go, FNM, uv
    ├── 04_containers_and_kubernetes.sh       ← Podman, kubectl, kind, k9s, helm
    ├── 05_modern_cli_utils.sh               ← CLI power tools
    └── 06_shell_and_prompt.sh               ← Zsh, OhMyZsh, Starship, .zshrc
```

---

## Quick Start

```bash
# Clone the repo
git clone <to-be-determined-repo-url> && cd Niri+DMS

# Run the full setup
./setup.sh
```

That's it. The orchestrator will:

1. Run pre-flight checks (root guard, Fedora detection, internet, sudo)
2. Show you the installation plan and ask for confirmation
3. Execute each module sequentially with progress indicators
4. Print a summary report with pass/fail status and timing

---

## Usage

```bash
./setup.sh                 # Interactive full install
./setup.sh --yes           # Skip confirmation (for automation)
./setup.sh --dry-run       # Print all commands without executing
./setup.sh --only 3        # Run only module 3 (Languages)
./setup.sh --help          # Show usage and module list
```

### Flags

| Flag           | Description                                           |
| -------------- | ----------------------------------------------------- |
| `--yes`, `-y`  | Skip the confirmation prompt                          |
| `--only N`     | Run only module N (1–6)                               |
| `--dry-run`    | Real dry-run — prints every command without executing |
| `--help`, `-h` | Show usage info and module list                       |

---

## Modules

### Module 01 — Niri + DMS (Compositor & Desktop)

Installs the core Wayland desktop stack:

| Package                    | Purpose                                                              |
| -------------------------- | -------------------------------------------------------------------- |
| **Niri**                   | Scrollable tiling Wayland compositor                                 |
| **xwayland-satellite**     | X11 compatibility layer for legacy apps                              |
| **Dank Material Shell**    | Material You shell with notifications, lock screen, and app launcher |
| **Ghostty**                | GPU-accelerated terminal emulator                                    |
| **wl-clipboard**           | Wayland clipboard support                                            |
| **pavucontrol**            | Audio volume control (PipeWire compatible)                           |
| **blueman**                | Bluetooth manager                                                    |
| **Roboto / FontAwesome**   | Typography for Material Design                                       |
| **matugen**                | Material You color generation                                        |
| **xdg-desktop-portal-gtk** | File dialogs for Firefox, Flatpak, etc.                              |
| **Qt5/Qt6 Wayland**        | Native Wayland rendering for Qt apps                                 |

### Module 02 — Rust Toolchain

Installs Rust via the official `rustup` installer, plus essential development components:

- `rust-analyzer` — LSP server for IDE integration
- `clippy` — Linter for idiomatic Rust
- `rustfmt` — Automatic code formatter

### Module 03 — Languages & Package Managers

| Tool    | What It Manages               | Why                                     |
| ------- | ----------------------------- | --------------------------------------- |
| **Go**  | Go programs                   | Installed via Fedora repos              |
| **FNM** | Node.js versions              | Fast, Rust-based `nvm` replacement      |
| **uv**  | Python versions + virtualenvs | 10–100x faster than pip, replaces conda |

### Module 04 — Containers & Kubernetes

| Tool                            | Purpose                             |
| ------------------------------- | ----------------------------------- |
| **Podman** + **podman-compose** | Daemonless, rootless OCI containers |
| **kubectl**                     | Kubernetes CLI                      |
| **kind**                        | Local K8s clusters inside Podman    |
| **k9s**                         | Terminal UI for Kubernetes          |
| **helm**                        | Kubernetes package manager          |

### Module 05 — Modern CLI Utilities

14 curated replacements for traditional Unix tools:

| Tool        | Replaces     | Description                                  |
| ----------- | ------------ | -------------------------------------------- |
| `fzf`       | —            | Fuzzy finder for everything                  |
| `ripgrep`   | `grep`       | 10x faster, respects `.gitignore`            |
| `eza`       | `ls`         | Icons, Git integration, tree view            |
| `bat`       | `cat`        | Syntax highlighting, line numbers            |
| `zoxide`    | `cd`         | Learns your most-used directories            |
| `fd-find`   | `find`       | Simpler syntax, faster                       |
| `tealdeer`  | `man`        | Concise, practical command examples          |
| `jq`        | —            | JSON processor                               |
| `btop`      | `top`/`htop` | Beautiful resource monitor                   |
| `lazygit`   | `git`        | Terminal Git UI                              |
| `stow`      | —            | Dotfile symlink manager                      |
| `xh`        | `curl`       | Colorized HTTP client                        |
| `git-delta` | `diff`       | Beautiful Git diffs with syntax highlighting |
| `dust`      | `du`         | Modern disk usage analyzer                   |

### Module 06 — Zsh, OhMyZsh & Starship

Sets up the interactive shell experience:

- **Zsh** as the default shell
- **OhMyZsh** framework with plugins:
  - `zsh-autosuggestions` — suggests commands from history as you type
  - `zsh-syntax-highlighting` — colors valid/invalid commands in real-time
- **Starship** prompt — shows Git status, Python venv, K8s context, Rust version, command duration, and more
- Configures `.zshrc` with all tool init lines and aliases:
  - `ls` → `eza --icons`
  - `cat` → `bat`
  - `docker` → `podman`
  - `k` → `kubectl`
  - `kind` → uses Podman provider automatically

---

## Safety & Resilience

This isn't a fragile dotfiles script — it's built as a **provisioning framework** with production-grade reliability:

| Feature                 | What It Does                                                                   |
| ----------------------- | ------------------------------------------------------------------------------ |
| `set -Eeuo pipefail`    | Strict error handling in every file — no silent failures                       |
| **Idempotent modules**  | Safe to re-run — checks for existing installs before acting                    |
| **Sudo keep-alive**     | Asks for password once, keeps it cached for the entire run                     |
| **Real dry-run**        | `--dry-run` prints every command at the `run_step` level                       |
| **Per-module timing**   | Tracks how long each module takes                                              |
| **Logging**             | All output saved to `~/.local/share/setup/logs/`                               |
| **`.zshrc` protection** | Uses a marker comment to prevent duplicate entries on re-run                   |
| **OS detection**        | Warns if not on Fedora 43+ or if internet is unavailable                       |
| **Graceful failure**    | If a module fails, the rest still run and a summary report shows what happened |

---

## Logs

Every run is logged to:

```
~/.local/share/setup/logs/setup-YYYYMMDD-HHMMSS.log
```

If something fails, the log captures the full output. Re-run just the failed module with:

```bash
./setup.sh --only N
```

---

## After Installation

1. **Log out and back in** — for Zsh to become your default shell
2. **Select Niri** at the login screen as your session
3. **Open Ghostty** — your terminal is ready with Starship, all tools, and aliases

### First-time commands

```bash
# Install a Node.js LTS version
fnm install --lts

# Install Python 3.12
uv python install 3.12

# Start a PyTorch project with CUDA
uv init my-ml-project && cd my-ml-project
uv add torch --index-url https://download.pytorch.org/whl/cu124

# Create a local Kubernetes cluster
kind create cluster

# Install Java (if ever needed)
# Just install SDKMAN: curl -s "https://get.sdkman.io" | bash
# Then: sdk install java
```

---

## Requirements

- **Fedora 43** (Workstation or Server with GNOME removed)
- **Internet connection** (all modules download packages)
- **Non-root user with sudo access**

---

## License

MIT
