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
    {"name": "Stack Overflow for Agents", "desc": "Interact with Stack Overflow for Agents: authenticate, search validated knowledge, read context pages.", "cmd": "npx skills add https://agents.stackoverflow.com/ --skill sofa --yes --agent cline goose", "category": "Development & Engineering"},
    
    # Additional Goose Extensions
    {"name": "TradingView", "desc": "AI-powered trading toolkit for Claude and MCP clients. Backtesting + Live Sentiment + Yahoo Finance + 30+ Technical Analysis Tools — all in one MCP server.", "cmd": "uvx --from tradingview-mcp-server tradingview-mcp", "category": "Finance & Operations"},
    {"name": "Bluesky Social", "desc": "A full-featured Bluesky MCP server that adds search, feeds, trends, follower graph tools, thread retrieval, and rich content/engagement management for agentic workflows.", "cmd": "npx -y @semihberkay/bluesky-mcp", "category": "Media & Productivity"},
    {"name": "Mastodon Social", "desc": "A minimal Mastodon MCP server providing basic posting, timeline access, and simple social interactions for agentic clients.", "cmd": "uvx --from mastodon-mcp-server mastodon-mcp", "category": "Media & Productivity"},
    {"name": "LinkedIn Newsletter", "desc": "A minimal LinkedIn MCP server that exposes basic profile lookup and posting capabilities for lightweight agent automation.", "cmd": "uvx ldraney-linkedin-mcp", "category": "Media & Productivity"},
    {"name": "LinkedIn", "desc": "A minimal LinkedIn MCP server that enables agents to authenticate, fetch profiles, and perform basic LinkedIn interactions programmatically.", "cmd": "uvx linkedin-scraper-mcp@latest --transport stdio", "category": "Media & Productivity"},
    {"name": "LinkedIn Jobs and Network", "desc": "A lightweight MCP server that exposes LinkedIn search and profile-scraping capabilities to agentic clients.", "cmd": "npx -y @pegasusheavy/linkedin-mcp", "category": "Media & Productivity"},
    {"name": "Git Server", "desc": "MCP Git Server designed to interact with Git repositories, particularly useful for tasks such as repository management, branch operations, commit handling, and more.", "cmd": "uvx mcp-server-git", "category": "Development & Engineering"},
    {"name": "Excel", "desc": "A Model Context Protocol server for Excel file manipulation", "cmd": "uvx excel-mcp-server stdio", "category": "Media & Productivity"},
    {"name": "Judicial Research Agent", "desc": "An MCP server that lets AI agents search and retrieve 3M+ U.S. court decisions and EU legislation via CourtListener and EUR-Lex for legal research.", "cmd": "uvx --from legal-court-mcp-server legal-court-server", "category": "Legal Services"},
    {"name": "Real Estate Assistant", "desc": "An MCP server that gives AI agents unified access to U.S. real-estate data, including property records, valuations, and market insights for analysis and automation.", "cmd": "uvx --from real-estate-data-mcp-server real-estate-server", "category": "Finance & Operations"},
    {"name": "Job Market Analyst", "desc": "An MCP server providing global labor-market data, including unemployment rates, wages, sector employment, and occupation outlooks using official BLS (US) and Eurostat (EU) APIs.", "cmd": "uvx --from labor-market-mcp-server labor-market-server", "category": "Finance & Operations"},
    {"name": "Crossref Research Assistant", "desc": "An MCP server that lets AI agents query Crossref for academic metadata, including DOIs, authors, journals, citations, and publication records for research automation.", "cmd": "uvx --from crossref-academic-mcp-server crossref-server", "category": "Search & Research"},
    {"name": "Supply-Chain Agent", "desc": "A lightweight MCP server providing structured access to logistics workflows—shipments, tracking, routing, and supply-chain operations—for AI agents and automation.", "cmd": "uvx logistics_ai_mcp", "category": "Supply Chain & Logistics"},
    {"name": "Open WebSearch", "desc": "A Multi-engine MCP server, CLI, and local daemon, that can also be paired with skill-guided agent workflows for live web search and content retrieval.", "cmd": "npx -y open-websearch@latest mcp", "category": "Search & Research"}
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