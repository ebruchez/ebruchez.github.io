(() => {
  'use strict';

  const grid = document.getElementById('tw-grid');
  if (!grid) return;

  const cards = Array.from(grid.querySelectorAll('.tw-card'));
  const bucketTabs = Array.from(document.querySelectorAll('.tw-bucket-tab'));
  const searchInput = document.getElementById('tw-search');
  const brandSelect = document.getElementById('tw-filter-brand');
  const decadeSelect = document.getElementById('tw-filter-decade');
  const typeSelect = document.getElementById('tw-filter-type');
  const statusSelect = document.getElementById('tw-filter-status');
  const sortSelect = document.getElementById('tw-sort');
  const countEl = document.getElementById('tw-result-count');
  const resetBtn = document.getElementById('tw-reset-filters');
  const emptyEl = document.getElementById('tw-empty-state');

  let activeBucket = 'collection';

  function readQueryParams() {
    const params = new URLSearchParams(window.location.search);
    if (params.has('bucket')) {
      const b = params.get('bucket');
      if (bucketTabs.some((t) => t.dataset.twBucket === b)) {
        activeBucket = b;
      }
    }
    if (params.has('q') && searchInput) searchInput.value = params.get('q');
    if (params.has('brand') && brandSelect) brandSelect.value = params.get('brand');
    if (params.has('decade') && decadeSelect) decadeSelect.value = params.get('decade');
    if (params.has('type') && typeSelect) typeSelect.value = params.get('type');
    if (params.has('status') && statusSelect) statusSelect.value = params.get('status');
    if (params.has('sort') && sortSelect) sortSelect.value = params.get('sort');
  }

  function syncQueryParams() {
    const params = new URLSearchParams();
    if (activeBucket !== 'collection') params.set('bucket', activeBucket);
    if (searchInput && searchInput.value.trim()) params.set('q', searchInput.value.trim());
    if (brandSelect && brandSelect.value) params.set('brand', brandSelect.value);
    if (decadeSelect && decadeSelect.value) params.set('decade', decadeSelect.value);
    if (typeSelect && typeSelect.value) params.set('type', typeSelect.value);
    if (statusSelect && statusSelect.value) params.set('status', statusSelect.value);
    if (sortSelect && sortSelect.value !== 'brand') params.set('sort', sortSelect.value);

    const qs = params.toString();
    const newUrl = qs ? `${window.location.pathname}?${qs}` : window.location.pathname;
    window.history.replaceState(null, '', newUrl);
  }

  function updateBucketUI() {
    bucketTabs.forEach((tab) => {
      const isActive = tab.dataset.twBucket === activeBucket;
      tab.classList.toggle('is-active', isActive);
      tab.setAttribute('aria-selected', isActive ? 'true' : 'false');
    });
  }

  function sortCards() {
    const mode = sortSelect ? sortSelect.value : 'brand';
    const sorted = [...cards].sort((a, b) => {
      switch (mode) {
        case 'year_asc': {
          const ya = parseInt(a.dataset.year || '9999', 10);
          const yb = parseInt(b.dataset.year || '9999', 10);
          if (ya !== yb) return ya - yb;
          return (a.dataset.sortBrand || '').localeCompare(b.dataset.sortBrand || '');
        }
        case 'year_desc': {
          const ya = parseInt(a.dataset.year || '0', 10);
          const yb = parseInt(b.dataset.year || '0', 10);
          const na = ya === 9999 ? -1 : ya;
          const nb = yb === 9999 ? -1 : yb;
          if (na !== nb) return nb - na;
          return (a.dataset.sortBrand || '').localeCompare(b.dataset.sortBrand || '');
        }
        case 'updated': {
          const ua = a.dataset.updated || '';
          const ub = b.dataset.updated || '';
          if (ua !== ub) return ub.localeCompare(ua);
          return (a.dataset.sortBrand || '').localeCompare(b.dataset.sortBrand || '');
        }
        case 'photos': {
          const pa = parseInt(a.dataset.photos || '0', 10);
          const pb = parseInt(b.dataset.photos || '0', 10);
          if (pa !== pb) return pb - pa;
          return (a.dataset.sortBrand || '').localeCompare(b.dataset.sortBrand || '');
        }
        default:
          return (a.dataset.sortBrand || '').localeCompare(b.dataset.sortBrand || '');
      }
    });

    const frag = document.createDocumentFragment();
    sorted.forEach((c) => frag.appendChild(c));
    grid.appendChild(frag);
  }

  function applyFilters() {
    const query = (searchInput ? searchInput.value : '').trim().toLowerCase();
    const tokens = query ? query.split(/\s+/) : [];
    const brand = brandSelect ? brandSelect.value : '';
    const decade = decadeSelect ? decadeSelect.value : '';
    const mtype = typeSelect ? typeSelect.value : '';
    const status = statusSelect ? statusSelect.value : '';

    let visible = 0;
    let bucketTotal = 0;

    cards.forEach((card) => {
      const inBucket = activeBucket === 'all' || card.dataset.bucket === activeBucket;
      if (inBucket) bucketTotal += 1;

      let match = inBucket;
      if (match && brand && card.dataset.brand !== brand) match = false;
      if (match && decade && card.dataset.decade !== decade) match = false;
      if (match && mtype && card.dataset.type !== mtype) match = false;
      if (match && status && card.dataset.status !== status) match = false;
      if (match && tokens.length > 0) {
        const hay = card.dataset.search || '';
        for (const tok of tokens) {
          if (!hay.includes(tok)) {
            match = false;
            break;
          }
        }
      }

      card.hidden = !match;
      if (match) visible += 1;
    });

    const hasActiveFilters = Boolean(query || brand || decade || mtype || status);
    if (countEl) {
      countEl.textContent = hasActiveFilters
        ? `Showing ${visible} of ${bucketTotal} machines`
        : `Showing ${visible} ${visible === 1 ? 'machine' : 'machines'}`;
    }
    if (resetBtn) resetBtn.hidden = !hasActiveFilters;
    if (emptyEl) emptyEl.hidden = visible > 0;

    syncQueryParams();
  }

  bucketTabs.forEach((tab) => {
    tab.addEventListener('click', () => {
      activeBucket = tab.dataset.twBucket;
      updateBucketUI();
      applyFilters();
    });
  });

  if (searchInput) searchInput.addEventListener('input', applyFilters);
  if (brandSelect) brandSelect.addEventListener('change', applyFilters);
  if (decadeSelect) decadeSelect.addEventListener('change', applyFilters);
  if (typeSelect) typeSelect.addEventListener('change', applyFilters);
  if (statusSelect) statusSelect.addEventListener('change', applyFilters);
  if (sortSelect) {
    sortSelect.addEventListener('change', () => {
      sortCards();
      applyFilters();
    });
  }

  if (resetBtn) {
    resetBtn.addEventListener('click', () => {
      if (searchInput) searchInput.value = '';
      if (brandSelect) brandSelect.value = '';
      if (decadeSelect) decadeSelect.value = '';
      if (typeSelect) typeSelect.value = '';
      if (statusSelect) statusSelect.value = '';
      applyFilters();
    });
  }

  readQueryParams();
  updateBucketUI();
  sortCards();
  applyFilters();
})();
