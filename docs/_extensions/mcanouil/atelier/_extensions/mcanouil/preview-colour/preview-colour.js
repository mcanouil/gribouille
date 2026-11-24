/**
 * Preview Colour Extension - copy the colour of a mark to the clipboard
 *
 * @author Mickaël Canouil
 *
 * Each mark is a button that holds its colour in `data-colour`. One listener
 * on the document handles every mark. The result of the copy is shown in a
 * short tooltip, and is also written to one polite live region, so that a
 * screen reader announces it. The live region exists before the first copy,
 * because a screen reader can miss a region that is added and filled at the
 * same time.
 */

(() => {
  const TOOLTIP_DURATION = 1500;
  const STATUS_DURATION = 3000;
  const STATUS_DELAY = 100;
  let liveRegion = null;
  let liveRegionTimer = null;

  const createLiveRegion = () => {
    liveRegion = document.createElement('div');
    liveRegion.className = 'preview-colour-status';
    liveRegion.setAttribute('role', 'status');
    liveRegion.setAttribute('aria-live', 'polite');
    document.body.appendChild(liveRegion);
  };

  const announce = (message) => {
    clearTimeout(liveRegionTimer);
    liveRegion.textContent = '';
    liveRegionTimer = setTimeout(() => {
      liveRegion.textContent = message;
      liveRegionTimer = setTimeout(() => {
        liveRegion.textContent = '';
      }, STATUS_DURATION);
    }, STATUS_DELAY);
  };

  const tooltipTimers = new WeakMap();

  // The stylesheet draws the tooltip from `data-tooltip`, so it is not an
  // element inside the code, where a theme rule such as `code span` reaches it.
  const showTooltip = (mark, message) => {
    clearTimeout(tooltipTimers.get(mark));
    mark.dataset.tooltip = message;
    tooltipTimers.set(
      mark,
      setTimeout(() => delete mark.dataset.tooltip, TOOLTIP_DURATION),
    );
  };

  const report = (mark, value, copied) => {
    showTooltip(mark, copied ? 'Copied!' : 'Copy failed');
    announce(copied ? `Copied ${value}` : `Could not copy ${value}`);
  };

  const copy = async (mark) => {
    const value = mark.dataset.colour;
    try {
      await navigator.clipboard.writeText(value);
    } catch (error) {
      console.error(`preview-colour: could not copy "${value}" to the clipboard.`, error);
      report(mark, value, false);
      return;
    }
    report(mark, value, true);
  };

  const init = () => {
    createLiveRegion();
    document.addEventListener('click', (event) => {
      const mark = event.target.closest?.('button.preview-colour');
      if (!mark) return;
      // A mark can sit inside a link, and a copy must not also follow it.
      event.preventDefault();
      copy(mark);
    });
    // Reveal.js reads Space and Enter on the document to change slides. The
    // capture listener keeps them on the mark, so they press the button.
    document.addEventListener(
      'keydown',
      (event) => {
        if ((event.key === ' ' || event.key === 'Enter') && event.target.closest?.('button.preview-colour')) {
          event.stopPropagation();
        }
      },
      true,
    );
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
