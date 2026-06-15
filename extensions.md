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
    </div>
