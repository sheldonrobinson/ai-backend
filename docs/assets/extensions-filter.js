document.addEventListener('DOMContentLoaded', function() {
  const cards = Array.from(document.querySelectorAll('.card'));
  const selector = document.getElementById('category-filter');
  if (!selector) return;

  // Ordered categories requested
  const orderedCategories = [
    'All',
    'Finance & Operations',
    'Development & Engineering',
    'Media & Productivity',
    'Search & Research',
    'Healthcare & Biotechnology',
    'Legal Services',
    'Supply Chain & Logistics',
    'Data & Utilities',
    'Agent Infrastructure'
  ];

  // Mapping rules (lowercase substrings -> category)
  const mappingRules = [
    { keywords: ['finance', 'real-estate', 'fred', 'trading', 'job market', 'job', 'labor'], category: 'Finance & Operations' },
    { keywords: ['dev', 'development', 'engineer', 'git', 'shadcn', 'chrome devtools', 'product manager'], category: 'Development & Engineering' },
    { keywords: ['media', 'social', 'bluesky', 'mastodon', 'linkedin', 'news', 'content', 'gemini', 'workspace'], category: 'Media & Productivity' },
    { keywords: ['search', 'research', 'crossref', 'open websearch', 'duckduckgo', 'arxiv', 'research', 'exa'], category: 'Search & Research' },
    { keywords: ['health', 'nutrition', 'bio', 'biotech', 'biomcp', 'healthcare'], category: 'Healthcare & Biotechnology' },
    { keywords: ['legal', 'court', 'judicial', 'agreements', 'patent', 'patents'], category: 'Legal Services' },
    { keywords: ['supply', 'logistics', 'shipment', 'supply-chain', 'logistics'], category: 'Supply Chain & Logistics' },
    { keywords: ['data', 'excel', 'document', 'openfoodfacts', 'weather', 'fred', 'data & utilities', 'utilities'], category: 'Data & Utilities' },
    { keywords: ['agent', 'directory', 'mcp hub', 'agent-directory', 'agent-directory', 'agent memory', 'agent memory', 'infrastructure'], category: 'Agent Infrastructure' }
  ];

  // Helper: derive primary categories for a card based on its tag texts
  function deriveCategoriesFromTags(tagTexts) {
    const lower = tagTexts.map(t => t.toLowerCase());
    const found = new Set();
    mappingRules.forEach(rule => {
      rule.keywords.forEach(kw => {
        lower.forEach(lt => {
          if (lt.includes(kw)) found.add(rule.category);
        });
      });
    });
    // Fallback: if no mapping found, include the original tag(s)
    if (found.size === 0) {
      tagTexts.forEach(t => found.add(t));
    }
    return Array.from(found);
  }

  // Populate selector with ordered list
  orderedCategories.forEach(cat => {
    const opt = document.createElement('option');
    opt.value = cat;
    opt.textContent = cat;
    selector.appendChild(opt);
  });

  // Attach computed categories to cards
  cards.forEach(card => {
    const tagNodes = Array.from(card.querySelectorAll('.tag'));
    const tagTexts = tagNodes.map(n => n.innerText.trim()).filter(Boolean);
    const cats = deriveCategoriesFromTags(tagTexts);
    card.dataset.cats = cats.join('||');
  });

  // Insert a no-results message placeholder
  const noResults = document.createElement('div');
  noResults.id = 'extensions-no-results';
  noResults.style.display = 'none';
  noResults.style.marginTop = '12px';
  noResults.style.fontStyle = 'italic';
  noResults.textContent = 'No extensions or skills found for this category.';
  selector.parentNode.insertBefore(noResults, selector.nextSibling);

  function applyFilter() {
    const val = selector.value;
    let visibleCount = 0;
    cards.forEach(card => {
      const cats = (card.dataset.cats || '').split('||').map(s => s.trim()).filter(Boolean);
      if (val === 'All' || cats.includes(val)) {
        card.style.display = '';
        visibleCount++;
      } else {
        card.style.display = 'none';
      }
    });
    noResults.style.display = (visibleCount === 0) ? '' : 'none';
  }

  selector.addEventListener('change', applyFilter);
});