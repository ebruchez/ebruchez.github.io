const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
const carouselRegistry = new Map();

function getScrollBehavior() {
  return reducedMotion.matches ? 'instant' : 'smooth';
}

function getTargetScrollLeft(track, slide) {
  return slide.offsetLeft + slide.offsetWidth / 2 - track.clientWidth / 2;
}

function getNearestIndex(track, slides) {
  const trackCenter = track.scrollLeft + track.clientWidth / 2;
  let bestIdx = 0;
  let bestDist = Infinity;
  for (let i = 0; i < slides.length; i++) {
    const slide = slides[i];
    const slideCenter = slide.offsetLeft + slide.offsetWidth / 2;
    const dist = Math.abs(slideCenter - trackCenter);
    if (dist < bestDist) {
      bestDist = dist;
      bestIdx = i;
    }
  }
  return bestIdx;
}

function initCarousel(root) {
  const track = root.querySelector('.post-carousel-track');
  const slides = Array.from(root.querySelectorAll('.post-carousel-slide'));
  const markers = Array.from(root.querySelectorAll('.post-carousel-marker'));
  const prevBtn = root.querySelector('[data-direction="previous"]');
  const nextBtn = root.querySelector('[data-direction="next"]');
  const statusEl = root.querySelector('.post-carousel-status');
  const supportsScrollEnd = Boolean(track && 'onscrollend' in track);

  if (!track || slides.length === 0) return;

  let activeMarkerIdx = 0;
  let settledIdx = 0;
  let pendingIdx = null;
  let settleTimer = null;
  let rafId = null;

  function announceSlide(idx) {
    if (!statusEl) return;
    const label = slides[idx]?.getAttribute('data-slide-label') || '';
    statusEl.textContent = label
      ? `Slide ${idx + 1} of ${slides.length}: ${label}`
      : `Slide ${idx + 1} of ${slides.length}`;
  }

  function applyMarkerState(idx) {
    if (idx === activeMarkerIdx && markers[idx]?.getAttribute('aria-current') === 'true') {
      return;
    }
    activeMarkerIdx = idx;
    for (let i = 0; i < markers.length; i++) {
      if (i === idx) {
        markers[i].setAttribute('aria-current', 'true');
      } else {
        markers[i].removeAttribute('aria-current');
      }
    }
  }

  function applyButtonState(idx) {
    if (prevBtn) {
      prevBtn.setAttribute('aria-disabled', String(idx <= 0));
    }
    if (nextBtn) {
      nextBtn.setAttribute('aria-disabled', String(idx >= slides.length - 1));
    }
  }

  function clearSettleTimer() {
    if (settleTimer !== null) {
      clearTimeout(settleTimer);
      settleTimer = null;
    }
  }

  function settle(announce) {
    const idx = getNearestIndex(track, slides);
    if (pendingIdx !== null && Math.abs(track.scrollLeft - getTargetScrollLeft(track, slides[pendingIdx])) > 4) {
      return;
    }
    pendingIdx = null;
    clearSettleTimer();
    applyMarkerState(idx);
    applyButtonState(idx);

    if (idx !== settledIdx) {
      settledIdx = idx;
      if (announce) {
        announceSlide(idx);
      }
    }
  }

  function scheduleFallbackSettle(delayMs, announce) {
    clearSettleTimer();
    settleTimer = setTimeout(() => {
      settleTimer = null;
      pendingIdx = null;
      settle(announce);
    }, delayMs);
  }

  function scrollToIndex(targetIdx, behavior, announce = true) {
    if (targetIdx < 0 || targetIdx >= slides.length) return;
    const targetLeft = getTargetScrollLeft(track, slides[targetIdx]);

    applyMarkerState(targetIdx);
    applyButtonState(targetIdx);

    if (behavior === 'instant' || Math.abs(track.scrollLeft - targetLeft) < 1) {
      pendingIdx = null;
      clearSettleTimer();
      const prevScrollBehavior = track.style.scrollBehavior;
      track.style.scrollBehavior = 'auto';
      track.scrollLeft = targetLeft;
      track.style.scrollBehavior = prevScrollBehavior;
      if (targetIdx !== settledIdx) {
        settledIdx = targetIdx;
        if (announce) {
          announceSlide(targetIdx);
        }
      }
      return;
    }

    pendingIdx = targetIdx;
    scheduleFallbackSettle(450, announce);
    track.scrollTo({ left: targetLeft, behavior: 'smooth' });
  }

  prevBtn?.addEventListener('click', () => {
    if (prevBtn.getAttribute('aria-disabled') === 'true') return;
    const base = pendingIdx !== null ? pendingIdx : getNearestIndex(track, slides);
    if (base > 0) {
      scrollToIndex(base - 1, getScrollBehavior(), true);
    }
  });

  nextBtn?.addEventListener('click', () => {
    if (nextBtn.getAttribute('aria-disabled') === 'true') return;
    const base = pendingIdx !== null ? pendingIdx : getNearestIndex(track, slides);
    if (base < slides.length - 1) {
      scrollToIndex(base + 1, getScrollBehavior(), true);
    }
  });

  for (let i = 0; i < markers.length; i++) {
    markers[i].addEventListener('click', () => {
      scrollToIndex(i, getScrollBehavior(), true);
    });
  }

  track.addEventListener(
    'scroll',
    () => {
      if (pendingIdx === null && rafId === null) {
        rafId = requestAnimationFrame(() => {
          rafId = null;
          if (pendingIdx === null) {
            const idx = getNearestIndex(track, slides);
            applyMarkerState(idx);
            applyButtonState(idx);
          }
        });
      }

      if (!supportsScrollEnd || pendingIdx !== null) {
        scheduleFallbackSettle(150, true);
      }
    },
    { passive: true }
  );

  if (supportsScrollEnd) {
    track.addEventListener(
      'scrollend',
      () => {
        settle(true);
      },
      { passive: true }
    );
  }

  const initialIdx = getNearestIndex(track, slides);
  settledIdx = initialIdx;
  applyMarkerState(initialIdx);
  applyButtonState(initialIdx);

  carouselRegistry.set(root, { slides, scrollToIndex });
}

let lightboxSynced = false;
function bindLightboxSync() {
  if (lightboxSynced) return;
  const lb = window.Lightbox3?.Lightbox?.instance;
  if (!lb || typeof lb.on !== 'function') return;
  lightboxSynced = true;

  lb.on('navigate', ({ triggerEl }) => {
    if (!(triggerEl instanceof Element)) return;
    const slide = triggerEl.closest('.post-carousel-slide');
    const root = slide?.closest('.post-carousel');
    if (!slide || !root) return;
    const entry = carouselRegistry.get(root);
    if (!entry) return;
    const idx = entry.slides.indexOf(slide);
    if (idx >= 0) {
      if ('previouslyFocusedEl' in lb) {
        lb.previouslyFocusedEl = triggerEl;
      }
      entry.scrollToIndex(idx, 'instant', false);
    }
  });
}

for (const el of document.querySelectorAll('.post-carousel')) {
  initCarousel(el);
}

bindLightboxSync();
if (!lightboxSynced) {
  window.addEventListener('DOMContentLoaded', bindLightboxSync, { once: true });
  document.addEventListener('click', bindLightboxSync, { capture: true });
}
