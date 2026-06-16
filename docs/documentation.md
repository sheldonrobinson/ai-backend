# AI Backend — Components & Architecture

This documentation summarizes the purpose of each component in the AI Backend, how they interact, and operational notes.

<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="700" viewBox="0 0 1200 700">
  <defs>
    <marker id="arrow" markerWidth="10" markerHeight="10" refX="10" refY="5" orient="auto" markerUnits="strokeWidth">
      <path d="M0,0 L10,5 L0,10 z" fill="#333" />
    </marker>
    <style>
      .box { fill:#f8fafc; stroke:#2d3748; stroke-width:1.5; rx:10; }
      .title { font: bold 16px sans-serif; fill:#0f172a; }
      .label { font: 13px sans-serif; fill:#0f172a; }
      .note { font: 12px sans-serif; fill:#475569; }
      .arrow { stroke:#1f2937; stroke-width:2; fill:none; marker-end:url(#arrow); }
    </style>
  </defs>

  <!-- Title -->
  <text x="40" y="36" class="title">AI Backend Request / Response Flow</text>
  <text x="40" y="56" class="note">Components: Goose (agent), MCPJungle (gateway), MCP Servers, agentgateway (LLM proxy), Llama.C++ (inference)</text>

  <!-- Goose -->
  <rect x="40" y="100" width="200" height="80" class="box" />
  <text x="60" y="130" class="label">Goose (Agent / Desktop)</text>
  <text x="60" y="150" class="note">Sends MCP requests & LLM prompts</text>

  <!-- MCPJungle -->
  <rect x="320" y="120" width="220" height="100" class="box" />
  <text x="340" y="150" class="label">MCPJungle (MCP Gateway)</text>
  <text x="340" y="170" class="note">Listens on :9000, routes MCP to servers</text>

  <!-- MCP Servers group -->
  <rect x="620" y="100" width="260" height="140" class="box" />
  <text x="640" y="130" class="label">MCP Servers</text>
  <text x="640" y="150" class="note">Weather, Docs, Memory, etc.</text>
  <text x="640" y="170" class="note">Respond via MCPJungle back to Goose</text>

  <!-- agentgateway -->
  <rect x="320" y="260" width="220" height="100" class="box" />
  <text x="340" y="290" class="label">agentgateway (LLM Proxy)</text>
  <text x="340" y="310" class="note">HTTP API to Llama.C++ or other LLMs</text>

  <!-- Llama -->
  <rect x="620" y="280" width="260" height="100" class="box" />
  <text x="640" y="310" class="label">Llama.C++ HTTP Server</text>
  <text x="640" y="330" class="note">LLM inference (localhost:11434)</text>

  <!-- Logs -->
  <rect x="40" y="420" width="320" height="80" class="box" />
  <text x="60" y="450" class="label">Logs & Rotation</text>
  <text x="60" y="470" class="note">%TEMP%/AI-Backend-Logs (Windows)</text>
  <text x="60" y="490" class="note">$XDG_STATE_HOME/ai-backend-logs (Unix)</text>

  <!-- Arrows: Goose -> MCPJungle -> MCP Servers -->
  <path d="M240 140 L320 140" class="arrow" />
  <text x="270" y="128" class="note">MCP request (JSON)</text>

  <path d="M540 160 L620 160" class="arrow" />
  <text x="580" y="148" class="note">Forward MCP request</text>

  <!-- MCP Servers -> MCPJungle -> Goose (response) -->
  <path d="M620 220 L540 220" class="arrow" />
  <text x="580" y="236" class="note">MCP response</text>

  <path d="M320 220 L240 180" class="arrow" />
  <text x="260" y="206" class="note">Return to Goose</text>

  <!-- Goose -> agentgateway -> Llama -->
  <path d="M240 160 L320 300" class="arrow" />
  <text x="260" y="230" class="note">LLM prompt / completion request</text>

  <path d="M540 310 L620 310" class="arrow" />
  <text x="580" y="298" class="note">HTTP/JSON</text>

  <!-- Llama -> agentgateway -> Goose (streaming response) -->
  <path d="M880 330 L760 330 L760 200 L240 180" class="arrow" />
  <text x="540" y="360" class="note">Tokens/streaming response (via agentgateway)</text>

  <!-- MCP Servers may call agentgateway -->
  <path d="M740 180 L740 260" stroke="#ff7b00" stroke-width="2" fill="none" marker-end="url(#arrow)"/>
  <text x="750" y="220" class="note" fill="#ff7b00">MCP Server may call agentgateway for completions</text>

  <!-- Decorative arrows to logs -->
  <path d="M220 180 L220 420" class="arrow" />
  <text x="232" y="310" class="note">Stdout/stderr redirected</text>

  <!-- Legend -->
  <rect x="920" y="100" width="250" height="140" rx="8" fill="#f1f5f9" stroke="#cbd5e1" />
  <text x="940" y="126" class="label">Legend</text>
  <text x="940" y="150" class="note">Solid arrows: request/response</text>
  <text x="940" y="170" class="note">Orange: optional LLM calls from MCP servers</text>
  <text x="940" y="190" class="note">Logs: rotation, compression, 7-day retention</text>

</svg>

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
- `ai-backend-flow.svg` — architecture diagram (embedded above)

If you want, add a dedicated troubleshooting or operations page with step-by-step checks for failures (ports, logs, process supervision).