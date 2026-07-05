const STORAGE_KEY = 'gec-a11y';
const ZOOM_MIN = 0.85;
const ZOOM_MAX = 1.6;
const ZOOM_STEP = 0.1;

const srStatus = document.getElementById('sr-status');

const loadState = () => {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return { zoom: 1, highContrast: false };
    const parsed = JSON.parse(raw);
    return {
      zoom: typeof parsed.zoom === 'number' ? parsed.zoom : 1,
      highContrast: !!parsed.highContrast,
    };
  } catch {
    return { zoom: 1, highContrast: false };
  }
};

const saveState = (state) => {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  } catch {
    // ignore write failures (private mode, quota, etc.)
  }
};

const clampZoom = (zoom) => Math.round(Math.min(ZOOM_MAX, Math.max(ZOOM_MIN, zoom)) * 100) / 100;

export function initAccessibility(refs, onChange) {
  const { mainEl, hcToggle, iconOff, iconOn, zoomDec, zoomInc, zoomLabel } = refs;
  let state = loadState();

  const apply = () => {
    document.body.dataset.hc = state.highContrast ? 'on' : 'off';
    mainEl.style.zoom = state.zoom;
    mainEl.style.setProperty('--user-zoom', state.zoom);
    zoomLabel.textContent = `${Math.round(state.zoom * 100)}%`;
    iconOff.style.display = state.highContrast ? 'none' : '';
    iconOn.style.display = state.highContrast ? '' : 'none';
    hcToggle.setAttribute('aria-pressed', String(state.highContrast));
    if (onChange) onChange();
  };

  const update = (patch) => {
    state = { ...state, ...patch };
    saveState(state);
    apply();
  };

  hcToggle.addEventListener('click', () => update({ highContrast: !state.highContrast }));
  zoomDec.addEventListener('click', () => update({ zoom: clampZoom(state.zoom - ZOOM_STEP) }));
  zoomInc.addEventListener('click', () => update({ zoom: clampZoom(state.zoom + ZOOM_STEP) }));

  document.querySelector('.gec-info-focus')?.addEventListener('click', () => {
    document.querySelector('.mv-gec-info')?.focus();
  });

  apply();
}

export function announce(text) {
  if (!srStatus) return;
  srStatus.textContent = '';
  setTimeout(() => { srStatus.textContent = text; }, 50);
}
