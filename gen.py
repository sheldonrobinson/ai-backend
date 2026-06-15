import json
import urllib.parse

extensions = [
    {"name": "shadcn UI", "desc": "A shadcn/ui-native MCP server enabling structured component metadata, actions, and UI-aware tooling.", "cmd": "npx -y shadcn@latest mcp", "category": "Development & Engineering"},
    {"name": "Legal Document Analyzer", "desc": "Analyzes legal documents, extract key clauses, summarize content, and highlight potential risks.", "cmd": "npx -y mcp-legal-doc-analyzer@latest --templates ~/.legal-doc-analyzer/templates --db-path ~/.legal-doc-analyzer/legal.db", "category": "Legal Services"},
    {"name": "OpenAgreements", "desc": "AI-assisted system for generating clear, consistent drafts of common legal documents and routine contracts.", "cmd": "npx skills add open-agreements/open-agreements -y --agent goose cline", "category": "Legal Services"},
    {"name": "BioMCP", "desc": "Search and retrieve biomedical data - genes, variants, clinical trials, and phenotype-disease matching.", "cmd": "npx skills add genomoncology/biomcp -y --agent goose cline", "category": "Healthcare & Biotechnology"},
    {"name": "Home Assistant", "desc": "Everything you need to know to build, test and review Home Assistant Integrations.", "cmd": "npx skills add home-assistant/core integrations -y --agent goose cline", "category": "Smart Home / IoT"},
    {"name": "Gooseworks (Local)", "desc": "Portable visual skill pack for the Agent Skills ecosystem.", "cmd": "npx -y skills add gooseworks-ai/goose-skills", "category": "Development & Engineering"},
    {"name": "Gemini Workspace", "desc": "Google Workspace Extension for Gemini CLI.", "cmd": "npx skills add gemini-cli-extensions/workspace -y --agent goose cline", "category": "Media & Productivity"},
    {"name": "Chrome DevTools", "desc": "Uses Chrome DevTools via MCP for efficient debugging, troubleshooting and browser automation.", "cmd": "npx skills add ChromeDevTools/chrome-devtools-mcp -y --agent goose cline", "category": "Development & Engineering"},
    {"name": "Exa Labs Search", "desc": "Deep research powered by Exa. Use for lead generation, literature reviews, deep dives, competitive analysis.", "cmd": "npx skills add exa-labs/exa-mcp-server -y --agent goose cline", "category": "Search & Research"},
    {"name": "HuggingFace Skills", "desc": "Hugging Face Hub CLI (hf) for downloading, uploading, and managing models, datasets, spaces, buckets.", "cmd": "npx skills add huggingface/skills -y --agent goose cline", "category": "AI / ML specific"},
    {"name": "OpenClaw Security", "desc": "Security-first vetting for OpenClaw skills. Use before installing any skill from ClawHub, GitHub.", "cmd": "npx skills add UseAI-pro/openclaw-skills-security -y --agent goose cline", "category": "Security"},
    {"name": "Finance Skills", "desc": "Financial analyst agent skill. Ratio analysis, DCF valuation, budget variance, rolling forecasts.", "cmd": "npx skills add JoelLewis/finance_skills", "category": "Finance & Operations"},
    {"name": "Product Manager", "desc": "Product Management skills for agents.", "cmd": "npx skills add deanpeters/product-manager-skills -y --global --agent goose cline", "category": "Development & Engineering"},
    {"name": "Supply Chain Optimizer", "desc": "Supply chain and logistics optimization skills.", "cmd": "npx skills add heymoezy/porter --skill logistics-optimizer supply-chain-optimizer -y --agent goose cline", "category": "Supply Chain & Logistics"},
    {"name": "Stack Overflow for Agents", "desc": "Interact with Stack Overflow for Agents: authenticate, search validated knowledge, read context pages.", "cmd": "npx skills add https://agents.stackoverflow.com/ --skill sofa --yes --agent cline goose", "category": "Development & Engineering"}
]

html = """---
layout: default
title: Extension Registry
---

# 🧩 Goose Extension Registry

Browse and install extensions directly to your Goose Agent with a single click.

<style>
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 20px; margin-top: 20px; }
.card { border: 1px solid #e1e4e8; border-radius: 8px; padding: 20px; background: #fff; box-shadow: 0 1px 3px rgba(27,31,35,0.1); display: flex; flex-direction: column; justify-content: space-between; }
.card h3 { margin-top: 0; font-size: 1.25em; color: #24292e; }
.card p { font-size: 0.9em; color: #586069; flex-grow: 1; }
.install-btn { display: block; text-align: center; padding: 10px; background-color: #0366d6; color: #fff !important; text-decoration: none !important; border-radius: 6px; font-weight: 600; margin-top: 15px; transition: background-color 0.2s; }
.install-btn:hover { background-color: #005cc5; }
.tag { display: inline-block; padding: 4px 8px; background-color: #f1f8ff; color: #0366d6; border-radius: 12px; font-size: 0.75em; font-weight: 600; margin-bottom: 12px; align-self: flex-start; }
.cmd-preview { background: #f6f8fa; padding: 8px; border-radius: 4px; font-family: monospace; font-size: 0.75em; overflow-x: auto; white-space: nowrap; margin-top: 10px; color: #24292e; border: 1px solid #eaecef; }
</style>

<div class="grid">
"""

for ext in extensions:
    name_enc = urllib.parse.quote(ext["name"])
    cmd_enc = urllib.parse.quote(ext["cmd"])
    deeplink = f"goose://extension?name={name_enc}&cmd={cmd_enc}"
    
    html += f"""
    <div class="card">
        <span class="tag">{ext['category']}</span>
        <h3>{ext['name']}</h3>
        <p>{ext['desc']}</p>
        <div class="cmd-preview">{ext['cmd']}</div>
        <a href="{deeplink}" class="install-btn">➕ Install with Goose</a>
    </div>
    """

html += "</div>\n"

with open("extensions.md", "w", encoding="utf-8") as f:
    f.write(html)
print("Generated extensions.md")
