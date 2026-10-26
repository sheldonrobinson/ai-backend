# AI Backend — Components & Architecture

This documentation summarizes the purpose of each component in the AI Backend, how they interact, and operational notes.

<!-- Diagram removed per request -->


## Components

- Llama.C++ HTTP Server
  - Role: Local inference engine serving text completions and streaming tokens over HTTP (example: localhost:9931).
  - Purpose: Fast on-device LLM inference using ggml backends; used for chat, completion, and streaming token responses.
  - Notes: Configurable via LLAMA_ARG_* environment variables.

- Bifrost (AI Gateway)
  - Role: HTTP gateway that exposes a consistent API to callers and routes LLM requests to llama-server (or other LLM providers).
  - Purpose: Centralizes LLM access, adds governance, routing, virtual keys, and MCP Gateway endpoints for Goose integration.
  - Notes: Configured via PUT /api/config with X-Bifrost-Setup-Token; default port 8080.

- Goose (Agent)
  - Role: Agentic orchestration application that runs skills and invokes external MCP servers and LLMs.
  - Purpose: Provides skill execution, deeplink installs for extensions, and coordinates agent workflows.
  - Notes: Runs as ACP server; configured with bifrost and llama-server providers; bifrost MCP Gateway at /mcp.

## Supporting Scripts & Installers

- Windows: install.ps1 installs packages and copies per-user start scripts to `%LOCALAPPDATA%\\Programs\\Konnek\\AI-Backend` and creates Start Menu/Desktop/Startup shortcuts. Start script: `tools/start-all.ps1`.
- Unix (Linux/macOS): install.sh performs package installs and post-install configuration and writes env vars to user shell profiles. Start script: `tools/start-all.sh`.
- Uninstaller: `tools/uninstall.ps1` removes per-user shortcuts and the install folder.

## Bifrost Stack Installers (`resources/inference-serving/localai-services/`)

The bifrost stack installs and configures three services in a fixed order:

1. **llama-server** — local inference endpoint (port 9931)
2. **bifrost-http** — AI Gateway (port 8080) that registers llama-server as a provider
3. **goose** — ACP server (port 3284) that registers bifrost and llama-server as providers

### Installation Order

```
llama-server  →  bifrost-http  →  goose
```

### Scripts

| Script | Purpose |
|--------|---------|
| `install-llama-server.sh` / `.ps1` | Downloads llama-app binary (renamed to `llama`), creates systemd/NSSM service |
| `install-bifrost.sh` / `.ps1` | Downloads bifrost + bifrost-http binaries, generates setup token, configures via API with idempotency guards |
| `install-goose.sh` / `.ps1` | Downloads goose binary, discovers bifrost VK and llama models dynamically, creates service |
| `install-all.sh` / `.ps1` | Runs all three installers in order |
| `uninstall-llama-server.sh` / `.ps1` | Removes llama-server service, binary, directories |
| `uninstall-bifrost.sh` / `.ps1` | Removes bifrost-http service, binaries, env file, directories |
| `uninstall-goose.sh` / `.ps1` | Removes goose service, binary, config, directories |
| `uninstall-all.sh` / `.ps1` | Runs all three uninstallers in reverse order |

### Common Flags

| Flag | Description |
|------|-------------|
| `--system` | System-wide deployment (default: per-user) |
| `--purge` | (uninstall only) Purge all data directories |
| `--skip-llama` | (install-all only) Skip llama-server installation |
| `--skip-bifrost` | (install-all only) Skip bifrost-http installation |
| `--skip-goose` | (install-all only) Skip goose installation |
| `--help` | Show help message |

### Component-Specific Flags

**install-llama-server:**
- `--llama-binary <path>` — Use existing binary instead of downloading
- `--llama-args <args>` — Extra arguments passed to `llama serve`

**install-bifrost:**
- `--prefix <path>` — Installation prefix (default: `/usr/local` or `C:\Program Files`)
- `--bifrost-binary <path>` — Use existing bifrost-http binary
- `--bifrost-cli-binary <path>` — Use existing bifrost CLI binary
- `--bifrost-args <args>` — Extra arguments passed to bifrost-http
- `--bifrost-version <ver>` — Bifrost CLI version (default: `latest`)
- `--bifrost-http-version <ver>` — Bifrost-http version (default: `v2.3.2`)

**install-goose:**
- `--goose-binary <path>` — Use existing goose binary instead of downloading
- `--goose-args <args>` — Extra arguments passed to `goose serve`

### Deployment Modes

**Linux (bash/systemd):**
- Per-user: `systemd --user` services, binaries in `$HOME/.local/bin`, data in `$HOME/.config`/`$HOME/.local/share`
- System (`--system`): `systemd --system` services, binaries in `/usr/local/bin`, data in `/var/lib`, dedicated service users

**Windows (PowerShell/NSSM):**
- Per-user: NSSM services, binaries in `%LOCALAPPDATA%\bin`, data in `%APPDATA%`
- System (`--system`): NSSM services, binaries in `C:\Program Files\<service>\bin`, data in `C:\ProgramData\<service>`
- NSSM is auto-downloaded from https://nssm.cc if not present

### Ports

| Service | Port | Purpose |
|---------|------|---------|
| llama-server | 9931 | Local inference (`/v1/models`, `/v1/chat/completions`) |
| bifrost-http | 8080 | AI Gateway API (`/api/config`, `/api/v1/*`) |
| goose | 3284 | ACP server (`/`, MCP/WebSocket endpoints) |

### Environment Variables

**llama-server** (`service.env`):
- `LLAMA_ARG_HOST` — default `127.0.0.1`
- `LLAMA_ARG_PORT` — default `9931`
- `NGL_LEVEL` — default `auto`
- `CONTEXT_SIZE` — default `0`
- `LOG_LEVEL` — default `info`

**bifrost-http** (`service.env`):
- `BIFROST_HOST` — default `localhost`
- `BIFROST_PORT` — default `8080`
- `BIFROST_SETUP_TOKEN` — auto-generated 64-char hex token
- `BIFROST_APP_DIR` — auto-detected (config.db location or `/tmp/bifrost-app`)
- `LLAMA_ARG_HOST` — default `127.0.0.1`
- `LLAMA_ARG_PORT` — default `9931`
- `LOG_LEVEL` — default `info`

**goose** (`goose.env`):
- `GOOSE_PATH_ROOT` — working directory for goose data
- `GOOSE_PORT` — default `3284`
- `GOOSE_HOST` — default `127.0.0.1`
- `BIFROST_HOST` — default `127.0.0.1`
- `BIFROST_PORT` — default `8080`
- `BIFROST_VK` — discovered from bifrost-http virtual-keys API
- `LLAMA_ARG_HOST` — default `127.0.0.1`
- `LLAMA_ARG_PORT` — default `9931`
- `LOG_LEVEL` — default `info`

### Idempotency & Non-Destructive Behavior

- **File creation**: All scripts check `if [ -f "..." ]` (bash) / `Test-Path` (PowerShell) before writing config files, preserving existing configurations on re-runs.
- **Binary download**: Skips download if binary already exists at target path.
- **API calls** (bifrost-http): All `POST`/`PUT` calls use a **GET-before-POST/PUT** pattern (`api_exists()` / `Test-BifrostApiExists`) to avoid creating duplicate providers, keys, models, routing rules, routing targets, virtual keys, or virtual key provider configs.
- **Service creation**: Existing service files are preserved; services are only created if the service file does not already exist.

### Usage Examples

**Linux (per-user):**
```bash
./install-all.sh
```

**Linux (system-wide):**
```bash
sudo ./install-all.sh --system
```

**Linux (skip bifrost, install llama + goose only):**
```bash
./install-all.sh --skip-bifrost
```

**Windows (PowerShell, per-user):**
```powershell
.\install-all.ps1
```

**Windows (PowerShell, system-wide, admin required):**
```powershell
.\install-all.ps1 -System
```

**Uninstall (reverse order, with purge):**
```bash
./uninstall-all.sh --system --purge
```
```powershell
.\uninstall-all.ps1 -System -Purge
```

### Service Management

**Linux:**
```bash
# Check status
systemctl --user status llama-server.service
systemctl --user status bifrost-http.service
systemctl --user status goose.service

# Restart
systemctl --user restart llama-server.service
systemctl --user restart bifrost-http.service
systemctl --user restart goose.service

# View logs
journalctl --user -u llama-server.service -f
journalctl --user -u bifrost-http.service -f
journalctl --user -u goose.service -f
```

**Windows:**
```powershell
# Check status
Get-Service -Name llama-server -ErrorAction SilentlyContinue
Get-Service -Name bifrost-http -ErrorAction SilentlyContinue
Get-Service -Name goose -ErrorAction SilentlyContinue

# Start/Stop
Start-Service -Name goose
Stop-Service -Name goose

# View logs (NSSM log files)
Get-Content $env:APPDATA\goose\goose.log -Tail 50 -Wait
```

### Test Endpoints

```bash
# llama-server models
curl http://127.0.0.1:9931/v1/models

# bifrost-http config
curl http://127.0.0.1:8080/api_config

# goose ACP server
curl http://127.0.0.1:3284/
```

## Logging & Rotation

- Windows logs: `%TEMP%\\AI-Backend-Logs` — daily rotation, gzip/zip compression, size-based rotation (default 10MB), and 7-day retention.
- Unix logs: `${XDG_STATE_HOME:-$HOME/.local/state}/ai-backend-logs` with similar rotation and retention.

## Request/Response Flow (summary)

- Goose sends requests to bifrost-http (AI Gateway) which routes LLM completions to llama-server and streams tokens back.
- Goose connects to bifrost MCP Gateway at `http://localhost:8080/mcp` for MCP server integration.
- bifrost-http provides governance, routing rules, virtual keys, and provider management via its REST API.

## Operational Notes & Tips

- Default installation is per-user (no elevation required). Elevated package manager installs (winget/choco/brew) still require elevation.
- For robustness consider running components under supervision (systemd user units on Linux, NSSM or Windows services for persistent runs).
- Test deeplinks and Goose installs in the Goose Desktop environment to validate goose:// extension URLs.

## Files of Interest

- `install.ps1`, `install.sh` — installers
- `tools/start-all.ps1`, `tools/start-all.sh` — start scripts (hidden-by-default with -Visible/--visible option)
- `tools/uninstall.ps1` — per-user uninstaller
- `extensions.md` — Goose Extensions registry
- `resources/inference-serving/localai-services/install-*.sh/.ps1` — bifrost stack installers
- `resources/inference-serving/localai-services/uninstall-*.sh/.ps1` — bifrost stack uninstallers

If you want, add a dedicated troubleshooting or operations page with step-by-step checks for failures (ports, logs, process supervision).