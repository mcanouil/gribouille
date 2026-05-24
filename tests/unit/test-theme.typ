// theme() stores element records verbatim; merge-theme overlays them on the
// defaults.

#import "../../src/theme/theme.typ": _text-style, resolve-element, theme
#import "../../src/theme/elements.typ": (
  element-blank, element-line, element-rect, element-text,
)
#import "../../src/theme/defaults.typ": merge-theme

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

// tick-length scalar cascade: side > axis > base.
#import "../../src/theme/theme.typ": _scalar-cascade
#let len-base = merge-theme(theme(tick-length: 0.3cm))
#assert.eq(_scalar-cascade(len-base, "tick-length", "x-bottom", "x"), 0.3cm)
#assert.eq(_scalar-cascade(len-base, "tick-length", "y-right", "y"), 0.3cm)

#let len-axis = merge-theme(theme(
  tick-length: 0.1cm,
  tick-length-x: 0.4cm,
))
#assert.eq(_scalar-cascade(len-axis, "tick-length", "x-bottom", "x"), 0.4cm)
#assert.eq(_scalar-cascade(len-axis, "tick-length", "x-top", "x"), 0.4cm)
#assert.eq(_scalar-cascade(len-axis, "tick-length", "y-left", "y"), 0.1cm)

#let len-side = merge-theme(theme(
  tick-length: 0.1cm,
  tick-length-x: 0.2cm,
  tick-length-x-bottom: 0.5cm,
))
#assert.eq(_scalar-cascade(len-side, "tick-length", "x-bottom", "x"), 0.5cm)
#assert.eq(_scalar-cascade(len-side, "tick-length", "x-top", "x"), 0.2cm)
#assert.eq(_scalar-cascade(len-side, "tick-length", "y-right", "y"), 0.1cm)

// element-blank on a text surface collapses to a 0pt size so every consumer
// that gates on `size > 0pt` skips both the ink and its reserved space.
#let blank-title = merge-theme(theme(axis-title: element-blank()))
#assert.eq(_text-style(blank-title, "axis-title").size, 0pt)
#let blank-plot-title = merge-theme(theme(plot-title: element-blank()))
#assert.eq(_text-style(blank-plot-title, "plot-title").size, 0pt)
// A normal text element keeps its declared size.
#assert.eq(_text-style(merge-theme(theme()), "axis-title").size, 9pt)

Theme tests passed.
