NCBI_API_KEY="..."        # PubTator, PubMed/efetch, PMC OA, NCBI ID converter
S2_API_KEY="..."          # Optional Semantic Scholar auth; dedicated quota at 1 req/sec
OPENFDA_API_KEY="..."     # OpenFDA rate limits
NCI_API_KEY="..."         # NCI CTS trial search (--source nci)
ONCOKB_TOKEN="..."        # OncoKB variant helper
ALPHAGENOME_API_KEY="..." # AlphaGenome variant effect prediction
DISGENET_API_KEY="..."    # Enables scored DisGeNET sections on gene and disease lookups
OMIM_API_KEY="..."        # 

# SKILLS

{
  "is_builtin": false,
  "id": "shadcn",
  "name": "shadcn UI",
  "description": "A shadcn/ui–native MCP server enabling structured component metadata, actions, and UI-aware tooling for agent workflows.",
  "command": "npx -y shadcn@latest mcp",
  "environmentVariables": []
}

Include `cline` as `goose` is not standard compliance in `SKILL.md` install location.

legal-doc-analyzer
  -title: Legal Document Analyzer
  -desc: An MCP server analyzes legal documents, extract key clauses, summarize content, and highlight potential risks for automated legal workflows.
  -cmd: npx -y mcp-legal-doc-analyzer@latest --templates ~/.legal-doc-analyzer/templates --db-path ~/.legal-doc-analyzer/legal.db
  
OpenAgreements
  -skills: npx skills add open-agreements/open-agreements -y --agent goose cline
  -desc: An AI-assisted system for generating clear, consistent drafts of common legal documents and routine contracts.
  -mcp: https://openagreements.org/api/mcp

BioMCP
  - skills: npx skills add genomoncology/biomcp -y --agent goose cline
  - cmd: npx skills add genomoncology/biomcp -y --agent goose cline
  
home-assistant
  - skills: npx skills add home-assistant/core integrations -y --agent goose cline

gooseworks
  - https://skills.gooseworks.ai/
  - skills (cloud): npx gooseworks install --all
  - skills (local): npx -y skills add gooseworks-ai/goose-skills
 
google-workspace-extension-for-gemini-cli
  - https://www.geminicliextensions.com/
  - skills: npx skills add gemini-cli-extensions/workspace -y --agent goose cline
 
developer:
  -npx skills add ChromeDevTools/chrome-devtools-mcp -y --agent goose cline
npx skills add exa-labs/exa-mcp-server -y --agent goose cline
npx skills add huggingface/skills -y --agent goose cline

openclaw (mst useful for MacOS):
  - npx skills add openclaw/openclaw -y --agent goose cline --dangerously-accept-openclaw-risks

openclaw-security:  
  - npx skills add UseAI-pro/openclaw-skills-security -y --agent goose cline
npx skills add halthelobster/proactive-agent

npx skills add https://github.com/block/Agent-Skills -y --agent goose cline
npx skills add steipete/agent-scripts --skill agent-transcript create-cli nano-banana-pro video-transcript-downloader -y --agent goose cline

# Finance (JoelLewis/finance_skills)
npx skills add JoelLewis/finance_skills
npx skills add https://github.com/JoelLewis/finance_skills/tree/main/plugins/advisory-practice -y --agent goose cline
npx skills add https://github.com/JoelLewis/finance_skills/tree/main/plugins/client-operations/skills -y --agent goose cline
npx skills add https://github.com/JoelLewis/finance_skills/tree/main/plugins/compliance -y --agent goose cline
npx skills add https://github.com/JoelLewis/finance_skills/tree/main/plugins/core -y --agent goose cline
npx skills add https://github.com/JoelLewis/finance_skills/tree/main/plugins/data-integration -y --agent goose cline
npx skills add https://github.com/JoelLewis/finance_skills/tree/main/plugins/trading-operations -y --agent goose cline
npx skills add https://github.com/JoelLewis/finance_skills/tree/main/plugins/wealth-management -y --agent goose cline
npx skills add finskills/risk-manager -y --agent goose cline

# Collection
npx skills add alirezarezvani/claude-skills --agent goose cline

# Product Manager
npx skills add deanpeters/product-manager-skills -y --agent goose cline

# Supply-Chain
npx skills add heymoezy/porter --skill logistics-optimizer supply-chain-optimizer -y --agent goose cline

npx skills add heymoezy/porter --skill academic-researcher bibliographic-researcher literature-reviewer -y --agent goose cline

npx skills add https://agents.stackoverflow.com/ --skill sofa --yes --agent goose cline

# Alternative Markets
npx skills add debridge-finance/debridge-skills --agent goose cline 

# Goose Desktop Personal Essentials
npx skills add https://github.com/block/Agent-Skills --yes --agent goose cline
npx skills add https://github.com/modelcontextprotocol/ext-apps.git --yes --agent goose cline
npx skills add https://github.com/Aas-ee/open-webSearch --skill open-websearch --yes --agent goose cline