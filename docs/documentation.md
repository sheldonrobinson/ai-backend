# AI Backend — Components & Architecture

This documentation summarizes the purpose of each component in the AI Backend, how they interact, and operational notes.

<!-- Diagram removed per request -->


## Components

- Llama.C++ HTTP Server
  - Role: Local inference engine serving text completions and streaming tokens over HTTP (example: localhost:11434).
  - Purpose: Fast on-device LLM inference using ggml backends; used for chat, completion, and streaming token responses.
  - Notes: Configurable via LLAMA_ARG_* environment variables; models referenced via models.ini.

- agentgateway (LLM Proxy)
  - Role: HTTP gateway that exposes a consistent API to callers and routes LLM requests to Llama.C++ (or other LLMs).
  - Purpose: Centralizes LLM access, adds transport/timeout management, and provides OpenAPI or MCP-friendly endpoints for other components.
  - Notes: Set LOCAL_XDS_PATH to point to gateway.yml for runtime config.

- MCPJungle (MCP Gateway)
  - Role: Model Context Protocol gateway that routes MCP JSON requests between agents (Goose) and MCP servers.
  - Purpose: Acts as catalog & router (default port 9000), enabling Goose to call domain-specific MCP servers (weather, docs, memory, etc.).
  - Notes: MCP servers register with MCPJungle; MCPJungle returns MCP responses back to Goose.

- Goose (Agent)
  - Role: Agentic orchestration application that runs skills and invokes external MCP servers and LLMs.
  - Purpose: Provides skill execution, deeplink installs for extensions, and coordinates agent workflows.
  - Notes: Extensions are installed via goose:// deeplinks; skills may be added via the skills system.

## Supporting Scripts & Installers

- Windows: install.ps1 installs packages and copies per-user start scripts to `%LOCALAPPDATA%\\Programs\\Konnek\\AI-Backend` and creates Start Menu/Desktop/Startup shortcuts. Start script: `tools/start-all.ps1`.
- Unix (Linux/macOS): install.sh performs package installs and post-install configuration (models.ini, gateway.yml, mcpjungle.db) and writes env vars to user shell profiles. Start script: `tools/start-all.sh`.
- Uninstaller: `tools/uninstall.ps1` removes per-user shortcuts and the install folder.

## Logging & Rotation

- Windows logs: `%TEMP%\\AI-Backend-Logs` — daily rotation, gzip/zip compression, size-based rotation (default 10MB), and 7-day retention.
- Unix logs: `${XDG_STATE_HOME:-$HOME/.local/state}/ai-backend-logs` with similar rotation and retention.

## Request/Response Flow (summary)

- Goose sends MCP JSON requests to MCPJungle; MCPJungle routes them to the appropriate MCP Server and returns responses via MCPJungle back to Goose.
- Goose or MCP Servers needing LLM completions call agentgateway; agentgateway forwards to Llama.C++ and streams tokens back.
- MCP Servers can optionally call agentgateway for completions to augment their MCP responses.

## Operational Notes & Tips

- Default installation is per-user (no elevation required). Elevated package manager installs (winget/choco/brew) still require elevation.
- For robustness consider running components under supervision (systemd user units on Linux, NSSM or Windows services for persistent runs).
- Test deeplinks and Goose installs in the Goose Desktop environment to validate goose:// extension URLs.

## Files of Interest

- `install.ps1`, `install.sh` — installers
- `tools/start-all.ps1`, `tools/start-all.sh` — start scripts (hidden-by-default with -Visible/--visible option)
- `tools/uninstall.ps1` — per-user uninstaller
- `extensions.md` — Goose Extensions registry

If you want, add a dedicated troubleshooting or operations page with step-by-step checks for failures (ports, logs, process supervision).