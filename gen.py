import json
import urllib.parse
import re

extensions = [
    # True Extensions
    {"name": "shadcn UI", "id": "shadcn", "desc": "A shadcn/ui-native MCP server enabling structured component metadata, actions, and UI-aware tooling.", "cmd": "npx", "args": ["-y", "shadcn@latest", "mcp"], "category": "Development & Engineering"},
    {"name": "Legal Document Analyzer", "id": "legal-doc-analyzer", "desc": "Analyzes legal documents, extract key clauses, summarize content, and highlight potential risks.", "cmd": "npx", "args": ["-y", "mcp-legal-doc-analyzer@latest", "--templates", "~/.legal-doc-analyzer/templates", "--db-path", "~/.legal-doc-analyzer/legal.db"], "category": "Legal Services"},
    {"name": "TradingView", "id": "tradingview", "desc": "AI-powered trading toolkit for Claude and MCP clients. Backtesting + Live Sentiment + Yahoo Finance + 30+ Technical Analysis Tools — all in one MCP server.", "cmd": "uvx", "args": ["--from", "tradingview-mcp-server", "tradingview-mcp"], "category": "Finance & Operations"},
    {"name": "Bluesky Social", "id": "blueskysocial", "desc": "A full-featured Bluesky MCP server that adds search, feeds, trends, follower graph tools, thread retrieval, and rich content/engagement management for agentic workflows.", "cmd": "npx", "args": ["-y", "@semihberkay/bluesky-mcp"], "category": "Media & Productivity", "envs": ["BLUESKY_IDENTIFIER", "BLUESKY_SERVICE_URL", "BLUESKY_APP_PASSWORD"]},
    {"name": "Mastodon Social", "id": "mastodonsocial", "desc": "A minimal Mastodon MCP server providing basic posting, timeline access, and simple social interactions for agentic clients.", "cmd": "uvx", "args": ["--from", "mastodon-mcp-server", "mastodon-mcp"], "category": "Media & Productivity", "envs": ["MASTODON_INSTANCE", "MASTODON_ACCESS_TOKEN"]},
    {"name": "LinkedIn Newsletter", "id": "linkedinnewsletter", "desc": "A minimal LinkedIn MCP server that exposes basic profile lookup and posting capabilities for lightweight agent automation.", "cmd": "uvx", "args": ["ldraney-linkedin-mcp"], "category": "Media & Productivity", "envs": ["LINKEDIN_PERSON_ID", "LINKEDIN_ACCESS_TOKEN"]},
    {"name": "LinkedIn", "id": "linkedin", "desc": "A minimal LinkedIn MCP server that enables agents to authenticate, fetch profiles, and perform basic LinkedIn interactions programmatically.", "cmd": "uvx", "args": ["linkedin-scraper-mcp@latest", "--transport", "stdio"], "category": "Media & Productivity", "envs": ["UV_HTTP_TIMEOUT"]},
    {"name": "LinkedIn Jobs and Network", "id": "linkedinjobsandnetwork", "desc": "A lightweight MCP server that exposes LinkedIn search and profile-scraping capabilities to agentic clients.", "cmd": "npx", "args": ["-y", "@pegasusheavy/linkedin-mcp"], "category": "Media & Productivity", "envs": ["LINKEDIN_ACCESS_TOKEN"]},
    {"name": "Git Server", "id": "git", "desc": "MCP Git Server designed to interact with Git repositories, particularly useful for tasks such as repository management, branch operations, commit handling, and more.", "cmd": "uvx", "args": ["mcp-server-git"], "category": "Development & Engineering"},
    {"name": "Excel", "id": "excel", "desc": "A Model Context Protocol server for Excel file manipulation", "cmd": "uvx", "args": ["excel-mcp-server", "stdio"], "category": "Media & Productivity"},
    {"name": "Judicial Research Agent", "id": "judicialresearchagent", "desc": "An MCP server that lets AI agents search and retrieve 3M+ U.S. court decisions and EU legislation via CourtListener and EUR-Lex for legal research.", "cmd": "uvx", "args": ["--from", "legal-court-mcp-server", "legal-court-server"], "category": "Legal Services"},
    {"name": "Real Estate Assistant", "id": "realestateassistant", "desc": "An MCP server that gives AI agents unified access to U.S. real-estate data, including property records, valuations, and market insights for analysis and automation.", "cmd": "uvx", "args": ["--from", "real-estate-data-mcp-server", "real-estate-server"], "category": "Finance & Operations"},
    {"name": "Job Market Analyst", "id": "jobmarketanalyst", "desc": "An MCP server providing global labor-market data, including unemployment rates, wages, sector employment, and occupation outlooks using official BLS (US) and Eurostat (EU) APIs.", "cmd": "uvx", "args": ["--from", "labor-market-mcp-server", "labor-market-server"], "category": "Finance & Operations"},
    {"name": "Crossref Research Assistant", "id": "crossrefresearchassistant", "desc": "An MCP server that lets AI agents query Crossref for academic metadata, including DOIs, authors, journals, citations, and publication records for research automation.", "cmd": "uvx", "args": ["--from", "crossref-academic-mcp-server", "crossref-server"], "category": "Search & Research"},
    {"name": "Supply-Chain Agent", "id": "supply-chain-agent", "desc": "A lightweight MCP server providing structured access to logistics workflows—shipments, tracking, routing, and supply-chain operations—for AI agents and automation.", "cmd": "uvx", "args": ["logistics_ai_mcp"], "category": "Supply Chain & Logistics"},
    {"name": "Open WebSearch", "id": "open_websearch", "desc": "A Multi-engine MCP server, CLI, and local daemon, that can also be paired with skill-guided agent workflows for live web search and content retrieval.", "cmd": "npx", "args": ["-y", "open-websearch@latest", "mcp"], "category": "Search & Research"}
]

# Skills
skills = [
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
    {"name": "Product Manager", "desc": "Product Management skills for agents.", "cmd": "npx skills add deanpeters/product-manager-skills -y --agent goose cline", "category": "Development & Engineering"},
    {"name": "Supply Chain Optimizer", "desc": "Supply chain and logistics optimization skills.", "cmd": "npx skills add heymoezy/porter --skill logistics-optimizer supply-chain-optimizer -y --agent goose cline", "category": "Supply Chain & Logistics"},
    {"name": "Stack Overflow for Agents", "desc": "Interact with Stack Overflow for Agents: authenticate, search validated knowledge, read context pages.", "cmd": "npx skills add https://agents.stackoverflow.com/ --skill sofa --yes --agent cline goose", "category": "Development & Engineering"}
]

html = """---
layout: page
title: Extensions & Skills Registry
---

# 🧩 Goose Extensions & Skills Registry

Browse, discover, and install extensions and skills for your Goose Agent. 
- **Extensions** run external MCP servers to give the agent new capabilities.
- **Skills** add specialized prompt logic and workflow instructions directly to Goose.

<style>
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 20px; margin-top: 20px; margin-bottom: 40px;}
.card { border: 1px solid #e1e4e8; border-radius: 8px; padding: 20px; background: #fff; box-shadow: 0 1px 3px rgba(27,31,35,0.1); display: flex; flex-direction: column; justify-content: space-between; }
.card h3 { margin-top: 0; font-size: 1.25em; color: #24292e; }
.card p { font-size: 0.9em; color: #586069; flex-grow: 1; }
.install-btn { display: block; text-align: center; padding: 10px; background-color: #0366d6; color: #fff !important; text-decoration: none !important; border-radius: 6px; font-weight: 600; margin-top: 15px; transition: background-color 0.2s; }
.install-btn:hover { background-color: #005cc5; }
.tag { display: inline-block; padding: 4px 8px; background-color: #f1f8ff; color: #0366d6; border-radius: 12px; font-size: 0.75em; font-weight: 600; margin-bottom: 12px; align-self: flex-start; }
.tag.skill { background-color: #e6ffed; color: #0366d6; border: 1px solid #0366d6; }
.cmd-preview { background: #f6f8fa; padding: 8px; border-radius: 4px; font-family: monospace; font-size: 0.75em; overflow-x: auto; white-space: nowrap; margin-top: 10px; color: #24292e; border: 1px solid #eaecef; }
.section-title { border-bottom: 2px solid #eaecef; padding-bottom: 10px; margin-top: 40px;}
</style>

<h2 class="section-title">📦 Extensions (MCP Servers)</h2>
<p>Click "Install with Goose" to add these directly to Goose Desktop.</p>
<div class="grid">
"""

for ext in extensions:
    # Build query params
    params = {
        "cmd": ext["cmd"],
        "id": ext["id"],
        "name": ext["name"],
        "description": ext["desc"]
    }
    
    # URL Encode params
    encoded_params = [f"{k}={urllib.parse.quote(str(v))}" for k, v in params.items()]
    
    # Add array of args
    for arg in ext["args"]:
        encoded_params.append(f"arg={urllib.parse.quote(arg)}")
    
    # Add envs if any
    if "envs" in ext:
        for env in ext["envs"]:
            # Format is env=KEY=Description
            encoded_params.append(f"env={urllib.parse.quote(env + '=' + env)}")
            
    query_string = "&".join(encoded_params)
    deeplink = f"goose://extension?{query_string}"
    
    # Create copyable view string
    display_cmd = f"{ext['cmd']} " + " ".join(ext["args"])
    
    html += f"""
    <div class="card">
        <span class="tag">{ext['category']}</span>
        <h3>{ext['name']}</h3>
        <p>{ext['desc']}</p>
        <div class="cmd-preview">{display_cmd}</div>
        <a href="{deeplink}" class="install-btn">➕ Install Extension</a>
    </div>
    """

html += "</div>\n\n"

html += """
<h2 class="section-title">🧠 Agent Skills</h2>
<p>Run these commands in your terminal to install these specialized skills into Goose.</p>
<div class="grid">
"""

for skill in skills:
    html += f"""
    <div class="card">
        <div>
            <span class="tag skill">{skill['category']}</span>
            <span class="tag skill" style="background-color: #ffdce0; color: #22863a; border-color: #22863a;">Skill</span>
        </div>
        <h3>{skill['name']}</h3>
        <p>{skill['desc']}</p>
        <div class="cmd-preview">{skill['cmd']}</div>
    </div>
    """

html += "</div>\n"

with open("extensions.md", "w", encoding="utf-8") as f:
    f.write(html)
print("Generated extensions.md")