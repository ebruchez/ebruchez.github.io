/*
 * Standalone client-side interactions for blog.bruchez.name
 * Zero external dependencies.
 */
(() => {
  'use strict';

  const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
  const sysDarkPrefers = window.matchMedia('(prefers-color-scheme: dark)');

  /* --------------------------------------------------------------------------
   * 1. Color Scheme Toggle & Persistence (localStorage + <meta name="color-scheme">)
   * -------------------------------------------------------------------------- */
  const SCHEME_KEY = 'color-scheme';
  const metaScheme = document.querySelector('meta[name="color-scheme"]');
  const modeToggleBtn = document.querySelector('.mode-toggle');

  function getStoredScheme() {
    try {
      const val = localStorage.getItem(SCHEME_KEY);
      return val === 'light' || val === 'dark' ? val : null;
    } catch {
      return null;
    }
  }

  function getRenderedScheme() {
    const stored = getStoredScheme();
    if (stored) return stored;
    const htmlMode = document.documentElement.getAttribute('mode');
    if (htmlMode === 'light' || htmlMode === 'dark') return htmlMode;
    return sysDarkPrefers.matches ? 'dark' : 'light';
  }

  function applySchemeState(stored) {
    if (stored === 'light' || stored === 'dark') {
      if (metaScheme) metaScheme.content = stored;
      document.documentElement.setAttribute('mode', stored);
    } else {
      if (metaScheme) metaScheme.content = 'light dark';
      document.documentElement.removeAttribute('mode');
    }
    syncModeToggleLabel();
    window.dispatchEvent(new CustomEvent('themechange', { detail: { scheme: getRenderedScheme() } }));
  }

  function syncModeToggleLabel() {
    if (!modeToggleBtn) return;
    const next = getRenderedScheme() === 'dark' ? 'light' : 'dark';
    const label = `Switch to ${next} color scheme`;
    modeToggleBtn.setAttribute('aria-label', label);
    modeToggleBtn.setAttribute('title', label);
  }

  if (modeToggleBtn) {
    syncModeToggleLabel();
    modeToggleBtn.addEventListener('click', () => {
      const target = getRenderedScheme() === 'dark' ? 'light' : 'dark';
      const osCurrent = sysDarkPrefers.matches ? 'dark' : 'light';
      try {
        if (target === osCurrent) {
          localStorage.removeItem(SCHEME_KEY);
          applySchemeState(null);
        } else {
          localStorage.setItem(SCHEME_KEY, target);
          applySchemeState(target);
        }
      } catch {
        applySchemeState(target);
      }
    });
  }

  sysDarkPrefers.addEventListener('change', () => {
    syncModeToggleLabel();
    if (!getStoredScheme()) {
      window.dispatchEvent(new CustomEvent('themechange', { detail: { scheme: getRenderedScheme() } }));
    }
  });

  window.addEventListener('storage', (event) => {
    if (event.key === SCHEME_KEY) {
      const next = event.newValue === 'light' || event.newValue === 'dark' ? event.newValue : null;
      applySchemeState(next);
    }
  });

  /* --------------------------------------------------------------------------
   * 2. Mobile Sidebar Drawer
   * -------------------------------------------------------------------------- */
  const SIDEBAR_ATTR = 'sidebar-display';
  const sidebarTrigger = document.getElementById('sidebar-trigger');
  const mask = document.getElementById('mask');

  function setSidebarOpen(open) {
    if (open) {
      document.body.setAttribute(SIDEBAR_ATTR, '');
    } else {
      document.body.removeAttribute(SIDEBAR_ATTR);
    }
    if (sidebarTrigger) {
      sidebarTrigger.setAttribute('aria-expanded', String(open));
    }
  }

  sidebarTrigger?.addEventListener('click', () => {
    setSidebarOpen(!document.body.hasAttribute(SIDEBAR_ATTR));
  });

  mask?.addEventListener('click', () => {
    setSidebarOpen(false);
  });

  /* --------------------------------------------------------------------------
   * 3. Lazy On-Demand Site Search
   * -------------------------------------------------------------------------- */
  const searchTrigger = document.getElementById('search-trigger');
  const searchWrapper = document.getElementById('search-wrapper');
  const searchInput = document.getElementById('search-input');
  const searchCleaner = document.getElementById('search-cleaner');
  const searchCancel = document.getElementById('search-cancel');
  const topbarTitle = document.getElementById('topbar-title');
  const mainEl = document.getElementById('main');
  const resultWrapper = document.getElementById('search-result-wrapper');
  const resultsContainer = document.getElementById('search-results');

  let searchIndexPromise = null;
  let searchEntries = null;
  let savedScrollY = 0;
  let resultsVisible = false;

  function loadSearchIndex() {
    if (searchIndexPromise) return searchIndexPromise;
    const url = searchInput?.getAttribute('data-search-url') || '/assets/js/data/search.json';
    searchIndexPromise = fetch(url)
      .then((res) => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        return res.json();
      })
      .then((data) => {
        searchEntries = Array.isArray(data)
          ? data.map((item) => ({
              ...item,
              _titleLower: (item.title || '').toLowerCase(),
              _metaLower: `${item.categories || ''} ${item.tags || ''}`.toLowerCase(),
              _bodyLower: `${item.snippet || ''} ${item.body || ''}`.toLowerCase()
            }))
          : [];
        return searchEntries;
      })
      .catch(() => {
        searchIndexPromise = null;
        return null;
      });
    return searchIndexPromise;
  }

  function showResultsPanel() {
    if (resultsVisible || !resultWrapper || !mainEl) return;
    savedScrollY = window.scrollY;
    resultWrapper.classList.remove('unloaded');
    resultWrapper.style.display = 'flex';
    mainEl.classList.add('unloaded');
    window.scrollTo(0, 0);
    resultsVisible = true;
  }

  function hideResultsPanel() {
    if (!resultsVisible || !resultWrapper || !mainEl) return;
    if (resultsContainer) resultsContainer.textContent = '';
    resultWrapper.classList.add('unloaded');
    resultWrapper.style.display = '';
    mainEl.classList.remove('unloaded');
    resultsVisible = false;
    window.scrollTo(0, savedScrollY);
  }

  function openMobileSearch() {
    sidebarTrigger?.classList.add('unloaded');
    topbarTitle?.classList.add('unloaded');
    searchTrigger?.classList.add('unloaded');
    searchWrapper?.classList.add('d-flex', 'loaded');
    searchCancel?.classList.add('loaded');
    showResultsPanel();
    loadSearchIndex();
    searchInput?.focus();
  }

  function closeMobileSearch() {
    searchCancel?.classList.remove('loaded');
    searchWrapper?.classList.remove('d-flex', 'loaded');
    sidebarTrigger?.classList.remove('unloaded');
    topbarTitle?.classList.remove('unloaded');
    searchTrigger?.classList.remove('unloaded');
    if (searchInput) searchInput.value = '';
    searchCleaner?.classList.remove('visible');
    hideResultsPanel();
  }

  function isMobileSearchActive() {
    return Boolean(searchCancel?.classList.contains('loaded'));
  }

  function scoreEntry(entry, terms, fullPhrase) {
    let score = 0;
    for (const term of terms) {
      const inTitle = entry._titleLower.includes(term);
      const inMeta = entry._metaLower.includes(term);
      const inBody = entry._bodyLower.includes(term);
      if (!inTitle && !inMeta && !inBody) return 0;
      if (inTitle) score += 12;
      if (inMeta) score += 5;
      if (inBody) score += 2;
    }
    if (terms.length > 1 && entry._titleLower.includes(fullPhrase)) {
      score += 15;
    }
    if (entry._titleLower.startsWith(fullPhrase)) {
      score += 8;
    }
    return score;
  }

  function renderSearchResults(rawQuery) {
    if (!resultsContainer) return;
    const query = rawQuery.trim().toLowerCase();
    resultsContainer.textContent = '';

    if (!query) {
      if (!isMobileSearchActive()) {
        hideResultsPanel();
      }
      return;
    }

    showResultsPanel();

    if (!searchEntries) {
      const loading = document.createElement('p');
      loading.className = 'mt-5 text-muted';
      loading.textContent = 'Searching…';
      resultsContainer.appendChild(loading);
      loadSearchIndex().then((loaded) => {
        if (!loaded) {
          resultsContainer.textContent = '';
          const err = document.createElement('p');
          err.className = 'mt-5 text-muted';
          err.textContent = 'Search index could not be loaded.';
          resultsContainer.appendChild(err);
          return;
        }
        if (searchInput && searchInput.value.trim().toLowerCase() === query) {
          renderSearchResults(searchInput.value);
        }
      });
      return;
    }

    const terms = query.split(/\s+/).filter(Boolean);
    const matches = [];
    for (const entry of searchEntries) {
      const score = scoreEntry(entry, terms, query);
      if (score > 0) matches.push({ entry, score });
    }
    matches.sort((a, b) => b.score - a.score);

    const top = matches.slice(0, 24);
    if (top.length === 0) {
      const empty = document.createElement('p');
      empty.className = 'mt-5';
      empty.textContent = 'No matching posts or pages found.';
      resultsContainer.appendChild(empty);
      return;
    }

    const frag = document.createDocumentFragment();
    for (const { entry } of top) {
      const item = document.createElement('div');
      item.className = 'pl-1 pr-1 pl-sm-2 pr-sm-2 pl-lg-4 pr-lg-4 pl-xl-0 pr-xl-0';

      const link = document.createElement('a');
      link.href = entry.url;
      link.textContent = entry.title;
      item.appendChild(link);

      if (entry.categories || entry.tags || entry.date) {
        const meta = document.createElement('div');
        meta.className = 'post-meta d-flex flex-wrap text-muted mt-1 mb-1';

        if (entry.date) {
          const dateEl = document.createElement('div');
          dateEl.className = 'mr-3';
          const icon = document.createElement('i');
          icon.className = 'far fa-calendar fa-fw';
          icon.setAttribute('aria-hidden', 'true');
          dateEl.append(icon, ` ${entry.date}`);
          meta.appendChild(dateEl);
        }

        if (entry.categories) {
          const catEl = document.createElement('div');
          catEl.className = 'mr-3';
          const icon = document.createElement('i');
          icon.className = entry.type === 'page' ? 'far fa-bookmark fa-fw' : 'far fa-folder fa-fw';
          icon.setAttribute('aria-hidden', 'true');
          catEl.append(icon, ` ${entry.categories}`);
          meta.appendChild(catEl);
        }

        if (entry.tags) {
          const tagEl = document.createElement('div');
          const icon = document.createElement('i');
          icon.className = 'fa fa-tag fa-fw';
          icon.setAttribute('aria-hidden', 'true');
          tagEl.append(icon, ` ${entry.tags}`);
          meta.appendChild(tagEl);
        }

        item.appendChild(meta);
      }

      if (entry.snippet) {
        const snippet = document.createElement('p');
        snippet.textContent = entry.snippet;
        item.appendChild(snippet);
      }

      frag.appendChild(item);
    }
    resultsContainer.appendChild(frag);
  }

  if (searchInput) {
    searchInput.addEventListener('focus', () => {
      searchWrapper?.classList.add('input-focus');
      loadSearchIndex();
    });

    searchInput.addEventListener('blur', () => {
      searchWrapper?.classList.remove('input-focus');
    });

    searchInput.addEventListener('input', () => {
      const val = searchInput.value;
      if (val.length > 0) {
        searchCleaner?.classList.add('visible');
      } else {
        searchCleaner?.classList.remove('visible');
      }
      renderSearchResults(val);
    });
  }

  searchTrigger?.addEventListener('click', openMobileSearch);
  searchCancel?.addEventListener('click', closeMobileSearch);

  searchCleaner?.addEventListener('click', () => {
    if (!searchInput) return;
    searchInput.value = '';
    searchCleaner.classList.remove('visible');
    renderSearchResults('');
    searchInput.focus();
  });

  document.addEventListener('keydown', (event) => {
    if (event.key !== 'Escape') return;
    if (document.body.hasAttribute(SIDEBAR_ATTR)) {
      setSidebarOpen(false);
    } else if (isMobileSearchActive()) {
      closeMobileSearch();
    } else if (resultsVisible) {
      if (searchInput) searchInput.value = '';
      searchCleaner?.classList.remove('visible');
      hideResultsPanel();
      searchInput?.blur();
    }
  });

  /* --------------------------------------------------------------------------
   * 4. Table of Contents & Scrollspy
   * -------------------------------------------------------------------------- */
  const tocNav = document.getElementById('toc');
  if (tocNav) {
    const headings = Array.from(
      document.querySelectorAll('#post-wrapper .post-content :is(h2, h3)[id]:not([data-toc-skip])')
    );

    if (headings.length > 0) {
      const rootList = document.createElement('ul');
      rootList.className = 'toc-list';
      let currentSublist = null;

      for (const heading of headings) {
        if (!heading.hasAttribute('tabindex')) {
          heading.setAttribute('tabindex', '-1');
        }
        const li = document.createElement('li');
        const link = document.createElement('a');
        link.className = 'toc-link';
        link.href = `#${heading.id}`;
        link.textContent = (heading.textContent || '').trim();
        li.appendChild(link);

        if (heading.tagName === 'H2' || !currentSublist) {
          rootList.appendChild(li);
          if (heading.tagName === 'H2') {
            currentSublist = document.createElement('ul');
            currentSublist.className = 'toc-sublist';
            li.appendChild(currentSublist);
          }
        } else {
          currentSublist.appendChild(li);
        }
      }

      for (const emptyUl of rootList.querySelectorAll('ul.toc-sublist:empty')) {
        emptyUl.remove();
      }
      tocNav.appendChild(rootList);

      const tocLinks = Array.from(tocNav.querySelectorAll('a.toc-link'));
      const supportsScrollTargetGroup =
        typeof CSS !== 'undefined' && typeof CSS.supports === 'function' && CSS.supports('scroll-target-group: auto');

      if (supportsScrollTargetGroup) {
        const syncAriaCurrent = () => {
          const activeLink = tocNav.querySelector('a.toc-link:target-current');
          for (const link of tocLinks) {
            link.setAttribute('aria-current', link === activeLink ? 'true' : 'false');
          }
        };
        syncAriaCurrent();
        document.addEventListener('scrollend', syncAriaCurrent, { passive: true });
      } else if ('IntersectionObserver' in window) {
        const setActiveId = (id) => {
          const targetHref = `#${id}`;
          for (const link of tocLinks) {
            const isActive = link.getAttribute('href') === targetHref;
            link.classList.toggle('target-current', isActive);
            link.setAttribute('aria-current', String(isActive));
          }
        };

        setActiveId(headings[0].id);
        const observer = new IntersectionObserver(
          (entries) => {
            for (const entry of entries) {
              if (entry.isIntersecting) {
                setActiveId(entry.target.id);
              }
            }
          },
          { rootMargin: '-80px 0px -65% 0px', threshold: 0 }
        );
        for (const heading of headings) {
          observer.observe(heading);
        }
      }
    } else {
      document.getElementById('toc-wrapper')?.classList.add('unloaded');
    }
  }

  /* --------------------------------------------------------------------------
   * 5. Copy-Code & Copy-Link Buttons (Invoker Commands + Fallback)
   * -------------------------------------------------------------------------- */
  const copyTimers = new WeakMap();
  const originalIconClasses = new WeakMap();
  let lastAnnouncement = '';

  function legacyCopy(text) {
    const field = Object.assign(document.createElement('textarea'), { value: text });
    field.setAttribute('readonly', '');
    field.style.cssText = 'position:fixed;inset-block-start:0;opacity:0';
    document.body.appendChild(field);
    field.select();
    try {
      return document.execCommand('copy');
    } finally {
      field.remove();
    }
  }

  function reportCopy(button, ok) {
    const tip = button.nextElementSibling;
    const icon = button.querySelector('i');
    clearTimeout(copyTimers.get(button));

    if (icon && !originalIconClasses.has(button)) {
      originalIconClasses.set(button, icon.className);
    }

    button.removeAttribute('data-copied');
    button.removeAttribute('data-failed');

    let message = ok ? 'Copied' : 'Copy failed';
    if (message === lastAnnouncement) {
      message += '\u00A0';
    }
    lastAnnouncement = message;

    if (tip) tip.textContent = '';
    void button.offsetWidth;
    button.setAttribute(ok ? 'data-copied' : 'data-failed', '');
    if (icon) {
      icon.className = ok ? 'fas fa-check' : 'fas fa-exclamation-circle';
    }

    if (tip) {
      requestAnimationFrame(() => {
        tip.textContent = message;
      });
    }

    copyTimers.set(
      button,
      setTimeout(() => {
        button.removeAttribute('data-copied');
        button.removeAttribute('data-failed');
        if (tip) tip.textContent = '';
        if (icon && originalIconClasses.has(button)) {
          icon.className = originalIconClasses.get(button);
        }
      }, 2000)
    );
  }

  async function executeCopy(button, target, command) {
    let text = '';
    if (command === '--copy-url') {
      text = window.location.href;
    } else if (target) {
      text = target.matches('input, textarea') ? target.value : (target.innerText || target.textContent || '').replace(/\n$/, '');
    }
    if (!text) return;

    try {
      await navigator.clipboard.writeText(text);
      reportCopy(button, true);
    } catch {
      if (legacyCopy(text)) {
        reportCopy(button, true);
      } else {
        reportCopy(button, false);
      }
    }
  }

  if ('CommandEvent' in window) {
    document.addEventListener(
      'command',
      (event) => {
        if (typeof event.command === 'string' && event.command.startsWith('--copy')) {
          executeCopy(event.source, event.target, event.command);
        }
      },
      true
    );
  } else {
    document.addEventListener('click', (event) => {
      if (!(event.target instanceof Element)) return;
      const button = event.target.closest('button[command^="--copy"]');
      if (!button) return;
      const cmd = button.getAttribute('command') || '--copy';
      if (cmd === '--copy-url') {
        executeCopy(button, null, cmd);
      } else {
        const targetId = button.getAttribute('commandfor');
        const target = targetId ? document.getElementById(targetId) : null;
        if (target) executeCopy(button, target, cmd);
      }
    });
  }

  /* --------------------------------------------------------------------------
   * 6. Email Link
   * -------------------------------------------------------------------------- */
  document.addEventListener('click', (event) => {
    if (!(event.target instanceof Element)) return;

    const emailLink = event.target.closest('a[data-email-user][data-email-domain]');
    if (emailLink) {
      event.preventDefault();
      const user = emailLink.getAttribute('data-email-user');
      const domain = emailLink.getAttribute('data-email-domain');
      if (user && domain) {
        window.location.href = `mailto:${user}@${domain}`;
      }
    }
  });
})();
