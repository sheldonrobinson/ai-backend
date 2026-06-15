---
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

    <div class="card">
        <span class="tag">Development & Engineering</span>
        <h3>shadcn UI</h3>
        <p>A shadcn/ui-native MCP server enabling structured component metadata, actions, and UI-aware tooling.</p>
        <div class="cmd-preview">npx -y shadcn@latest mcp</div>
        <a href="goose://extension?name=shadcn%20UI&cmd=npx%20-y%20shadcn%40latest%20mcp" class="install-btn">➕ Install with Goose</a>
    </div>
    
    <div class="card">
        <span class="tag">Legal Services</span>
        <h3>Legal Document Analyzer</h3>
        <p>Analyzes legal documents, extract key clauses, summarize content, and highlight potential risks.</p>
        <div class="cmd-preview">npx -y mcp-legal-doc-analyzer@latest --templates ~/.legal-doc-analyzer/templates --db-path ~/.legal-doc-analyzer/legal.db</div>
        <a href="goose://extension?name=Legal%20Document%20Analyzer&cmd=npx%20-y%20mcp-legal-doc-analyzer%40latest%20--templates%20~/.legal-doc-analyzer/templates%20--db-path%20~/.legal-doc-analyzer/legal.db" class="install-btn">➕ Install with Goose</a>
    </div>
    
    <div class="card">
        <span class="tag">Legal Services</span>
        <h3>OpenAgreements</h3>
        <p>AI-assisted system for generating clear, consistent drafts of common legal documents and routine contracts.</p>
        <div class="cmd-preview">npx skills add open-agreements/open-agreements -y --agent goose cline</div>
        <a href="goose://extension?name=OpenAgreements&cmd=npx%20skills%20add%20open-agreements/open-agreements%20-y%20--agent%20goose%20cline" class="install-btn">➕ Install with Goose</a>
    </div>
    
    <div class="card">
        <span class="tag">Healthcare & Biotechnology</span>
        <h3>BioMCP</h3>
        <p>Search and retrieve biomedical data - genes, variants, clinical trials, and phenotype-disease matching.</p>
        <div class="cmd-preview">npx skills add genomoncology/biomcp -y --agent goose cline</div>
        <a href="goose://extension?name=BioMCP&cmd=npx%20skills%20add%20genomoncology/biomcp%20-y%20--agent%20goose%20cline" class="install-btn">➕ Install with Goose</a>
    </div>
    
    <div class="card">
        <span class="tag">Smart Home / IoT</span>
        <h3>Home Assistant</h3>
        <p>Everything you need to know to build, test and review Home Assistant Integrations.</p>
        <div class="cmd-preview">npx skills add home-assistant/core integrations -y --agent goose cline</div>
        <a href="goose://extension?name=Home%20Assistant&cmd=npx%20skills%20add%20home-assistant/core%20integrations%20-y%20--agent%20goose%20cline" class="install-btn">➕ Install with Goose</a>
    </div>
    
    <div class="card">
        <span class="tag">Development & Engineering</span>
        <h3>Gooseworks (Local)</h3>
        <p>Portable visual skill pack for the Agent Skills ecosystem.</p>
        <div class="cmd-preview">npx -y skills add gooseworks-ai/goose-skills</div>
        <a href="goose://extension?name=Gooseworks%20%28Local%29&cmd=npx%20-y%20skills%20add%20gooseworks-ai/goose-skills" class="install-btn">➕ Install with Goose</a>
    </div>
    
    <div class="card">
        <span class="tag">Media & Productivity</span>
        <h3>Gemini Workspace</h3>
        <p>Google Workspace Extension for Gemini CLI.</p>
        <div class="cmd-preview">npx skills add gemini-cli-extensions/workspace -y --agent goose cline</div>
        <a href="goose://extension?name=Gemini%20Workspace&cmd=npx%20skills%20add%20gemini-cli-extensions/workspace%20-y%20--agent%20goose%20cline" class="install-btn">➕ Install with Goose</a>
    </div>
    
    <div class="card">
        <span class="tag">Development & Engineering</span>
        <h3>Chrome DevTools</h3>
        <p>Uses Chrome DevTools via MCP for efficient debugging, troubleshooting and browser automation.</p>
        <div class="cmd-preview">npx skills add ChromeDevTools/chrome-devtools-mcp -y --agent goose cline</div>
        <a href="goose://extension?name=Chrome%20DevTools&cmd=npx%20skills%20add%20ChromeDevTools/chrome-devtools-mcp%20-y%20--agent%20goose%20cline" class="install-btn">➕ Install with Goose</a>
    </div>
    
    <div class="card">
        <span class="tag">Search & Research</span>
        <h3>Exa Labs Search</h3>
        <p>Deep research powered by Exa. Use for lead generation, literature reviews, deep dives, competitive analysis.</p>
        <div class="cmd-preview">npx skills add exa-labs/exa-mcp-server -y --agent goose cline</div>
        <a href="goose://extension?name=Exa%20Labs%20Search&cmd=npx%20skills%20add%20exa-labs/exa-mcp-server%20-y%20--agent%20goose%20cline" class="install-btn">➕ Install with Goose</a>
    </div>
    
    <div class="card">
        <span class="tag">AI / ML specific</span>
        <h3>HuggingFace Skills</h3>
        <p>Hugging Face Hub CLI (hf) for downloading, uploading, and managing models, datasets, spaces, buckets.</p>
        <div class="cmd-preview">npx skills add huggingface/skills -y --agent goose cline</div>
        <a href="goose://extension?name=HuggingFace%20Skills&cmd=npx%20skills%20add%20huggingface/skills%20-y%20--agent%20goose%20cline" class="install-btn">➕ Install with Goose</a>
    </div>
    
    <div class="card">
        <span class="tag">Security</span>
        <h3>OpenClaw Security</h3>
        <p>Security-first vetting for OpenClaw skills. Use before installing any skill from ClawHub, GitHub.</p>
        <div class="cmd-preview">npx skills add UseAI-pro/openclaw-skills-security -y --agent goose cline</div>
        <a href="goose://extension?name=OpenClaw%20Security&cmd=npx%20skills%20add%20UseAI-pro/openclaw-skills-security%20-y%20--agent%20goose%20cline" class="install-btn">➕ Install with Goose</a>
    </div>
    
    <div class="card">
        <span class="tag">Finance & Operations</span>
        <h3>Finance Skills</h3>
        <p>Financial analyst agent skill. Ratio analysis, DCF valuation, budget variance, rolling forecasts.</p>
        <div class="cmd-preview">npx skills add JoelLewis/finance_skills</div>
        <a href="goose://extension?name=Finance%20Skills&cmd=npx%20skills%20add%20JoelLewis/finance_skills" class="install-btn">➕ Install with Goose</a>
    </div>
    
    <div class="card">
        <span class="tag">Development & Engineering</span>
        <h3>Product Manager</h3>
        <p>Product Management skills for agents.</p>
        <div class="cmd-preview">npx skills add deanpeters/product-manager-skills -y --global --agent goose cline</div>
        <a href="goose://extension?name=Product%20Manager&cmd=npx%20skills%20add%20deanpeters/product-manager-skills%20-y%20--global%20--agent%20goose%20cline" class="install-btn">➕ Install with Goose</a>
    </div>
    
    <div class="card">
        <span class="tag">Supply Chain & Logistics</span>
        <h3>Supply Chain Optimizer</h3>
        <p>Supply chain and logistics optimization skills.</p>
        <div class="cmd-preview">npx skills add heymoezy/porter --skill logistics-optimizer supply-chain-optimizer -y --agent goose cline</div>
        <a href="goose://extension?name=Supply%20Chain%20Optimizer&cmd=npx%20skills%20add%20heymoezy/porter%20--skill%20logistics-optimizer%20supply-chain-optimizer%20-y%20--agent%20goose%20cline" class="install-btn">➕ Install with Goose</a>
    </div>
    
    <div class="card">
        <span class="tag">Development & Engineering</span>
        <h3>Stack Overflow for Agents</h3>
        <p>Interact with Stack Overflow for Agents: authenticate, search validated knowledge, read context pages.</p>
        <div class="cmd-preview">npx skills add https://agents.stackoverflow.com/ --skill sofa --yes --agent cline goose</div>
        <a href="goose://extension?name=Stack%20Overflow%20for%20Agents&cmd=npx%20skills%20add%20https%3A//agents.stackoverflow.com/%20--skill%20sofa%20--yes%20--agent%20cline%20goose" class="install-btn">➕ Install with Goose</a>
    </div>
    
    <div class="card">
        <span class="tag">Finance & Operations</span>
        <h3>TradingView</h3>
        <p>AI-powered trading toolkit for Claude and MCP clients. Backtesting + Live Sentiment + Yahoo Finance + 30+ Technical Analysis Tools — all in one MCP server.</p>
        <div class="cmd-preview">uvx --from tradingview-mcp-server tradingview-mcp</div>
        <a href="goose://extension?name=TradingView&cmd=uvx%20--from%20tradingview-mcp-server%20tradingview-mcp" class="install-btn">➕ Install with Goose</a>
    </div>
    
    <div class="card">
        <span class="tag">Media & Productivity</span>
        <h3>Bluesky Social</h3>
        <p>A full-featured Bluesky MCP server that adds search, feeds, trends, follower graph tools, thread retrieval, and rich content/engagement management for agentic workflows.</p>
        <div class="cmd-preview">npx -y @semihberkay/bluesky-mcp</div>
        <a href="goose://extension?name=Bluesky%20Social&cmd=npx%20-y%20%40semihberkay/bluesky-mcp" class="install-btn">➕ Install with Goose</a>
    </div>
    
    <div class="card">
        <span class="tag">Media & Productivity</span>
        <h3>Mastodon Social</h3>
        <p>A minimal Mastodon MCP server providing basic posting, timeline access, and simple social interactions for agentic clients.</p>
        <div class="cmd-preview">uvx --from mastodon-mcp-server mastodon-mcp</div>
        <a href="goose://extension?name=Mastodon%20Social&cmd=uvx%20--from%20mastodon-mcp-server%20mastodon-mcp" class="install-btn">➕ Install with Goose</a>
    </div>
    
    <div class="card">
        <span class="tag">Media & Productivity</span>
        <h3>LinkedIn Newsletter</h3>
        <p>A minimal LinkedIn MCP server that exposes basic profile lookup and posting capabilities for lightweight agent automation.</p>
        <div class="cmd-preview">uvx ldraney-linkedin-mcp</div>
        <a href="goose://extension?name=LinkedIn%20Newsletter&cmd=uvx%20ldraney-linkedin-mcp" class="install-btn">➕ Install with Goose</a>
    </div>
    
    <div class="card">
        <span class="tag">Media & Productivity</span>
        <h3>LinkedIn</h3>
        <p>A minimal LinkedIn MCP server that enables agents to authenticate, fetch profiles, and perform basic LinkedIn interactions programmatically.</p>
        <div class="cmd-preview">uvx linkedin-scraper-mcp@latest --transport stdio</div>
        <a href="goose://extension?name=LinkedIn&cmd=uvx%20linkedin-scraper-mcp%40latest%20--transport%20stdio" class="install-btn">➕ Install with Goose</a>
    </div>
    
    <div class="card">
        <span class="tag">Media & Productivity</span>
        <h3>LinkedIn Jobs and Network</h3>
        <p>A lightweight MCP server that exposes LinkedIn search and profile-scraping capabilities to agentic clients.</p>
        <div class="cmd-preview">npx -y @pegasusheavy/linkedin-mcp</div>
        <a href="goose://extension?name=LinkedIn%20Jobs%20and%20Network&cmd=npx%20-y%20%40pegasusheavy/linkedin-mcp" class="install-btn">➕ Install with Goose</a>
    </div>
    
    <div class="card">
        <span class="tag">Development & Engineering</span>
        <h3>Git Server</h3>
        <p>MCP Git Server designed to interact with Git repositories, particularly useful for tasks such as repository management, branch operations, commit handling, and more.</p>
        <div class="cmd-preview">uvx mcp-server-git</div>
        <a href="goose://extension?name=Git%20Server&cmd=uvx%20mcp-server-git" class="install-btn">➕ Install with Goose</a>
    </div>
    
    <div class="card">
        <span class="tag">Media & Productivity</span>
        <h3>Excel</h3>
        <p>A Model Context Protocol server for Excel file manipulation</p>
        <div class="cmd-preview">uvx excel-mcp-server stdio</div>
        <a href="goose://extension?name=Excel&cmd=uvx%20excel-mcp-server%20stdio" class="install-btn">➕ Install with Goose</a>
    </div>
    
    <div class="card">
        <span class="tag">Legal Services</span>
        <h3>Judicial Research Agent</h3>
        <p>An MCP server that lets AI agents search and retrieve 3M+ U.S. court decisions and EU legislation via CourtListener and EUR-Lex for legal research.</p>
        <div class="cmd-preview">uvx --from legal-court-mcp-server legal-court-server</div>
        <a href="goose://extension?name=Judicial%20Research%20Agent&cmd=uvx%20--from%20legal-court-mcp-server%20legal-court-server" class="install-btn">➕ Install with Goose</a>
    </div>
    
    <div class="card">
        <span class="tag">Finance & Operations</span>
        <h3>Real Estate Assistant</h3>
        <p>An MCP server that gives AI agents unified access to U.S. real-estate data, including property records, valuations, and market insights for analysis and automation.</p>
        <div class="cmd-preview">uvx --from real-estate-data-mcp-server real-estate-server</div>
        <a href="goose://extension?name=Real%20Estate%20Assistant&cmd=uvx%20--from%20real-estate-data-mcp-server%20real-estate-server" class="install-btn">➕ Install with Goose</a>
    </div>
    
    <div class="card">
        <span class="tag">Finance & Operations</span>
        <h3>Job Market Analyst</h3>
        <p>An MCP server providing global labor-market data, including unemployment rates, wages, sector employment, and occupation outlooks using official BLS (US) and Eurostat (EU) APIs.</p>
        <div class="cmd-preview">uvx --from labor-market-mcp-server labor-market-server</div>
        <a href="goose://extension?name=Job%20Market%20Analyst&cmd=uvx%20--from%20labor-market-mcp-server%20labor-market-server" class="install-btn">➕ Install with Goose</a>
    </div>
    
    <div class="card">
        <span class="tag">Search & Research</span>
        <h3>Crossref Research Assistant</h3>
        <p>An MCP server that lets AI agents query Crossref for academic metadata, including DOIs, authors, journals, citations, and publication records for research automation.</p>
        <div class="cmd-preview">uvx --from crossref-academic-mcp-server crossref-server</div>
        <a href="goose://extension?name=Crossref%20Research%20Assistant&cmd=uvx%20--from%20crossref-academic-mcp-server%20crossref-server" class="install-btn">➕ Install with Goose</a>
    </div>
    
    <div class="card">
        <span class="tag">Supply Chain & Logistics</span>
        <h3>Supply-Chain Agent</h3>
        <p>A lightweight MCP server providing structured access to logistics workflows—shipments, tracking, routing, and supply-chain operations—for AI agents and automation.</p>
        <div class="cmd-preview">uvx logistics_ai_mcp</div>
        <a href="goose://extension?name=Supply-Chain%20Agent&cmd=uvx%20logistics_ai_mcp" class="install-btn">➕ Install with Goose</a>
    </div>
    
    <div class="card">
        <span class="tag">Search & Research</span>
        <h3>Open WebSearch</h3>
        <p>A Multi-engine MCP server, CLI, and local daemon, that can also be paired with skill-guided agent workflows for live web search and content retrieval.</p>
        <div class="cmd-preview">npx -y open-websearch@latest mcp</div>
        <a href="goose://extension?name=Open%20WebSearch&cmd=npx%20-y%20open-websearch%40latest%20mcp" class="install-btn">➕ Install with Goose</a>
    </div>
    </div>
