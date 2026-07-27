// theme() stores element records verbatim; merge-theme overlays them on the
// defaults.

#import "../../src/theme/theme.typ": (
  _line-stroke, _rect-style, _text-style, resolve-element, theme,
)
#import "../../src/theme/elements.typ": (
  element-blank, element-line, element-rect, element-text, element-tick,
)
#import "../../src/theme/defaults.typ": merge-theme
#import "../../src/theme/void.typ": theme-void

// Element records pass through verbatim.
#let t = theme(
  axis-text: element-text(size: 11pt),
  panel-background: element-rect(fill: rgb("#eeeeee")),
)
#assert.eq(t.axis-text.size, 11pt)
#assert.eq(t.panel-background.fill, rgb("#eeeeee"))

// Different sizing on a different surface.
#let t2 = theme(
  axis-text: element-text(size: 13pt),
  panel-background: element-rect(fill: rgb("#ff9900")),
)
#assert.eq(t2.axis-text.size, 13pt)
#assert.eq(t2.panel-background.fill, rgb("#ff9900"))

// Merging into the defaults produces a usable theme dict.
#let merged = merge-theme(t2)
#assert.eq(merged.axis-text.size, 13pt)
#assert.eq(merged.panel-background.fill, rgb("#ff9900"))

// axis-ticks: independent line surface, parented to `line`.
#let tt = merge-theme(theme(axis-ticks: element-line(stroke: 1.2pt)))
#assert.eq(tt.axis-ticks.stroke, 1.2pt)
#let resolved = resolve-element(tt, "axis-ticks")
#assert.eq(resolved.stroke, 1.2pt)

// axis-ticks inherits colour from the base `line` record, not from `axis-line`.
#let tt2 = merge-theme(theme(
  line: element-line(colour: rgb("#112233")),
  axis-line: element-line(colour: rgb("#aabbcc")),
))
#let r-ticks = resolve-element(tt2, "axis-ticks")
#assert.eq(r-ticks.colour, rgb("#112233"))
#let r-line = resolve-element(tt2, "axis-line")
#assert.eq(r-line.colour, rgb("#aabbcc"))

// element-blank on axis-ticks hides ticks while keeping the spine.
#let tt3 = merge-theme(theme(axis-ticks: element-blank()))
#let r-blank = resolve-element(tt3, "axis-ticks")
#assert.eq(r-blank.kind, "element-blank")

// Side-specific cascade — three levels deep: axis-text-x-bottom inherits
// from axis-text via axis-text-x.
#let s1 = merge-theme(theme(axis-text: element-text(size: 11pt)))
#let r-xb = resolve-element(s1, "axis-text-x-bottom")
#assert.eq(r-xb.size, 11pt)

// The most specific surface wins when multiple levels are set.
#let s2 = merge-theme(theme(
  axis-text: element-text(size: 11pt),
  axis-text-x: element-text(size: 12pt),
  axis-text-x-bottom: element-text(size: 13pt),
))
#assert.eq(resolve-element(s2, "axis-text-x-bottom").size, 13pt)
#assert.eq(resolve-element(s2, "axis-text-x-top").size, 12pt)
#assert.eq(resolve-element(s2, "axis-text-y-left").size, 11pt)

// Setting only the base `text` parent cascades through every axis variant.
#let s3 = merge-theme(theme(text: element-text(colour: rgb("#444444"))))
#assert.eq(
  resolve-element(s3, "axis-text-x-bottom").colour,
  rgb("#444444"),
)
#assert.eq(
  resolve-element(s3, "axis-title-y-right").colour,
  rgb("#444444"),
)

// element-blank on a side variant hides only that side.
#let s4 = merge-theme(theme(axis-line-y-right: element-blank()))
#assert.eq(resolve-element(s4, "axis-line-y-right").kind, "element-blank")
#assert(
  resolve-element(s4, "axis-line-y-left").at("kind", default: none)
    != "element-blank",
)

// axis-ticks side variants cascade from axis-ticks to every side.
#let s5 = merge-theme(theme(axis-ticks: element-line(stroke: 2pt)))
#assert.eq(resolve-element(s5, "axis-ticks-x-bottom").stroke, 2pt)
#assert.eq(resolve-element(s5, "axis-ticks-y-right").stroke, 2pt)

// Tick length cascade: side > axis > family.
#import "../../src/theme/theme.typ": _tick-length, default-tick-length
#let len-base = merge-theme(theme(axis-ticks: element-tick(length: 0.3cm)))
#assert.eq(_tick-length(len-base, "axis-ticks-x-bottom"), 0.3cm)
#assert.eq(_tick-length(len-base, "axis-ticks-y-right"), 0.3cm)

#let len-axis = merge-theme(theme(
  axis-ticks: element-tick(length: 0.1cm),
  axis-ticks-x: element-tick(length: 0.4cm),
))
#assert.eq(_tick-length(len-axis, "axis-ticks-x-bottom"), 0.4cm)
#assert.eq(_tick-length(len-axis, "axis-ticks-x-top"), 0.4cm)
#assert.eq(_tick-length(len-axis, "axis-ticks-y-left"), 0.1cm)

#let len-side = merge-theme(theme(
  axis-ticks: element-tick(length: 0.1cm),
  axis-ticks-x: element-tick(length: 0.2cm),
  axis-ticks-x-bottom: element-tick(length: 0.5cm),
))
#assert.eq(_tick-length(len-side, "axis-ticks-x-bottom"), 0.5cm)
#assert.eq(_tick-length(len-side, "axis-ticks-x-top"), 0.2cm)
#assert.eq(_tick-length(len-side, "axis-ticks-y-right"), 0.1cm)

// A ratio length scales the length inherited from the parent surface.
#assert.eq(
  _tick-length(
    merge-theme(theme(
      axis-ticks: element-tick(length: 0.3cm),
      axis-ticks-y: element-tick(length: 50%),
    )),
    "axis-ticks-y-left",
  ),
  0.15cm,
)

// Minor ticks default to half the resolved major length, per axis.
#let minor-default = merge-theme(theme(axis-ticks: element-tick(length: 0.4cm)))
#assert.eq(_tick-length(minor-default, "axis-ticks-minor-x"), 0.2cm)
#assert.eq(_tick-length(minor-default, "axis-ticks-minor-y"), 0.2cm)
#assert.eq(
  _tick-length(
    merge-theme(theme(axis-ticks-minor-y: element-tick(length: 0.05cm))),
    "axis-ticks-minor-y",
  ),
  0.05cm,
)
// Minor marks inherit the major stroke and colour unless overridden.
#let minor-inherit = merge-theme(theme(axis-ticks: element-tick(
  colour: rgb("#334455"),
  stroke: 0.8pt,
)))
#assert.eq(_line-stroke(minor-inherit, "axis-ticks-minor-x").thickness, 0.8pt)
#assert.eq(
  _line-stroke(minor-inherit, "axis-ticks-minor-x").paint,
  rgb("#334455"),
)

// element-blank is the single tick off switch: no stroke and no length, so
// nothing draws and no depth is reserved.
#let ticks-off = merge-theme(theme(axis-ticks-x-top: element-blank()))
#assert.eq(_tick-length(ticks-off, "axis-ticks-x-top"), 0cm)
#assert.eq(_line-stroke(ticks-off, "axis-ticks-x-top"), none)
#assert.eq(_tick-length(ticks-off, "axis-ticks-x-bottom"), 0.1cm)

// An element-line on a tick surface carries no length, so the cascade falls
// through to the default.
#assert.eq(
  _tick-length(
    merge-theme(theme(axis-ticks: element-line(stroke: 1pt))),
    "axis-ticks-y-left",
  ),
  default-tick-length,
)

// element-blank on a text surface collapses to a 0pt size so every consumer
// that gates on `size > 0pt` skips both the ink and its reserved space.
#let blank-title = merge-theme(theme(axis-title: element-blank()))
#assert.eq(_text-style(blank-title, "axis-title").size, 0pt)
#let blank-plot-title = merge-theme(theme(plot-title: element-blank()))
#assert.eq(_text-style(blank-plot-title, "plot-title").size, 0pt)
// A normal text element keeps its declared size.
#assert.eq(_text-style(merge-theme(theme()), "axis-title").size, 9pt)

// Tick labels hide per side: `axis-text` on one side collapses to 0pt while
// its siblings keep drawing.
#let blank-labels = merge-theme(theme(axis-text-y-right: element-blank()))
#assert.eq(_text-style(blank-labels, "axis-text-y-right").size, 0pt)
#assert.eq(_text-style(blank-labels, "axis-text-y-left").size, 8pt)
// theme-void hides every tick label through the same switch.
#assert.eq(
  _text-style(merge-theme(theme-void()), "axis-text-x-bottom").size,
  0pt,
)

// Relative `%` sizes cascade from the base `text`. At the default 9pt base the
// per-surface ratios resolve to the historical absolute sizes.
#let d0 = merge-theme(theme())
#assert.eq(_text-style(d0, "axis-title").size, 9pt)
#assert.eq(_text-style(d0, "axis-text").size, 8pt)
#assert.eq(_text-style(d0, "plot-title").size, 12pt)
// Setting the base `text` size rescales every ratio surface proportionally.
#let big = merge-theme(theme(text: element-text(size: 12pt)))
#assert.eq(_text-style(big, "axis-title").size, 12pt)
#assert.eq(_text-style(big, "axis-text").size, (8 / 9) * 12pt)
#assert.eq(_text-style(big, "plot-title").size, 16pt)
// An absolute surface size wins outright and ignores the base size.
#let abs-title = merge-theme(theme(
  text: element-text(size: 12pt),
  axis-title: element-text(size: 14pt),
))
#assert.eq(_text-style(abs-title, "axis-title").size, 14pt)
// A per-axis ratio resolves against its parent surface (nearest ancestor).
#let rel-side = merge-theme(theme(axis-text-x: element-text(size: 50%)))
#assert.eq(_text-style(rel-side, "axis-text-x-bottom").size, 4pt)
// theme-void keeps its absolute 0pt axis-title (collapsed surface).
#assert.eq(_text-style(merge-theme(theme-void()), "axis-title").size, 0pt)

// `angle` surfaces through `_text-style` and cascades to per-side surfaces,
// so axis-text rotation reaches the tick-label angle default.
#let angled = merge-theme(theme(axis-text: element-text(angle: 30deg)))
#assert.eq(_text-style(angled, "axis-text").angle, 30deg)
#assert.eq(_text-style(angled, "axis-text-x-bottom").angle, 30deg)
// Unset stays `none` so existing themes keep upright text.
#assert.eq(_text-style(merge-theme(theme()), "axis-text").angle, none)

// Relative `%` strokes cascade from the base `line`. At the default 0.5pt base
// the per-surface ratios resolve to the historical absolute thicknesses.
#assert.eq(_line-stroke(d0, "axis-line").thickness, 0.5pt)
#assert.eq(_line-stroke(d0, "legend-ticks").thickness, 0.3pt)
// Setting the base `line` stroke rescales every ratio surface proportionally.
#let thick = merge-theme(theme(line: element-line(stroke: 1pt)))
#assert.eq(_line-stroke(thick, "axis-line").thickness, 1pt)
#assert.eq(_line-stroke(thick, "legend-ticks").thickness, (0.3 / 0.5) * 1pt)
// An absolute surface stroke wins outright and ignores the base stroke.
#let abs-line = merge-theme(theme(
  line: element-line(stroke: 1pt),
  axis-line: element-line(stroke: 0.4pt),
))
#assert.eq(_line-stroke(abs-line, "axis-line").thickness, 0.4pt)
// A rect ratio stroke with no absolute ancestor resolves against the default
// thickness, so the historical legend-bar hairline survives.
#assert.eq(_rect-style(d0, "legend-bar").stroke.thickness, 0.2pt)
// Setting the base `rect` stroke anchors the ratio and rescales it.
#let thick-rect = merge-theme(theme(rect: element-rect(stroke: 1pt)))
#assert.eq(
  _rect-style(thick-rect, "legend-bar").stroke.thickness,
  (0.2 / 0.5) * 1pt,
)

Theme tests passed.
