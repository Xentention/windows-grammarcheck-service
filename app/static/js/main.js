import { correctText } from './api.js';
import { initAccessibility } from './accessibility.js';

const mainEl = document.querySelector('.app-main');
const hcToggle = document.getElementById('hc-toggle');
const iconOff = hcToggle.querySelector('[data-icon-off]');
const iconOn = hcToggle.querySelector('[data-icon-on]');
const zoomDec = document.getElementById('zoom-dec');
const zoomInc = document.getElementById('zoom-inc');
const zoomLabel = document.getElementById('zoom-label');

const clearBtn = document.getElementById('clear-btn');
const correctBtn = document.getElementById('correct-btn');
const correctSpinner = document.getElementById('correct-spinner');
const correctLabel = document.getElementById('correct-label');
const inputText = document.getElementById('input-text');
const errorCard = document.getElementById('error-card');
const errorText = document.getElementById('error-text');
const copyBtn = document.getElementById('copy-btn');
const outputBody = document.getElementById('output-body');
const elapsedTime = document.getElementById('elapsed-time');

let busy = false;
let lastCorrectedText = '';
let copyRevertTimer = null;

const autosize = () => {
  inputText.style.height = 'auto';
  inputText.style.height = `${Math.max(120, inputText.scrollHeight)}px`;
};

const updateCorrectAvailability = () => {
  correctBtn.disabled = busy || !inputText.value.trim();
};

const renderOutput = (corrected) => {
  outputBody.textContent = corrected;
};

const setElapsedTime = (elapsedStr) => {
  elapsedTime.textContent = `Время: ${elapsedStr}`;
  elapsedTime.hidden = false;
};

const setBusyUi = (isBusy) => {
  correctSpinner.hidden = !isBusy;
  correctLabel.textContent = isBusy ? 'Исправляю…' : 'Исправить';
  updateCorrectAvailability();
};

const onCorrect = async () => {
  const text = inputText.value.trim();
  if (!text || busy) return;

  busy = true;
  setBusyUi(true);
  errorCard.hidden = true;
  errorText.textContent = '';
  clearBtn.tabIndex = 0;
  copyBtn.tabIndex = 0;

  try {
    const { corrected, elapsedStr } = await correctText(text);
    lastCorrectedText = corrected;
    const noChange = corrected.trim() === text.trim();
    renderOutput(corrected);
    setElapsedTime(elapsedStr, noChange);
    copyBtn.disabled = false;
    clearBtn.tabIndex = -1;

  } catch (err) {
    errorText.textContent = err.message;
    errorCard.hidden = false;
  } finally {
    busy = false;
    setBusyUi(false);
  }
};

const onClear = () => {
  inputText.value = '';
  autosize();
  errorCard.hidden = true;
  outputBody.textContent = '';
  elapsedTime.hidden = true;
  elapsedTime.textContent = '';
  copyBtn.disabled = true;
  lastCorrectedText = '';
  clearBtn.tabIndex = 0;
  copyBtn.tabIndex = 0;
  updateCorrectAvailability();
};

const flashCopied = () => {
  copyBtn.title = 'Скопировано';
  clearTimeout(copyRevertTimer);
  copyRevertTimer = setTimeout(() => {
    copyBtn.title = 'Копировать';
  }, 1600);
};

const fallbackCopy = (text) => {
  const ta = document.createElement('textarea');
  ta.value = text;
  ta.style.position = 'fixed';
  ta.style.opacity = '0';
  document.body.appendChild(ta);
  ta.select();
  document.execCommand('copy');
  document.body.removeChild(ta);
  flashCopied();
};

const onCopy = () => {
  if (copyBtn.disabled || !lastCorrectedText) return;
  if (navigator.clipboard?.writeText) {
    navigator.clipboard.writeText(lastCorrectedText).then(flashCopied).catch(() => fallbackCopy(lastCorrectedText));
  } else {
    fallbackCopy(lastCorrectedText);
  }
};

inputText.addEventListener('input', autosize);
inputText.addEventListener('input', updateCorrectAvailability);
inputText.addEventListener('keydown', (e) => {
  if (e.key === 'Enter' && e.shiftKey) {
    e.preventDefault();
    correctBtn.click();
  }
});
correctBtn.addEventListener('click', onCorrect);
clearBtn.addEventListener('click', onClear);
copyBtn.addEventListener('click', onCopy);

copyBtn.addEventListener('keydown', (e) => {
  if (e.key === 'Tab' && !e.shiftKey) {
    e.preventDefault();
    copyBtn.tabIndex = -1;
    clearBtn.focus();
  }
});

window.addEventListener('resize', autosize);

autosize();
updateCorrectAvailability();

initAccessibility({ mainEl, hcToggle, iconOff, iconOn, zoomDec, zoomInc, zoomLabel }, autosize);
