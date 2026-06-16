AI Backend
============

This repository bundles components and installers to run a local AI backend composed of:

- llama.cpp (Llama.C++) — inference HTTP server
- agentgateway — LLM proxy
- MCPJungle — MCP gateway
- Goose — AI agent / CLI

🚀 **[Visit our GitHub Pages site](https://sheldonrobinson.github.io/ai-backend/) for full documentation, extensions gallery, and skill registry!**

Whether you're in **financial services**, **legal**, **supply-chain & logistics**, **healthcare**, **content creation & social media management**, or tackling **lifestyle, travel, job-seeking, or career challenges** — this AI backend empowers you to deploy private, on-device LLM agents that integrate with your workflows. No cloud vendor lock-in, no API costs, full privacy.

Quick start (Windows)

1. Open PowerShell as your normal user and run the installer (elevated steps may be requested by installer for system packages):
```
   powershell -NoProfile -ExecutionPolicy Bypass -Command "iex (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/sheldonrobinson/ai-backend/main/install.ps1')"
```
2. After install, use Start Menu or Desktop shortcut "AI Backend" to start components (hidden by default). To show consoles run the start script with -Visible.

Quick start (Linux / macOS)

1. Run the installer:
```
   bash -c "$(curl -fsSL https://raw.githubusercontent.com/sheldonrobinson/ai-backend/main/install.sh)"
```
2. Start services (background, logs in ~/.local/state/ai-backend-logs):
```
   ~/.local/share/Konnek/AI-Backend/start-all.sh
```
   To show terminals: ~/.local/share/Konnek/AI-Backend/start-all.sh --visible

Logs

- Windows: `%TEMP%\AI-Backend-Logs`
- Linux/macOS: `${XDG_STATE_HOME:-$HOME/.local/state}/ai-backend-logs`

Uninstall

- Windows: Start Menu -> Konnek -> Uninstall AI Backend or run %LOCALAPPDATA%\Programs\Konnek\AI-Backend\uninstall.ps1
- Linux/macOS: remove ~/.konnek and delete installed binaries as appropriate; tools/uninstall.ps1 exists for Windows only.

Contributing

Contributions welcome. Open issues or PRs for improvements, additional service supervision (systemd/launchd), or packaging.
