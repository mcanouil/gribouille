/**
* MIT License
*
* Copyright (c) 2026 Mickaël Canouil
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:

* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.

* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

// Map of supported output types to the Quarto-emitted class names.
const OUTPUT_TYPE_CLASSES = {
  stdout: 'cell-output-stdout',
  stderr: 'cell-output-stderr',
  display: 'cell-output-display',
  output: 'cell-output',
};

// Ordered output-type identifiers (first match wins during detection).
const OUTPUT_TYPE_ORDER = ['stdout', 'stderr', 'display', 'output'];

// Default summary text per output type.
const DEFAULT_TYPE_SUMMARIES = {
  stdout: 'Standard Output',
  stderr: 'Standard Error',
  display: 'Display Output',
  output: 'Code Output',
};

const DEFAULT_SUMMARY_TEMPLATE = '{type}';

/**
 * Parse a boolean from a data attribute. Accepts true/false/yes/no/1/0.
 * @param {string | null | undefined} value
 * @returns {boolean | null}
 */
function parseBoolean(value) {
  if (value === null || value === undefined || value === '') return null;
  const normalised = String(value).toLowerCase();
  if (normalised === 'true' || normalised === 'yes' || normalised === '1') return true;
  if (normalised === 'false' || normalised === 'no' || normalised === '0') return false;
  return null;
}

/**
 * Parse a non-negative integer from a data attribute.
 * @param {string | null | undefined} value
 * @returns {number | null}
 */
function parseInteger(value) {
  if (value === null || value === undefined || value === '') return null;
  const parsed = Number.parseInt(String(value), 10);
  if (Number.isNaN(parsed) || parsed < 0) return null;
  return parsed;
}

/**
 * Resolve the output-type key for an element by inspecting its class list.
 * @param {Element} element
 * @returns {string | null}
 */
function detectOutputType(element) {
  for (const key of OUTPUT_TYPE_ORDER) {
    if (element.classList.contains(OUTPUT_TYPE_CLASSES[key])) return key;
  }
  return null;
}

/**
 * Count the number of textual lines for an element.
 * @param {Element} element
 * @returns {number}
 */
function countLines(element) {
  const text = element.textContent || '';
  if (text.trim() === '') return 0;
  return text.split('\n').length;
}

/**
 * Render the summary text using the configured template and per-type overrides.
 * @param {string} outputType
 * @param {string | null} explicitSummary
 * @param {number} lineCount
 * @param {{ template: string, perType: Record<string, string> }} options
 * @returns {string}
 */
function renderSummary(outputType, explicitSummary, lineCount, options) {
  if (explicitSummary && explicitSummary !== '') return explicitSummary;
  const override = options.perType[outputType];
  if (override) return override;
  const label = DEFAULT_TYPE_SUMMARIES[outputType] || DEFAULT_TYPE_SUMMARIES.output;
  return (options.template || DEFAULT_SUMMARY_TEMPLATE)
    .replace(/\{type\}/g, label)
    .replace(/\{lines\}/g, String(lineCount));
}

/**
 * Wrap a single output element in a <details> block.
 * @param {Element} cell
 * @param {Element} output
 * @param {{ template: string, perType: Record<string, string>, open: boolean, autoCollapse: number | null }} options
 */
function wrapOutput(cell, output, options) {
  const outputType = detectOutputType(output);
  if (!outputType) return;

  const lineCount = countLines(output);
  const forceCollapsed = options.autoCollapse !== null && lineCount >= options.autoCollapse;

  const details = document.createElement('details');
  if (options.open && !forceCollapsed) details.open = true;

  const summary = document.createElement('summary');
  summary.textContent = renderSummary(
    outputType,
    cell.dataset.outputSummary || null,
    lineCount,
    options,
  );

  details.appendChild(summary);
  output.parentNode.insertBefore(details, output);
  details.appendChild(output);
}

document.addEventListener('DOMContentLoaded', () => {
  const cells = document.querySelectorAll('.cell[data-output-fold="true"]');

  cells.forEach((cell) => {
    const allowedTypes = (cell.dataset.outputTypes || 'stdout,stderr,display,output')
      .split(',')
      .map((part) => part.trim())
      .filter((part) => part.length > 0);

    const perType = {};
    for (const key of Object.keys(OUTPUT_TYPE_CLASSES)) {
      const attr = cell.dataset[`outputSummary${key.charAt(0).toUpperCase()}${key.slice(1)}`];
      if (attr) perType[key] = attr;
    }

    const options = {
      template: cell.dataset.outputSummaryTemplate || DEFAULT_SUMMARY_TEMPLATE,
      perType,
      open: parseBoolean(cell.dataset.outputOpen) === true,
      autoCollapse: parseInteger(cell.dataset.outputAutoCollapse),
    };

    const outputs = [];
    for (const key of allowedTypes) {
      const className = OUTPUT_TYPE_CLASSES[key];
      if (!className) continue;
      cell.querySelectorAll(`.${className}`).forEach((element) => {
        if (!outputs.includes(element)) outputs.push(element);
      });
    }

    outputs.forEach((output) => wrapOutput(cell, output, options));
  });
});
