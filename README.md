AI Backend — Bifrost Stack
==========================

This repository bundles installers for running a local AI backend composed of:

- **llama-server** — Local inference engine serving text completions over HTTP (port 9931)
- **bifrost-http** — AI Gateway for routing, governance, virtual keys, and MCP Gateway endpoints (port 8080)
- **goose** — AI Agent / ACP server (port 3284)

🚀 **[Visit our GitHub Pages site](https://sheldonrobinson.github.io/ai-backend/) for full documentation, extensions gallery, and skill registry!**

Whether you're in **financial services**, **legal**, **supply-chain & logistics**, **healthcare**, **content creation & social media management**, or tackling **lifestyle, travel, job-seeking, or career challenges** — this AI backend empowers you to deploy private, on-device LLM agents that integrate with your workflows. No cloud vendor lock-in, no API costs, full privacy.

## Installation Order

Services are installed and configured in this order:

```
llama-server  →  bifrost-http  →  goose
```

1. **llama-server** registers as a local inference provider
2. **bifrost-http** configures governance, routes requests to llama-server
3. **goose** registers bifrost and llama-server as providers, connects to bifrost MCP Gateway

## Quick Install

### Windows (PowerShell)

Run the all-in-one installer (elevated steps may be requested for system-wide deployment):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/sheldonrobinson/ai-backend/main/install-all.ps1').Content"
```

### Linux / macOS (Bash)

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/sheldonrobinson/ai-backend/main/install-all.sh)"
```

## Installer Scripts

All scripts are in the [`resources/inference-serving/localai-services/`](https://github.com/sheldonrobinson/ai-backend/tree/main/resources/inference-serving/localai-services) directory.

### Installers

| Script | Description |
|--------|-------------|
| `install-all.sh` / `install-all.ps1` | Installs all three services in order |
| `install-llama-server.sh` / `.ps1` | Installs llama-server only |
| `install-bifrost.sh` / `.ps1` | Installs bifrost-http only |
| `install-goose.sh` / `.ps1` | Installs goose only |

### Uninstallers

| Script | Description |
|--------|-------------|
| `uninstall-all.sh` / `uninstall-all.ps1` | Removes all services in reverse order |
| `uninstall-llama-server.sh` / `.ps1` | Removes llama-server only |
| `uninstall-bifrost.sh` / `.ps1` | Removes bifrost-http only |
| `uninstall-goose.sh` / `.ps1` | Removes goose only |

### Common Flags

| Flag | Description |
|------|-------------|
| `--system` | System-wide deployment (default: per-user) |
| `--purge` | (uninstall only) Purge all data directories |
| `--skip-llama` | (install-all only) Skip llama-server |
| `--skip-bifrost` | (install-all only) Skip bifrost-http |
| `--skip-goose` | (install-all only) Skip goose |
| `--help` | Show help message |

### Component-Specific Flags

**install-llama-server:** `--llama-binary <path>`, `--llama-args <args>`

**install-bifrost:** `--prefix <path>`, `--bifrost-binary <path>`, `--bifrost-cli-binary <path>`, `--bifrost-args <args>`, `--bifrost-version <ver>`, `--bifrost-http-version <ver>`

**install-goose:** `--goose-binary <path>`, `--goose-args <args>`

## Ports

| Service | Port | Purpose |
|---------|------|---------|
| llama-server | 9931 | Local inference (`/v1/models`, `/v1/chat/completions`) |
| bifrost-http | 8080 | AI Gateway API (`/api/config`, `/api/v1/*`, `/mcp`) |
| goose | 3284 | ACP server |

## Service Management

### Linux (systemd)

Per-user services (default):
```bash
systemctl --user status llama-server.service
systemctl --user status bifrost-http.service
systemctl --user status goose.service
```

System-wide services (`--system`):
```bash
sudo systemctl status llama-server.service
sudo systemctl status bifrost-http.service
sudo systemctl status goose.service
```

### Windows (NSSM)

```powershell
Get-Service -Name llama-server -ErrorAction SilentlyContinue
Get-Service -Name bifrost-http -ErrorAction SilentlyContinue
Get-Service -Name goose -ErrorAction SilentlyContinue
```

## Uninstall

Reverse order: goose → bifrost-http → llama-server

```bash
./uninstall-all.sh          # per-user
./uninstall-all.sh --system # system-wide
./uninstall-all.sh --system --purge  # purge all data
```

```powershell
.\uninstall-all.ps1          # per-user
.\uninstall-all.ps1 -System  # system-wide
.\uninstall-all.ps1 -System -Purge  # purge all data
```

## Logs

- **Linux:** `journalctl --user -u <service-name>.service -f`
- **Windows:** NSSM log files in `%APPDATA%\<service>\` or `%PROGRAMDATA%\<service>\`

## Idempotency

All installers are idempotent and non-destructive:

- Existing binary files are preserved (not overwritten)
- Existing configuration files are preserved (not overwritten)
- Existing service files are preserved (not recreated)
- Bifrost-http API calls use GET-before-POST/PUT guards to avoid duplicate registrations

## Contributing

Contributions welcome. Open issues or PRs for improvements, additional service supervision, or packaging.