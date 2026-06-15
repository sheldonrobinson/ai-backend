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
    <a href='powershell:Set-ExecutionPolicy Bypass -Scope Process -Force; iex (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/sheldonrobinson/ai-backend/main/install.ps1").Content' style="text-decoration:none;">
        <button class="install-btn">Install AI Backend (One‑Click)</button>
    </a>
    <div class="install-note">Runs the installer directly from memory using <code>powershell:</code> URI.</div>
</div>

<div class="install-section">
    <div class="install-title">⬇️ Download‑and‑Run Version</div>
    <a href="https://raw.githubusercontent.com/sheldonrobinson/ai-backend/main/install.ps1" download style="text-decoration:none;">
        <button class="install-btn">Download Installer (install.ps1)</button>
    </a>
    <div class="install-note">Downloads the installer file. You can right-click it and select "Run with PowerShell".</div>
</div>

<div class="install-section">
    <div class="install-title">🛡️ Fallback Version</div>
    <div class="install-note">
        If your browser blocks <code>powershell:</code> links, run this manually in a PowerShell terminal:
    </div>
    <div class="code-snippet">
Set-ExecutionPolicy Bypass -Scope Process -Force; iex (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/sheldonrobinson/ai-backend/main/install.ps1").Content
    </div>
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

*(For more extensions, see the skills list below or generate your own deeplinks at [Goose Docs Deeplink Generator](https://goose-docs.ai/deeplink-generator))*

---

## Skills Directory

A curated list of agent skills grouped by business category to enhance your AI Agent's functionality.

### Development & Engineering
* **General Skills:** `npx skills add https://github.com/block/Agent-Skills -y --agent goose cline`
* **Gooseworks (Local):** `npx -y skills add gooseworks-ai/goose-skills`
* **Chrome DevTools:** `npx skills add ChromeDevTools/chrome-devtools-mcp -y --agent goose cline`
* **MCP Ext Apps:** `npx skills add https://github.com/modelcontextprotocol/ext-apps.git -y --agent cline goose`
* **Stack Overflow for Agents:** `npx skills add https://agents.stackoverflow.com/ --skill sofa -y --agent cline goose`
* **Product Manager:** `npx skills add deanpeters/product-manager-skills -y --global --agent goose cline`

### Search & Research
* **Exa Labs Search:** `npx skills add exa-labs/exa-mcp-server -y --agent goose cline`
* **Open WebSearch:** `npx skills add https://github.com/Aas-ee/open-webSearch --skill open-websearch -y --agent cline goose`
* **Academic/Literature Research:** `npx skills add heymoezy/porter --skill academic-researcher bibliographic-researcher literature-reviewer -y --agent goose cline`

### Finance & Operations
* **Finance Skills Core:** `npx skills add JoelLewis/finance_skills`
* **Advisory Practice:** `npx skills add https://github.com/JoelLewis/finance_skills/tree/main/plugins/advisory-practice -y --agent goose cline`
* **Client Operations:** `npx skills add https://github.com/JoelLewis/finance_skills/tree/main/plugins/client-operations/skills -y --agent goose cline`
* **Compliance:** `npx skills add https://github.com/JoelLewis/finance_skills/tree/main/plugins/compliance -y --agent goose cline`
* **Trading Operations:** `npx skills add https://github.com/JoelLewis/finance_skills/tree/main/plugins/trading-operations -y --agent goose cline`
* **Wealth Management:** `npx skills add https://github.com/JoelLewis/finance_skills/tree/main/plugins/wealth-management -y --agent goose cline`
* **Risk Manager:** `npx skills add finskills/risk-manager -y global --agent goose cline`

### Legal Services
* **OpenAgreements:** `npx skills add open-agreements/open-agreements -y --agent goose cline` (AI-assisted system for routine contracts)

### Healthcare & Biotechnology
* **BioMCP:** `npx skills add genomoncology/biomcp -y --agent goose cline`

### Supply Chain & Logistics
* **Supply Chain Optimizer:** `npx skills add heymoezy/porter --skill logistics-optimizer supply-chain-optimizer -y --agent goose cline`

### Smart Home / IoT
* **Home Assistant:** `npx skills add home-assistant/core integrations -y --agent goose cline`

### Security
* **OpenClaw Security (MacOS preferred):** `npx skills add UseAI-pro/openclaw-skills-security -y --agent goose cline`

### Media & Productivity
* **Google Workspace (Gemini CLI):** `npx skills add gemini-cli-extensions/workspace -y --agent goose cline`
* **Transcript & Video Utils:** `npx skills add steipete/agent-scripts --skill agent-transcript create-cli nano-banana-pro video-transcript-downloader -y --agent goose cline`

### Blockchain / Crypto (Alternative Markets)
* **DeBridge Skills:** `npx skills add debridge-finance/debridge-skills --agent cline goose`

### AI / ML specific
* **HuggingFace Skills:** `npx skills add huggingface/skills -y --agent goose cline`

---
*For full component documentation and advanced configurations, see the individual component repositories.*