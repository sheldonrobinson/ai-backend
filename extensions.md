---
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

## 📦 Extensions (MCP Servers)
<p>Click "Install with Goose" to add these directly to Goose Desktop.</p>
<label for="category-filter" style="font-weight:600; margin-right:8px;">Filter by category:</label>
<select id="category-filter" style="padding:6px 8px; border-radius:6px; border:1px solid #e1e4e8;">
  <option value="All">All</option>
</select>
<div style="height:12px"></div>
<div class="grid">

    
    
    <div class="card">
        <span class="tag">Finance & Operations</span>
        <h3>TradingView</h3>
        <p>AI-powered trading toolkit for Claude and MCP clients. Backtesting + Live Sentiment + Yahoo Finance + 30+ Technical Analysis Tools — all in one MCP server.</p>
        <div class="cmd-preview">uvx --from tradingview-mcp-server tradingview-mcp</div>
        <a href="goose://extension?cmd=uvx&id=tradingview&name=TradingView&description=AI-powered%20trading%20toolkit%20for%20Claude%20and%20MCP%20clients.%20Backtesting%20%2B%20Live%20Sentiment%20%2B%20Yahoo%20Finance%20%2B%2030%2B%20Technical%20Analysis%20Tools%20%E2%80%94%20all%20in%20one%20MCP%20server.&arg=--from&arg=tradingview-mcp-server&arg=tradingview-mcp" class="install-btn">➕ Install Extension</a>
    </div>

    <div class="card">
        <span class="tag">Finance & Operations</span>
        <h3>ALPHA VANTAGE</h3>
        <p>The official Alpha Vantage API MCP server enables LLMs and agentic workflows to seamlessly interact with real-time and historical stock market data.</p>
        <div class="cmd-preview">uvx --from marketdata-mcp-server marketdata-mcp $ALPHAVANTAGE_API_KEY</div>
        <a href="goose://extension?cmd=uvx&arg=--from&arg=marketdata-mcp-server&arg=marketdata-mcp&arg=%24ALPHAVANTAGE_API_KEY&id=alphavantage&name=ALPHA%20VANTAGE&description=The%20official%20Alpha%20Vantage%20API%20MCP%20server%20enables%20LLMs%20and%20agentic%20workflows%20to%20seamlessly%20interact%20with%20real-time%20and%20historical%20stock%20market%20data.&env=ALPHAVANTAGE_API_KEY%3Dyour-api-key" class="install-btn">➕ Install Extension</a>
    </div>
    
    <div class="card">
        <span class="tag">Finance & Operations</span>
        <h3>SEC EDGAR</h3>
        <p>A MCP server for connecting AI assistants SEC's Electronic Data Gathering, Analysis, and Retrieval (EDGAR) system for access to company filings, financial statements, and insider trading data.</p>
        <div class="cmd-preview">uvx sec-edgar-mcp</div>
        <a href="goose://extension?cmd=uvx&arg=sec-edgar-mcp&id=sec_edgar&name=SEC%20EDGAR&description=A%20MCP%20server%20for%20connecting%20AI%20assistants%20SEC's%20Electronic%20Data%20Gathering%2C%20Analysis%2C%20and%20Retrieval%20(EDGAR)%20system%20for%20access%20to%20company%20filings%2C%20financial%20statements%2C%20and%20insider%20trading%20data.&env=SEC_EDGAR_USER_AGENT%3DJohn%20Doe%20(john.doe%40example.com)" class="install-btn">➕ Install Extension</a>
    </div>
    
    <div class="card">
        <span class="tag">Finance & Operations</span>
        <h3>FRB of St. Louis FRED</h3>
        <p>A MCP server that provides access to Federal Reserve Bank of St. Louis FRED (Federal Reserve Economic Data), including the Maps API for regional and geographic data.</p>
        <div class="cmd-preview">uvx fred-mcp-server</div>
        <a href="goose://extension?cmd=uvx&arg=fred-mcp-server&id=stlouisfed_fred&name=FRB%20of%20St.%20Louis%20FRED&description=A%20MCP%20server%20that%20provides%20access%20to%20Federal%20Reserve%20Bank%20of%20St.%20Louis%20FRED%20(Federal%20Reserve%20Economic%20Data)%2C%20including%20the%20Maps%20API%20for%20regional%20and%20geographic%20data.&env=FRED_API_KEY%3Dyour-fred-api-key" class="install-btn">➕ Install Extension</a>
    </div>
    
    <div class="card">
        <span class="tag">Development & Engineering</span>
        <h3>shadcn UI</h3>
        <p>A shadcn/ui-native MCP server enabling structured component metadata, actions, and UI-aware tooling.</p>
        <div class="cmd-preview">npx -y shadcn@latest mcp</div>
        <a href="goose://extension?cmd=npx&id=shadcn&name=shadcn%20UI&description=A%20shadcn/ui-native%20MCP%20server%20enabling%20structured%20component%20metadata%2C%20actions%2C%20and%20UI-aware%20tooling.&arg=-y&arg=shadcn%40latest&arg=mcp" class="install-btn">➕ Install Extension</a>
    </div>

    <div class="card">
        <span class="tag">Media & Productivity</span>
        <h3>Bluesky Social</h3>
        <p>A full-featured Bluesky MCP server that adds search, feeds, trends, follower graph tools, thread retrieval, and rich content/engagement management for agentic workflows.</p>
        <div class="cmd-preview">npx -y @semihberkay/bluesky-mcp</div>
        <a href="goose://extension?cmd=npx&id=blueskysocial&name=Bluesky%20Social&description=A%20full-featured%20Bluesky%20MCP%20server%20that%20adds%20search%2C%20feeds%2C%20trends%2C%20follower%20graph%20tools%2C%20thread%20retrieval%2C%20and%20rich%20content/engagement%20management%20for%20agentic%20workflows.&arg=-y&arg=%40semihberkay/bluesky-mcp&env=BLUESKY_IDENTIFIER%3DBLUESKY_IDENTIFIER&env=BLUESKY_SERVICE_URL%3DBLUESKY_SERVICE_URL&env=BLUESKY_APP_PASSWORD%3DBLUESKY_APP_PASSWORD" class="install-btn">➕ Install Extension</a>
    </div>

    <div class="card">
        <span class="tag">Media & Productivity</span>
        <h3>Bluesky</h3>
        <p>A MCP server that connects to Bluesky and provides tools to interact with the ATProtocol.</p>
        <div class="cmd-preview">npx -y @brianellin/bsky-mcp-server</div>
        <a href="goose://extension?cmd=npx&arg=-y&arg=%40brianellin%2Fbsky-mcp-server&id=bluesky&name=Bluesky&description=A%20MCP%20server%20that%20connects%20to%20Bluesky%20and%20provides%20tools%20to%20interact%20with%20the%20ATProtocol.&env=BLUESKY_IDENTIFIER%3Dyour-handle.bsky.social&env=BLUESKY_APP_PASSWORD%3Dyour-app-password&env=BLUESKY_SERVICE_URL%3Dhttps%3A%2F%2Fbsky.social" class="install-btn">➕ Install Extension</a>
    </div>

    <div class="card">
        <span class="tag">Media & Productivity</span>
        <h3>Discord</h3>
        <p>A minimal Discord MCP server that exposes basic message-sending and channel-interaction tools for agentic automation.</p>
        <div class="cmd-preview">npx -y @pasympa/discord-mcp</div>
        <a href="goose://extension?cmd=npx&arg=-y&arg=%40pasympa%2Fdiscord-mcp&id=discord&name=Discord&description=A%20minimal%20Discord%20MCP%20server%20that%20exposes%20basic%20message-sending%20and%20channel-interaction%20tools%20for%20agentic%20automation.&env=DISCORD_TOKEN%3Dyour-discord-token" class="install-btn">➕ Install Extension</a>
    </div>

    <div class="card">
        <span class="tag">Media & Productivity</span>
        <h3>LinkedIn Jobs and Network</h3>
        <p>A lightweight MCP server that exposes LinkedIn search and profile-scraping capabilities to agentic clients.</p>
        <div class="cmd-preview">npx -y @pegasusheavy/linkedin-mcp</div>
        <a href="goose://extension?cmd=npx&id=linkedinjobsandnetwork&name=LinkedIn%20Jobs%20and%20Network&description=A%20lightweight%20MCP%20server%20that%20exposes%20LinkedIn%20search%20and%20profile-scraping%20capabilities%20to%20agentic%20clients.&arg=-y&arg=%40pegasusheavy/linkedin-mcp&env=LINKEDIN_ACCESS_TOKEN%3DLINKEDIN_ACCESS_TOKEN" class="install-btn">➕ Install Extension</a>
    </div>

    <div class="card">
        <span class="tag">Search & Research</span>
        <h3>Open WebSearch</h3>
        <p>A Multi-engine MCP server, CLI, and local daemon, that can also be paired with skill-guided agent workflows for live web search and content retrieval.</p>
        <div class="cmd-preview">npx -y open-websearch@latest</div>
        <a href="goose://extension?cmd=npx&arg=-y&arg=open-websearch%40latest&id=open_websearch&name=Open%20WebSearch&description=A%20Multi-engine%20MCP%20server%2C%20CLI%2C%20and%20local%20daemon%2C%20that%20can%20also%20be%20paired%20with%20skill-guided%20agent%20workflows%20for%20live%20web%20search%20and%20content%20retrieval.&env=ENABLE_CORS%3Dtrue&env=MODE%3Dstdio" class="install-btn">➕ Install Extension</a>
    </div>
    
    <div class="card">
        <span class="tag">Healthcare & Biotechnology</span>
        <h3>BioMCP</h3>
        <p>BioMCP is an open-source toolkit that empowers AI assistants and agents with specialized biomedical knowledge. It connects AI systems to authoritative biomedical data sources, enabling them to answer questions about clinical trials, scientific literature, and genomic variants with precision and depth.</p>
        <div class="cmd-preview">uvx --from biomcp-python biomcp run --mode stdio</div>
        <a href="goose://extension?cmd=uvx&arg=--from&arg=biomcp-python&arg=biomcp&arg=run&arg=--mode&arg=stdio&id=biomcp&name=BioMCP&description=BioMCP%20is%20an%20open-source%20toolkit%20that%20empowers%20AI%20assistants%20and%20agents%20with%20specialized%20biomedical%20knowledge.%20It%20connects%20AI%20systems%20to%20authoritative%20biomedical%20data%20sources%2C%20enabling%20them%20to%20answer%20questions%20about%20clinical%20trials%2C%20scientific%20literature%2C%20and%20genomic%20variants%20with%20precision%20and%20depth." class="install-btn">➕ Install Extension</a>
    </div>  
    
    <div class="card">
        <span class="tag">Media & Productivity</span>
        <h3>Mastodon Social</h3>
        <p>A minimal Mastodon MCP server providing basic posting, timeline access, and simple social interactions for agentic clients.</p>
        <div class="cmd-preview">uvx --from mastodon-mcp-server mastodon-mcp</div>
        <a href="goose://extension?cmd=uvx&id=mastodonsocial&name=Mastodon%20Social&description=A%20minimal%20Mastodon%20MCP%20server%20providing%20basic%20posting%2C%20timeline%20access%2C%20and%20simple%20social%20interactions%20for%20agentic%20clients.&arg=--from&arg=mastodon-mcp-server&arg=mastodon-mcp&env=MASTODON_INSTANCE%3DMASTODON_INSTANCE&env=MASTODON_ACCESS_TOKEN%3DMASTODON_ACCESS_TOKEN" class="install-btn">➕ Install Extension</a>
    </div>
    
    <div class="card">
        <span class="tag">Media & Productivity</span>
        <h3>LinkedIn Newsletter</h3>
        <p>A minimal LinkedIn MCP server that exposes basic profile lookup and posting capabilities for lightweight agent automation.</p>
        <div class="cmd-preview">uvx ldraney-linkedin-mcp</div>
        <a href="goose://extension?cmd=uvx&id=linkedinnewsletter&name=LinkedIn%20Newsletter&description=A%20minimal%20LinkedIn%20MCP%20server%20that%20exposes%20basic%20profile%20lookup%20and%20posting%20capabilities%20for%20lightweight%20agent%20automation.&arg=ldraney-linkedin-mcp&env=LINKEDIN_PERSON_ID%3DLINKEDIN_PERSON_ID&env=LINKEDIN_ACCESS_TOKEN%3DLINKEDIN_ACCESS_TOKEN" class="install-btn">➕ Install Extension</a>
    </div>
    
    <div class="card">
        <span class="tag">Media & Productivity</span>
        <h3>LinkedIn</h3>
        <p>A minimal LinkedIn MCP server that enables agents to authenticate, fetch profiles, and perform basic LinkedIn interactions programmatically.</p>
        <div class="cmd-preview">uvx linkedin-scraper-mcp@latest --transport stdio</div>
        <a href="goose://extension?cmd=uvx&id=linkedin&name=LinkedIn&description=A%20minimal%20LinkedIn%20MCP%20server%20that%20enables%20agents%20to%20authenticate%2C%20fetch%20profiles%2C%20and%20perform%20basic%20LinkedIn%20interactions%20programmatically.&arg=linkedin-scraper-mcp%40latest&arg=--transport&arg=stdio&env=UV_HTTP_TIMEOUT%3DUV_HTTP_TIMEOUT" class="install-btn">➕ Install Extension</a>
    </div>
    
    
    <div class="card">
        <span class="tag">Development & Engineering</span>
        <h3>Git Server</h3>
        <p>MCP Git Server designed to interact with Git repositories, particularly useful for tasks such as repository management, branch operations, commit handling, and more.</p>
        <div class="cmd-preview">uvx mcp-server-git</div>
        <a href="goose://extension?cmd=uvx&id=git&name=Git%20Server&description=MCP%20Git%20Server%20designed%20to%20interact%20with%20Git%20repositories%2C%20particularly%20useful%20for%20tasks%20such%20as%20repository%20management%2C%20branch%20operations%2C%20commit%20handling%2C%20and%20more.&arg=mcp-server-git" class="install-btn">➕ Install Extension</a>
    </div>
    
    <div class="card">
        <span class="tag">Media & Productivity</span>
        <h3>Excel</h3>
        <p>A Model Context Protocol server for Excel file manipulation</p>
        <div class="cmd-preview">uvx excel-mcp-server stdio</div>
        <a href="goose://extension?cmd=uvx&id=excel&name=Excel&description=A%20Model%20Context%20Protocol%20server%20for%20Excel%20file%20manipulation&arg=excel-mcp-server&arg=stdio" class="install-btn">➕ Install Extension</a>
    </div>
    
    <div class="card">
        <span class="tag">Legal Services</span>
        <h3>Judicial Research Agent</h3>
        <p>A MCP server that lets AI agents search and retrieve 3M+ U.S. court decisions and EU legislation via CourtListener and EUR-Lex for legal research.</p>
        <div class="cmd-preview">uvx --from legal-court-mcp-server legal-court-server</div>
        <a href="goose://extension?cmd=uvx&id=judicialresearchagent&name=Judicial%20Research%20Agent&description=A%20MCP%20server%20that%20lets%20AI%20agents%20search%20and%20retrieve%203M%2B%20U.S.%20court%20decisions%20and%20EU%20legislation%20via%20CourtListener%20and%20EUR-Lex%20for%20legal%20research.&arg=--from&arg=legal-court-mcp-server&arg=legal-court-server" class="install-btn">➕ Install Extension</a>
    </div>
    
    <div class="card">
        <span class="tag">Legal Services</span>
        <h3>Paralegal Assistant</h3>
        <p>A MCP server analyzes legal documents, extract key clauses, summarize content, and highlight potential risks for automated legal workflows.</p>
        <div class="cmd-preview">npx -y mcp-legal-doc-analyzer@latest --templates ~/.legal-doc-analyzer/templates --db-path ~/.legal-doc-analyzer/legal.db</div>
        <a href="goose://extension?cmd=npx&arg=-y&arg=mcp-legal-doc-analyzer%40latest&arg=--templates&arg=~%2F.legal-doc-analyzer%2Ftemplates&arg=--db-path&arg=~%2F.legal-doc-analyzer%2Flegal.db&id=paralegal&name=Paralegal%20Assistant&description=A%20MCP%20server%20analyzes%20legal%20documents%2C%20extract%20key%20clauses%2C%20summarize%20content%2C%20and%20highlight%20potential%20risks%20for%20automated%20legal%20workflows." class="install-btn">➕ Install Extension</a>
    </div>
    
    <div class="card">
        <span class="tag">Finance & Operations</span>
        <h3>Real Estate Assistant</h3>
        <p>A MCP server that gives AI agents unified access to U.S. real-estate data, including property records, valuations, and market insights for analysis and automation.</p>
        <div class="cmd-preview">uvx --from real-estate-data-mcp-server real-estate-server</div>
        <a href="goose://extension?cmd=uvx&id=realestateassistant&name=Real%20Estate%20Assistant&description=A%20MCP%20server%20that%20gives%20AI%20agents%20unified%20access%20to%20U.S.%20real-estate%20data%2C%20including%20property%20records%2C%20valuations%2C%20and%20market%20insights%20for%20analysis%20and%20automation.&arg=--from&arg=real-estate-data-mcp-server&arg=real-estate-server" class="install-btn">➕ Install Extension</a>
    </div>
    
    <div class="card">
        <span class="tag">Finance & Operations</span>
        <h3>Job Market Analyst</h3>
        <p>A MCP server providing global labor-market data, including unemployment rates, wages, sector employment, and occupation outlooks using official BLS (US) and Eurostat (EU) APIs.</p>
        <div class="cmd-preview">uvx --from labor-market-mcp-server labor-market-server</div>
        <a href="goose://extension?cmd=uvx&id=jobmarketanalyst&name=Job%20Market%20Analyst&description=A%20MCP%20server%20providing%20global%20labor-market%20data%2C%20including%20unemployment%20rates%2C%20wages%2C%20sector%20employment%2C%20and%20occupation%20outlooks%20using%20official%20BLS%20%28US%29%20and%20Eurostat%20%28EU%29%20APIs.&arg=--from&arg=labor-market-mcp-server&arg=labor-market-server" class="install-btn">➕ Install Extension</a>
    </div>
    
    <div class="card">
        <span class="tag">Search & Research</span>
        <h3>Crossref Research Assistant</h3>
        <p>A MCP server that lets AI agents query Crossref for academic metadata, including DOIs, authors, journals, citations, and publication records for research automation.</p>
        <div class="cmd-preview">uvx --from crossref-academic-mcp-server crossref-server</div>
        <a href="goose://extension?cmd=uvx&id=crossrefresearchassistant&name=Crossref%20Research%20Assistant&description=A%20MCP%20server%20that%20lets%20AI%20agents%20query%20Crossref%20for%20academic%20metadata%2C%20including%20DOIs%2C%20authors%2C%20journals%2C%20citations%2C%20and%20publication%20records%20for%20research%20automation.&arg=--from&arg=crossref-academic-mcp-server&arg=crossref-server" class="install-btn">➕ Install Extension</a>
    </div>
    
    <div class="card">
        <span class="tag">Supply Chain & Logistics</span>
        <h3>Supply-Chain Agent</h3>
        <p>A lightweight MCP server providing structured access to logistics workflows—shipments, tracking, routing, and supply-chain operations—for AI agents and automation.</p>
        <div class="cmd-preview">uvx logistics_ai_mcp</div>
        <a href="goose://extension?cmd=uvx&id=supply-chain-agent&name=Supply-Chain%20Agent&description=A%20lightweight%20MCP%20server%20providing%20structured%20access%20to%20logistics%20workflows%E2%80%94shipments%2C%20tracking%2C%20routing%2C%20and%20supply-chain%20operations%E2%80%94for%20AI%20agents%20and%20automation.&arg=logistics_ai_mcp" class="install-btn">➕ Install Extension</a>
    </div>
    
    
    <div class="card">
        <span class="tag">Data & Utilities</span>
        <h3>Weather</h3>
        <p>Global weather, forecasts, air quality and historical climate data (Open-Meteo). No API key required for Open-Meteo; supports uvx-based install.</p>
        <div class="cmd-preview">uvx weather-mcp-server</div>
        <a href="goose://extension?cmd=uvx&id=weather&name=Weather%20MCP%20Server&description=Global%20weather%2C%20forecasts%2C%20air%20quality%20and%20historical%20climate%20data%20(Open-Meteo).&arg=weather-mcp-server&env=OPENWEATHER_API_KEY%3DOPENWEATHER_API_KEY" class="install-btn">➕ Install Extension</a>
    </div>

    <div class="card">
        <span class="tag">Search & Research</span>
        <h3>Research</h3>
        <p>Multi-source research MCP server: DuckDuckGo, Wikipedia, arXiv and Crossref — useful for autonomous literature and fact‑finding workflows.</p>
        <div class="cmd-preview">uvx research-automation-mcp-server</div>
        <a href="goose://extension?cmd=uvx&id=research-automation&name=Research%20Automation&description=Multi-source%20research%20MCP%20server%3A%20DuckDuckGo%2C%20Wikipedia%2C%20arXiv%20and%20Crossref.&arg=research-automation-mcp-server" class="install-btn">➕ Install Extension</a>
    </div>
    
   <div class="card">
        <span class="tag">Media & Productivity</span>
        <h3>News Aggregator</h3>
        <p>Aggregates trending topics from Reddit, HackerNews and global news sources for monitoring and summarization workflows.</p>
        <div class="cmd-preview">uvx news-aggregator-mcp-server</div>
        <a href="goose://extension?cmd=uvx&id=news-aggregator&name=News%20Aggregator&description=Aggregates%20trending%20topics%20from%20Reddit%2C%20HackerNews%20and%20global%20news%20sources.&arg=news-aggregator-mcp-server" class="install-btn">➕ Install Extension</a>
    </div>

    <div class="card">
        <span class="tag">Media & Productivity</span>
        <h3>Email Server</h3>
        <p>A MCP server that performs IMAP/SMTP email operations with Claude, Cursor, and other AI assistants.</p>
        <div class="cmd-preview">npx -y mcp-mail-server</div>
        <a href="goose://extension?cmd=npx&arg=-y&arg=mcp-mail-server&id=emailserver&name=Email%20Server&description=A%20MCP%20server%20that%20performs%20IMAP%2FSMTP%20email%20operations%20with%20Claude%2C%20Cursor%2C%20and%20other%20AI%20assistants.&env=IMAP_HOST%3DIMAP%20server%20address%20(e.g.%20imap.gmail.com)&env=IMAP_PORT%3DIMAP%20port%20number%20(e.g.%20993)&env=IMAP_SECURE%3DEnable%20TLS%20(e.g.%20true)&env=SMTP_HOST%3DSMTP%20server%20address%20(e.g.%20smtp.gmail.com)&env=SMTP_PORT%3DSMTP%20port%20number%09(e.g.%20465)&env=SMTP_SECURE%3DEnable%20SSL%20(e.g.%20true)&env=EMAIL_USER%3DEmail%20username%20(e.g.%20your-email%40gmail.com)&env=EMAIL_PASS%3DEmail%20password%2Fapp%20password" class="install-btn">➕ Install Extension</a>
    </div>

   <div class="card">
        <span class="tag">Media & Productivity</span>
        <h3>Calendar</h3>
        <p>A CalDAV MCP server to expose calendar operations as tools for AI assistants.</p>
        <div class="cmd-preview">npx -y caldav-mcp</div>
        <a href="goose://extension?cmd=npx&arg=-y&arg=caldav-mcp&id=calendar&name=Calendar&description=A%20CalDAV%20MCP%20server%20to%20expose%20calendar%20operations%20as%20tools%20for%20AI%20assistants.&env=CALDAV_BASE_URL%3DCalDAV%20Server%20URL&env=CALDAV_USERNAME%3DCalDAV%20username&env=CALDAV_PASSWORD%3DCalDAV%20password" class="install-btn">➕ Install Extension</a>
    </div>

    <div class="card">
        <span class="tag">Agent Infrastructure</span>
        <h3>Agent Directory</h3>
        <p>Service discovery and registry for AI agents and MCP servers; useful for multi-agent orchestration and discovery.</p>
        <div class="cmd-preview">uvx --from agent-directory-mcp-server agent-directory-server</div>
        <a href="goose://extension?cmd=uvx&arg=--from&arg=agent-directory-mcp-server&arg=agent-directory-server&id=agentdirectory&name=Agent%20Directory&description=Service%20discovery%20and%20registry%20for%20AI%20agents%20and%20MCP%20servers%3B%20useful%20for%20multi-agent%20orchestration%20and%20discovery." class="install-btn">➕ Install Extension</a>
    </div>

    <div class="card">
        <span class="tag">Agent Infrastructure</span>
        <h3>Agent Memory</h3>
        <p>Persistent memory for agents — store, retrieve and search knowledge across sessions to support long-running agent workflows.</p>
        <div class="cmd-preview">uvx --from agent-memory-mcp-server agent-memory-server</div>
        <a href="goose://extension?cmd=uvx&arg=--from&arg=agent-memory-mcp-server&arg=agent-memory-server&id=agentmemory&name=Agent%20Memory&description=Persistent%20memory%20for%20agents%20-%20store%2C%20retrieve%20and%20search%20knowledge%20across%20sessions." class="install-btn">➕ Install Extension</a>
    </div>

    <div class="card">
        <span class="tag">Search & Research</span>
        <h3>Patents</h3>
        <p>Access US patent data, search patents, citations and trends via the PatentsView API for IP research and analysis.</p>
        <div class="cmd-preview">uvx patent-intelligence-mcp-server</div>
        <a href="goose://extension?cmd=uvx&id=patent-intel&name=Patent%20Intelligence&description=Access%20US%20patent%20data%2C%20search%20patents%2C%20citations%20and%20trends%20via%20PatentsView.&arg=patent-intelligence-mcp-server" class="install-btn">➕ Install Extension</a>
    </div>

    <div class="card">
        <span class="tag">Data & Utilities</span>
        <h3>Space</h3>
        <p>NASA and astronomy data: exoplanets, Mars rover telemetry, asteroid info and Earth imagery for science workflows.</p>
        <div class="cmd-preview">uvx space-mcp-server</div>
        <a href="goose://extension?cmd=uvx&id=space-data&name=Space%20Data&description=NASA%20and%20astronomy%20data%3A%20exoplanets%2C%20Mars%20rovers%2C%20asteroids%20and%20Earth%20imagery.&arg=space-mcp-server" class="install-btn">➕ Install Extension</a>
    </div>

    <div class="card">
        <span class="tag">Healthcare & Biotechnology</span>
        <h3>OpenFoodFacts</h3>
        <p>Food product database lookup for nutrition and ingredients information via OpenFoodFacts.</p>
        <div class="cmd-preview">uvx openfoodfacts-mcp-server</div>
        <a href="goose://extension?cmd=uvx&id=openfoodfacts&name=OpenFoodFacts&description=Food%20product%20database%20lookup%20for%20nutrition%20and%20ingredients%20information.&arg=openfoodfacts-mcp-server" class="install-btn">➕ Install Extension</a>
    </div>

    <div class="card">
        <span class="tag">Healthcare & Biotechnology</span>
        <h3>Nutrition</h3>
        <p>USDA FoodData Central integration: foods, nutrients and dietary analysis for nutrition workflows.</p>
        <div class="cmd-preview">uvx nutrition-mcp-server</div>
        <a href="goose://extension?cmd=uvx&id=nutrition&name=Nutrition%20MCP%20Server&description=USDA%20FoodData%20Central%20integration%20for%20foods%2C%20nutrients%20and%20dietary%20analysis.&arg=nutrition-mcp-server" class="install-btn">➕ Install Extension</a>
    </div>

    <div class="card">
        <span class="tag">Media & Productivity</span>
        <h3>Documents</h3>
        <p>Local PDF & DOCX intelligence: text extraction, table detection, metadata and language detection (no cloud).</p>
        <div class="cmd-preview">uvx document-intelligence-mcp</div>
        <a href="goose://extension?cmd=uvx&id=document-intelligence&name=Document%20Intelligence&description=Local%20PDF%20%26%20DOCX%20intelligence%3A%20text%20extraction%2C%20table%20detection%2C%20metadata%20and%20language%20detection.&arg=document-intelligence-mcp" class="install-btn">➕ Install Extension</a>
    </div>

    <div class="card">
        <span class="tag">Media & Productivity</span>
        <h3>Nano Banana</h3>
        <p>A production-ready MCP server that provides AI-powered image generation capabilities through Google's Gemini models with intelligent model selection.</p>
        <div class="cmd-preview">uvx nanobanana-mcp-server@latest</div>
        <a href="goose://extension?cmd=uvx&arg=nanobanana-mcp-server%40latest&id=nanobanana&name=Nano%20Banana&description=A%20production-ready%20MCP%20server%20that%20provides%20AI-powered%20image%20generation%20capabilities%20through%20Google's%20Gemini%20models%20with%20intelligent%20model%20selection.&env=GEMINI_API_KEY%3Dgemini-api-key" class="install-btn">➕ Install Extension</a>
    </div>

    <div class="card">
        <span class="tag">Media & Productivity</span>
        <h3>NotebookLLM</h3>
        <p>A Unified CLI and MCP server for Google NotebookLM.</p>
        <div class="cmd-preview">uvx --from notebooklm-mcp-cli notebooklm-mcp</div>
        <a href="goose://extension?cmd=uvx&arg=--from&arg=notebooklm-mcp-cli&arg=notebooklm-mcp&id=notebooklm-mcp&name=NotebookLLM&description=A%20Unified%20CLI%20and%20MCP%20server%20for%20Google%20NotebookLM." class="install-btn">➕ Install Extension</a>
    </div>
    
    <div class="card">
        <span class="tag">Data & Utilities</span>
        <h3>Germany</h3>
        <p>German public data: traffic, DWD weather & warnings, Bundestag, energy, pollen and Destatis statistics (no API key required).</p>
        <div class="cmd-preview">uvx germany-mcp-server</div>
        <a href="goose://extension?cmd=uvx&id=germany&name=Germany&description=German%20public%20data%3A%20traffic%2C%20DWD%20weather%20%26%20warnings%2C%20Bundestag%2C%20energy%2C%20pollen%20and%20Destatis%20statistics.&arg=germany-mcp-server" class="install-btn">➕ Install Extension</a>
    </div>




    </div>



## 🧠 Agent Skills
<p>Run these commands in your terminal to install these specialized skills into Goose.</p>
<div class="grid">

    <div class="card">
        <div>
            <span class="tag skill">Legal Services</span>
            <span class="tag skill" style="background-color: #ffdce0; color: #22863a; border-color: #22863a;">Skill</span>
        </div>
        <h3>OpenAgreements</h3>
        <p>AI-assisted system for generating clear, consistent drafts of common legal documents and routine contracts.</p>
        <div class="cmd-preview">npx skills add open-agreements/open-agreements -y --agent goose cline</div>
    </div>
    
    <div class="card">
        <div>
            <span class="tag skill">Healthcare & Biotechnology</span>
            <span class="tag skill" style="background-color: #ffdce0; color: #22863a; border-color: #22863a;">Skill</span>
        </div>
        <h3>BioMCP</h3>
        <p>Search and retrieve biomedical data - genes, variants, clinical trials, and phenotype-disease matching.</p>
        <div class="cmd-preview">npx skills add genomoncology/biomcp -y --agent goose cline</div>
    </div>
    
    <div class="card">
        <div>
            <span class="tag skill">Smart Home / IoT</span>
            <span class="tag skill" style="background-color: #ffdce0; color: #22863a; border-color: #22863a;">Skill</span>
        </div>
        <h3>Home Assistant</h3>
        <p>Everything you need to know to build, test and review Home Assistant Integrations.</p>
        <div class="cmd-preview">npx skills add home-assistant/core integrations -y --agent goose cline</div>
    </div>
    
    <div class="card">
        <div>
            <span class="tag skill">Development & Engineering</span>
            <span class="tag skill" style="background-color: #ffdce0; color: #22863a; border-color: #22863a;">Skill</span>
        </div>
        <h3>Gooseworks (Local)</h3>
        <p>Portable visual skill pack for the Agent Skills ecosystem.</p>
        <div class="cmd-preview">npx -y skills add gooseworks-ai/goose-skills</div>
    </div>
    
    <div class="card">
        <div>
            <span class="tag skill">Media & Productivity</span>
            <span class="tag skill" style="background-color: #ffdce0; color: #22863a; border-color: #22863a;">Skill</span>
        </div>
        <h3>Gemini Workspace</h3>
        <p>Google Workspace Extension for Gemini CLI.</p>
        <div class="cmd-preview">npx skills add gemini-cli-extensions/workspace -y --agent goose cline</div>
    </div>
    
    <div class="card">
        <div>
            <span class="tag skill">Development & Engineering</span>
            <span class="tag skill" style="background-color: #ffdce0; color: #22863a; border-color: #22863a;">Skill</span>
        </div>
        <h3>Chrome DevTools</h3>
        <p>Uses Chrome DevTools via MCP for efficient debugging, troubleshooting and browser automation.</p>
        <div class="cmd-preview">npx skills add ChromeDevTools/chrome-devtools-mcp -y --agent goose cline</div>
    </div>
    
    <div class="card">
        <div>
            <span class="tag skill">Search & Research</span>
            <span class="tag skill" style="background-color: #ffdce0; color: #22863a; border-color: #22863a;">Skill</span>
        </div>
        <h3>Exa Labs Search</h3>
        <p>Deep research powered by Exa. Use for lead generation, literature reviews, deep dives, competitive analysis.</p>
        <div class="cmd-preview">npx skills add exa-labs/exa-mcp-server -y --agent goose cline</div>
    </div>
    
    <div class="card">
        <div>
            <span class="tag skill">Agent Infrastructure</span>
            <span class="tag skill" style="background-color: #ffdce0; color: #22863a; border-color: #22863a;">Skill</span>
        </div>
        <h3>HuggingFace Skills</h3>
        <p>Hugging Face Hub CLI (hf) for downloading, uploading, and managing models, datasets, spaces, buckets.</p>
        <div class="cmd-preview">npx skills add huggingface/skills -y --agent goose cline</div>
    </div>
    
    <div class="card">
        <div>
            <span class="tag skill">Agent Infrastructure</span>
            <span class="tag skill" style="background-color: #ffdce0; color: #22863a; border-color: #22863a;">Skill</span>
        </div>
        <h3>OpenClaw Security</h3>
        <p>Security-first vetting for OpenClaw skills. Use before installing any skill from ClawHub, GitHub.</p>
        <div class="cmd-preview">npx skills add UseAI-pro/openclaw-skills-security -y --agent goose cline</div>
    </div>
    
    <div class="card">
        <div>
            <span class="tag skill">Finance & Operations</span>
            <span class="tag skill" style="background-color: #ffdce0; color: #22863a; border-color: #22863a;">Skill</span>
        </div>
        <h3>Finance Skills</h3>
        <p>Financial analyst agent skill. Ratio analysis, DCF valuation, budget variance, rolling forecasts.</p>
        <div class="cmd-preview">npx skills add JoelLewis/finance_skills -y --agent goose cline</div>
    </div>
    
    <div class="card">
        <div>
            <span class="tag skill">Development & Engineering</span>
            <span class="tag skill" style="background-color: #ffdce0; color: #22863a; border-color: #22863a;">Skill</span>
        </div>
        <h3>Product Manager</h3>
        <p>Product Management skills for agents.</p>
        <div class="cmd-preview">npx skills add deanpeters/product-manager-skills -y --agent goose cline</div>
    </div>
    
    <div class="card">
        <div>
            <span class="tag skill">Supply Chain & Logistics</span>
            <span class="tag skill" style="background-color: #ffdce0; color: #22863a; border-color: #22863a;">Skill</span>
        </div>
        <h3>Supply Chain Optimizer</h3>
        <p>Supply chain and logistics optimization skills.</p>
        <div class="cmd-preview">npx skills add heymoezy/porter --skill logistics-optimizer supply-chain-optimizer -y --agent goose cline</div>
    </div>
    
    <div class="card">
        <div>
            <span class="tag skill">Development & Engineering</span>
            <span class="tag skill" style="background-color: #ffdce0; color: #22863a; border-color: #22863a;">Skill</span>
        </div>
        <h3>Stack Overflow for Agents</h3>
        <p>Interact with Stack Overflow for Agents: authenticate, search validated knowledge, read context pages.</p>
        <div class="cmd-preview">npx skills add https://agents.stackoverflow.com/ --skill sofa --yes --agent goose cline</div>
    </div>
    </div>
