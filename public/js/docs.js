/* Documentation JS — sidebar toggle, search, collapsible sections */

(function() {
  'use strict';

  // ── Collapsible sidebar sections ──
  document.querySelectorAll('.docs-sidebar-heading').forEach(function(heading) {
    heading.addEventListener('click', function() {
      this.classList.toggle('collapsed');
      var links = this.nextElementSibling;
      if (links && links.classList.contains('docs-sidebar-links')) {
        links.classList.toggle('collapsed');
      }
    });
  });

  // ── Client-side search ──
  var searchInput = document.getElementById('docs-search-input');
  var searchResults = document.getElementById('docs-search-results');
  var searchIndex = null;

  if (searchInput && searchResults) {
    // Load search index
    fetch('/static/docs/_search_index.json')
      .then(function(r) { return r.json(); })
      .then(function(data) { searchIndex = data; })
      .catch(function() { /* search won't work, that's ok */ });

    searchInput.addEventListener('input', function() {
      var query = this.value.trim().toLowerCase();
      if (!query || !searchIndex) {
        searchResults.classList.remove('active');
        searchResults.innerHTML = '';
        return;
      }

      var results = searchIndex.filter(function(entry) {
        if (entry.title.toLowerCase().indexOf(query) !== -1) return true;
        if (entry.description && entry.description.toLowerCase().indexOf(query) !== -1) return true;
        if (entry.headings) {
          for (var i = 0; i < entry.headings.length; i++) {
            if (entry.headings[i].toLowerCase().indexOf(query) !== -1) return true;
          }
        }
        return false;
      }).slice(0, 10);

      if (results.length === 0) {
        searchResults.innerHTML = '<div class="docs-search-result" style="cursor:default">No results found</div>';
        searchResults.classList.add('active');
        return;
      }

      // Determine if we're on /learn or /docs
      var basePath = window.location.pathname.startsWith('/learn') ? '/learn/' : '/docs/';

      searchResults.innerHTML = results.map(function(r) {
        return '<a class="docs-search-result" href="' + basePath + r.path + '">' +
          '<span>' + escapeHtml(r.title) + '</span>' +
          (r.section ? '<span class="docs-search-result-section">' + escapeHtml(r.section) + '</span>' : '') +
          '</a>';
      }).join('');
      searchResults.classList.add('active');
    });

    // Hide results on click outside
    document.addEventListener('click', function(e) {
      if (!searchInput.contains(e.target) && !searchResults.contains(e.target)) {
        searchResults.classList.remove('active');
      }
    });

    // Navigate results with keyboard
    searchInput.addEventListener('keydown', function(e) {
      if (e.key === 'Escape') {
        searchResults.classList.remove('active');
        searchInput.blur();
      }
    });
  }

  function escapeHtml(text) {
    var div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  // ── Scroll spy — highlight current section in sidebar ──
  var headings = document.querySelectorAll('.docs-article h2[id], .docs-article h3[id]');
  if (headings.length > 0) {
    // Lightweight scroll tracking — no IntersectionObserver needed
    // Just scroll the active sidebar item into view on load
    var activeLink = document.querySelector('.docs-sidebar-links a.active');
    if (activeLink) {
      activeLink.scrollIntoView({ block: 'center', behavior: 'auto' });
    }
  }
})();
