# Hardened Python (`uv`) Dev Container Template

## 1. Purpose
Modern software supply-chain attacks often target developer machines through compromised packages (`pip`, `uv`, etc.) that execute malicious install scripts with full access to your host system. 

This template provides an isolated, reproducible Python development environment using Docker and VS Code Dev Containers. It minimizes the blast radius of malicious dependencies by keeping your host filesystem, SSH keys, and cloud credentials completely hidden from the development container.

---

## 2. What Has Been Done (Security & Architecture)
This repository pre-configures four key files (`Dockerfile`, `compose.yaml`, `.devcontainer/devcontainer.json`, and `.gitignore`) with the following defenses and tooling:

* **Non-Root Container User (`Dockerfile`):** Runs all processes as an unprivileged `dev` user (`UID 1000`) rather than `root`.
* **Isolated Virtual Environment (`Dockerfile`):** Installs `uv` and places the Python virtual environment at `/home/dev/.venv` (outside the mounted `/workspace`) so container binaries stay isolated and never clash with host OS files.
* **Strict Filesystem Boundaries (`compose.yaml`):** Mounts **only** the current project directory into `/workspace`—blocking access to your host home directory (`~`), `~/.ssh`, `~/.aws`, and browser sessions.
* **Persistent Package Cache (`compose.yaml`):** Uses a dedicated Docker named volume (`uv-cache`) so `uv` caches wheels across container rebuilds without exposing your host filesystem.
* **Dropped Linux Capabilities (`compose.yaml`):** Strips all unnecessary kernel capabilities (`cap_drop: ALL`) and sets `no-new-privileges:true` to prevent privilege escalation inside the container.
* **Disabled Credential Forwarding (`devcontainer.json`):** Explicitly clears `SSH_AUTH_SOCK` so VS Code does not automatically forward your host SSH agent into the container.
* **Pre-Configured IDE Tooling (`devcontainer.json`):** Automatically installs the official Python and Ruff extensions inside the container, sets format-on-save, and runs `uv init` automatically on first creation.
* **Secret Hygiene (`.gitignore`):** Ignores `.env` files, private keys, virtual environments, and Python caches out of the box while keeping `uv.lock` tracked for deterministic builds.

---

## 3. How to Use It

### Prerequisites
* **Docker** installed and running (e.g., Docker Desktop, OrbStack, or Docker Engine).
* **VS Code** (or Cursor) with the **Dev Containers** extension (`ms-vscode-remote.remote-containers`) installed.

### Step 1: Create a New Project from This Template
Click **"Use this template"** -> **"Create a new repository"** on GitHub (or use the GitHub CLI):
```bash
gh repo create my-new-project --template YOUR_USERNAME/YOUR_TEMPLATE_REPO --private --clone
cd my-new-project
```

### Step 2: Launch in VS Code
1. Open the cloned project folder in VS Code:
   ```bash
   code .
   ```
2. Open the Command Palette (`Cmd+Shift+P` on macOS or `Ctrl+Shift+P` on Windows/Linux) and select:
   > **Dev Containers: Reopen in Container**
3. Wait for the container image to build. Once ready, `uv init` will automatically initialize `pyproject.toml` if it does not already exist.

### Step 3: Daily Development Workflow
* **Install packages & run code (Inside Container Terminal):**
  ```bash
  uv add requests 
  uv add --dev pytest ruff
  uv run pytest
  ```
* **Git operations (On Host Machine Terminal):**
  Because host SSH keys and the SSH agent are intentionally blocked from the container, run `git commit`, `git push`, and `git pull` from a terminal on your host machine rather than inside VS Code's container terminal.
* **Rebuilding after config changes:**
  If you modify `Dockerfile` or `compose.yaml`, open the VS Code Command Palette and run **Dev Containers: Rebuild Container**.
