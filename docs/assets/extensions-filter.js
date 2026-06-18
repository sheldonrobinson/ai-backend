document.addEventListener('DOMContentLoaded', function() {
  // Collect all cards across both extensions and skills sections
  const cards = Array.from(document.querySelectorAll('.card'));

  // Build set of categories (from .tag elements)
  const categories = new Set();
  cards.forEach(card => {
    const tags = Array.from(card.querySelectorAll('.tag'))
      .map(t => t.innerText.trim())
      .filter(Boolean);
    tags.forEach(t => categories.add(t));
  });

  // Populate selector if present
  const selector = document.getElementById('category-filter');
  if (!selector) return;

  // Add categories sorted
  Array.from(categories).sort().forEach(cat => {
    const opt = document.createElement('option');
    opt.value = cat;
    opt.textContent = cat;
    selector.appendChild(opt);
  });

  // Filtering function: show cards that have any tag matching the selected value
  function applyFilter() {
    const val = selector.value;
    cards.forEach(card => {
      const tags = Array.from(card.querySelectorAll('.tag')).map(t => t.innerText.trim());
      if (val === 'All' || tags.some(t => t === val)) {
        card.style.display = '';
      } else {
        card.style.display = 'none';
      }
    });
  }

  selector.addEventListener('change', applyFilter);
});