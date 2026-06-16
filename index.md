---
layout: page
title: Home
---

<div style="display:flex;justify-content:center;margin-bottom:18px;">
  <a href="index.html" style="margin:0 8px;padding:8px 12px;background:#1e1e1e;color:#fff;border-radius:6px;text-decoration:none;">🏠 Home</a>
  <a href="extensions.html" style="margin:0 8px;padding:8px 12px;background:#1e1e1e;color:#fff;border-radius:6px;text-decoration:none;">🧩 Extensions & Skills</a>
  <a href="https://github.com/sheldonrobinson/ai-backend" target="_blank" style="margin:0 8px;padding:8px 12px;background:#1e1e1e;color:#fff;border-radius:6px;text-decoration:none;">📦 Repo</a>
</div>

# AI Backend

A consolidated installer and toolkit for running a local AI backend. This project sets up:
1. **Llama.C++** - The core inference engine ([docs](https://github.com/ggml-org/llama.cpp/tree/master/tools/server))
2. **AgentGateway** - LLM Proxy for routing and management ([docs](https://github.com/agentgateway/agentgateway))
3. **MCPJungle** - MCP Gateway for tooling integration ([docs](https://github.com/mcpjungle/MCPJungle))
4. **Goose** - AI Agent ([docs](https://github.com/aaif-goose/goose/))

---

## Quick Install

### Windows

<!-- ONE-CLICK INSTALL SECTION -->
<style>
    .install-section {
        font-family: system-ui, sans-serif;
        margin: 40px 0;
        padding: 20px;
        border: 1px solid #e5e5e5;
        border-radius: 12px;
        background: #fafafa;
    }
    .install-title {
        font-size: 22px;
        font-weight: 600;
        margin-bottom: 16px;
    }
    .install-btn {
        display: inline-block;
        padding: 12px 20px;
        margin: 8px 0;
        font-size: 16px;
        border-radius: 8px;
        cursor: pointer;
        border: none;
        color: white;
        background: #0078d4;
        transition: background 0.2s ease;
        text-decoration: none;
    }
    .install-btn:hover {
        background: #005ea6;
    }
    .install-note {
        font-size: 14px;
        color: #555;
        margin-top: 6px;
    }
    .code-snippet {
        background: #1e1e1e;
        color: #dcdcdc;
        padding: 12px;
        border-radius: 6px;
        font-family: Consolas, monospace;
        margin-top: 10px;
        white-space: pre-wrap;
    }
</style>

<div class="install-section">
    <div class="install-title">🔥 One‑Click PowerShell Installer</div>
    <a href='powershell:Set-ExecutionPolicy Bypass -Scope Process -Force; iex (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/sheldonrobinson/ai-backend/main/install.ps1").Content' style="text-decoration: none;">
        <button class="install-btn">Install AI Backend (One‑Click)</button>
    </a>
    <div class="install-note">Runs the installer directly from memory using <code>powershell:</code> URI.</div>
</div>

<div class="install-section">
    <div class="install-title">⬇️ Download‑and‑Run Version</div>
    <a href="https://raw.githubusercontent.com/sheldonrobinson/ai-backend/main/install.ps1" download style="text-decoration: none;">
        <button class="install-btn">Download Installer (install.ps1)</button>
    </a>
    <div class="install-note">Downloads the installer file. You can right-click it and select "Run with PowerShell".</div>
</div>

<div class="install-section">
    <div class="install-title">🛡️ Fallback Version</div>
    <div class="install-note">
        If your browser blocks <code>powershell:</code> links, run this manually in a PowerShell terminal:
    </div>
    <div class="code-snippet">Set-ExecutionPolicy Bypass -Scope Process -Force; iex (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/sheldonrobinson/ai-backend/main/install.ps1").Content</div>
</div>

*Note: The script will automatically detect if you have an NVIDIA or AMD GPU and install the appropriate ggml-backend (CUDA or Vulkan) for maximum performance.*

### Linux/MacOS

Run the automated bash script from your terminal:

```bash
curl -sL https://raw.githubusercontent.com/sheldonrobinson/ai-backend/main/install.sh | bash
```

Ensure you have [Homebrew](https://brew.sh/) installed before running the script.

---

## Goose Extensions

Extend your Goose Agent capabilities by installing extensions. Click the links below to install them directly (requires Goose Desktop).

* [**shadcn UI**](goose://extension?name=shadcn%20UI&cmd=npx%20-y%20shadcn%40latest%20mcp) - A shadcn/ui–native MCP server enabling structured component metadata, actions, and UI-aware tooling.
* [**Legal Document Analyzer**](goose://extension?name=Legal%20Document%20Analyzer&cmd=npx%20-y%20mcp-legal-doc-analyzer%40latest%20--templates%20~%2F.legal-doc-analyzer%2Ftemplates%20--db-path%20~%2F.legal-doc-analyzer%2Flegal.db) - Analyzes legal documents, extracts key clauses, and highlights risks.

*(For a full list of extensions and an interactive grid, view our [Extensions Registry](extensions.html))*

---

## Skills Directory

A curated list of agent skills grouped by business category to enhance your AI Agent's functionality.

### Development & Engineering
* **General Skills:**

<div class="cmd-preview">npx skills add https://github.com/block/Agent-Skills -y --agent goose cline</div>

* **Gooseworks (Local):**

<div class="cmd-preview">npx -y skills add gooseworks-ai/goose-skills</div>

* **Chrome DevTools:**

<div class="cmd-preview">npx skills add ChromeDevTools/chrome-devtools-mcp -y --agent goose cline</div>

* **MCP Ext Apps:**

<div class="cmd-preview">npx skills add https://github.com/modelcontextprotocol/ext-apps.git -y --agent cline goose</div>

* **Stack Overflow for Agents:**

<div class="cmd-preview">npx skills add https://agents.stackoverflow.com/ --skill sofa -y --agent cline goose</div>

* **Product Manager:**

<div class="cmd-preview">npx skills add deanpeters/product-manager-skills -y --global --agent goose cline</div>

### Search & Research
* **Exa Labs Search:**

<div class="cmd-preview">npx skills add exa-labs/exa-mcp-server -y --agent goose cline</div>

* **Open WebSearch:**

<div class="cmd-preview">npx skills add https://github.com/Aas-ee/open-webSearch --skill open-websearch -y --agent cline goose</div>

* **Academic/Literature Research:**

<div class="cmd-preview">npx skills add heymoezy/porter --skill academic-researcher bibliographic-researcher literature-reviewer -y --agent goose cline</div>

### Finance & Operations
* **Finance Skills Core:**

<div class="cmd-preview">npx skills add JoelLewis/finance_skills</div>

* **Advisory Practice:**

<div class="cmd-preview">npx skills add https://github.com/JoelLewis/finance_skills/tree/main/plugins/advisory-practice -y --agent goose cline</div>

* **Client Operations:**

<div class="cmd-preview">npx skills add https://github.com/JoelLewis/finance_skills/tree/main/plugins/client-operations/skills -y --agent goose cline</div>

* **Compliance:**

<div class="cmd-preview">npx skills add https://github.com/JoelLewis/finance_skills/tree/main/plugins/compliance -y --agent goose cline</div>

* **Trading Operations:**

<div class="cmd-preview">npx skills add https://github.com/JoelLewis/finance_skills/tree/main/plugins/trading-operations -y --agent goose cline</div>

* **Wealth Management:**

<div class="cmd-preview">npx skills add https://github.com/JoelLewis/finance_skills/tree/main/plugins/wealth-management -y --agent goose cline</div>

* **Risk Manager:**

<div class="cmd-preview">npx skills add finskills/risk-manager -y global --agent goose cline</div>

### Legal Services
* **OpenAgreements:** (AI-assisted system for routine contracts)

<div class="cmd-preview">npx skills add open-agreements/open-agreements -y --agent goose cline</div>

### Healthcare & Biotechnology
* **BioMCP:**

<div class="cmd-preview">npx skills add genomoncology/biomcp -y --agent goose cline</div>

### Supply Chain & Logistics
* **Supply Chain Optimizer:**

<div class="cmd-preview">npx skills add heymoezy/porter --skill logistics-optimizer supply-chain-optimizer -y --agent goose cline</div>

### Smart Home / IoT
* **Home Assistant:**

<div class="cmd-preview">npx skills add home-assistant/core integrations -y --agent goose cline</div>

### Security
* **OpenClaw Security (MacOS preferred):**

<div class="cmd-preview">npx skills add UseAI-pro/openclaw-skills-security -y --agent goose cline</div>

### Media & Productivity
* **Google Workspace (Gemini CLI):**

<div class="cmd-preview">npx skills add gemini-cli-extensions/workspace -y --agent goose cline</div>

* **Transcript & Video Utils:**

<div class="cmd-preview">npx skills add steipete/agent-scripts --skill agent-transcript create-cli nano-banana-pro video-transcript-downloader -y --agent goose cline</div>

### Blockchain / Crypto (Alternative Markets)
* **DeBridge Skills:**

<div class="cmd-preview">npx skills add debridge-finance/debridge-skills --agent cline goose</div>

### AI / ML specific
* **HuggingFace Skills:**

<div class="cmd-preview">npx skills add huggingface/skills -y --agent goose cline</div>

---
*For full component documentation and advanced configurations, see the individual component repositories.*