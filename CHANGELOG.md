# Changelog

## Unreleased

- feat: `compose()` accepts composition-level `labs` (title/subtitle/caption) and `alt`, and now controls the collected legend's side through `guides` (e.g. `guides(default: guide-legend(position: "bottom"))`); the `guides-placement` parameter is removed. (#22)
- feat: `guides()` accepts a `default` entry that sets fallback guide options (such as the legend side) inherited by every aesthetic without its own override, in both `plot()` and `compose()`; `guide-legend`'s `position` now defaults to `auto` and inherits from it. (#21)
- feat: `compose()` gains `width`/`height` (filling a bounded container by default) and relative `widths`/`heights` to size panels against the canvas rather than their own declared dimensions. (#20)
- fix: the `compose` collected legend placed on `top` or `bottom` no longer clips its first swatch and is centred under the panels. (#19)
- docs: callout headers now sit on the type tint as a distinct band while the body uses the plain surface, and caution gets its own deeper mustard so it no longer matches warning. (#16)
- docs: tabset (panel-tabset) labels now follow the light/dark theme; the active tab label uses the brand primary colour in both schemes. (#15)
- docs: the development version is now downloadable from the dev documentation site and installable as a local package; release, Typst Universe, and development archives share an identical payload. (#14)
- feat: `element-text()`/`element-typst()` gain an `align` parameter setting per-surface text alignment, independent of the container; title and subtitle default left, caption right, axis titles and strip text centred. (#13)
- feat: `labs()` fields default to `auto`; pass `none` to suppress an axis or legend title and reclaim the space it reserved. (#12)
- feat: `element-blank()` on a text surface (axis, plot, or legend title) collapses the space the text would reserve. (#12)
- feat: `width`/`height` accept `auto` to fill the available space of a bounded container. (#10)
- fix: `width`/`height` now bound the whole image, including title, subtitle, caption, and plot-background padding; the data panel shrinks to fit and long titles wrap. (b53fab2)

## 0.1.1 (2026-05-22)

- fix: centre collected `compose` side legends against the panel grid. (994c9e8)
- fix: apply plot background inset/outset even without a fill. (2f24982)
- docs: enable llms.txt output for the documentation site. (6b05d6a)
- docs: add a navbar version switcher between the stable and development docs. (95c3d9b)

## 0.1.0 (2026-05-20)

- feat: initial version of Gribouille.
