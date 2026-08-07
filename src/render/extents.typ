// Axis label measurement: tick-label extents, depth/width geometry, title
// placement, and reserved secondary-axis extents used to size panel chrome.

#import "../utils/margin.typ": resolve-margin-side-cm
#import "../utils/typst-markup.typ": resolve-prose
#import "../utils/aes-resolve.typ": resolve-label
#import "../theme/theme.typ": _text-args
#import "../utils/measure.typ": longest-unbreakable-cm, measure-labels-cm
#import "../utils/palette.typ": spec-attr
#import "../utils/format.typ": format-break
#import "../scale/secondary.typ" as secondary-mod
#import "axis-format.typ": _axis-breaks, _axis-label, _secondary-breaks

// Convert the axis-text font size in pt to cm. Used as a fallback ink-height
// when no actual labels are measured (e.g., an axis with no breaks).
#let _ax-text-cm(size-pt) = size-pt / 1pt * 0.0353

// Map a horizontal-axis title alignment to its coordinate along the panel's
// x span (`lo`/`hi` are the left/right canvas x) and the cetz anchor that
// pins it there. `none` keeps the default of centred.
#let _x-title-place(align, lo, hi) = if align == left {
  (lo, "south-west")
} else if align == right {
  (hi, "south-east")
} else {
  ((lo + hi) / 2, "south")
}

// Same for a vertical-axis title; it is drawn rotated 90deg, so along its
// reading direction `left` is the panel bottom (`lo`) and `right` the top
// (`hi`). `none` keeps the default of centred.
#let _y-title-place(align, lo, hi) = if align == left {
  (lo, "south")
} else if align == right {
  (hi, "north")
} else {
  ((lo + hi) / 2, "center")
}

// Resolve a text style's rotation: the explicit `angle` field when the theme
// sets one, otherwise the surface's natural default in degrees (x titles read
// horizontally at 0deg, y titles read bottom-to-top at 90deg).
#let _title-angle(style, default-deg) = if style.angle != none {
  style.angle
} else { default-deg * 1deg }

// The exact box a wrapped axis title is drawn in, shared by the measuring and
// the drawing side so the two cannot drift. cetz stamps `top-edge:
// "cap-height"` / `bottom-edge: "baseline"` onto the bodies it lays out and
// sizes its own frame from a body measured that way, adding a descender
// allowance when the body does not already carry those edges. Setting them
// here makes `measure()` on this box predict the cetz frame exactly, which is
// what lets the canvas stay inside the requested plot size.
#let _title-boxed(body, along-cm, align-to) = box(
  width: along-cm * 1cm,
  align(align-to, text(top-edge: "cap-height", bottom-edge: "baseline", body)),
)

// Measure an axis title string at its font size, returning `(width, height)`
// in cm. Zero extents when no title renders. Caller must already be inside a
// `context { ... }` block, since `measure` requires it.
//
// `along-cm` bounds the title's reading direction, which is what the panel
// constrains: cetz lays a title out before rotating it, so a y title's
// pre-rotation width becomes its extent up the panel. Pass the available
// reading length and a longer title wraps instead of growing the canvas past
// the requested plot size; the record then carries `along` (the box the draw
// side must reproduce) and `min-width` (the widest unbreakable run, for the
// caller's overrun guard). Leave it `none` to measure a single unbounded line.
//
// Only the wrapped branch measures through the full text style; the unwrapped
// one keeps the size-only measurement every existing layout is calibrated to.
// The reservation still matches the drawing either way, because both sides go
// through `_title-boxed`.
#let _axis-title-extents(title, style, along-cm: none) = {
  if title == none { return (width: 0.0, height: 0.0, along: none) }
  let resolved = resolve-prose(title, eval-strings: style.typst)
  let natural = measure-labels-cm((resolved,), style.size)
  // A title that already fits needs no box: measuring and drawing it exactly
  // as before keeps every existing layout bit-identical.
  if along-cm == none or natural.width <= along-cm {
    return natural + (along: none)
  }
  let boxed = measure(_title-boxed(
    text(.._text-args(style))[#resolved],
    along-cm,
    center,
  ))
  (
    // A box reports the width it was given, not the ink inside it. That is the
    // honest figure here: the drawn title occupies exactly this box.
    width: along-cm,
    height: boxed.height / 1cm,
    min-width: longest-unbreakable-cm(resolved, style.size),
    along: along-cm,
  )
}

// Resolve a margin side on a text-style record to a cm float, falling back to
// the supplied default length when the user has not overridden the side. The
// surface's font size is forwarded so em values scale with it.
#let _text-margin-cm(style, side, default-length) = {
  resolve-margin-side-cm(
    style.margin.at(side),
    default-length,
    size-pt: style.size / 1pt,
  )
}

// Default extents for an axis without labels: zero width, font-height as a
// safe fallback so layouts that ask for a depth before measurement is
// possible still leave room for a single line of text.
#let _empty-extents(size) = (
  width: 0.0,
  height: _ax-text-cm(size),
)

// Either the supplied extents record or `_empty-extents(size)` when caller
// did not measure any labels (e.g., callers that skip measurement or have no secondary axis).
#let _resolve-extents(extents, size) = if extents != none {
  extents
} else { _empty-extents(size) }

// Resolve a single tick label to its rendered form so measurement matches
// what the axis-draw path will emit.
#let _resolve-tick(labels-cb, typst-mark, idx, value, fallback, typst-eval) = (
  resolve-prose(
    resolve-label(labels-cb, value, idx, fallback, typst-mark: typst-mark),
    eval-strings: typst-eval,
  )
)

#let _trained-labels-cb(trained) = spec-attr(
  trained,
  "labels",
  fallback: auto,
)

// Collect the formatted tick labels for the trained scale and measure them
// via Typst. Returns `(width, height)` in cm of the longest label's ink box.
// Caller must already be inside a `context { ... }` block.
// `typst-eval` mirrors the axis-text style's `typst` flag so typst-marked
// labels measure at their rendered width.
#let _axis-label-extents(trained, size, typst-eval: false) = {
  if trained == none { return _empty-extents(size) }
  let labels-cb = _trained-labels-cb(trained)
  let typst-mark = trained.at("typst-mark", default: false)
  let labels = ()
  if trained.type == "discrete" {
    labels = trained
      .domain
      .enumerate()
      .map(((idx, level)) => (
        _resolve-tick(labels-cb, typst-mark, idx, level, level, typst-eval)
      ))
  } else if trained.type == "continuous" {
    labels = _axis-breaks(trained)
      .enumerate()
      .map(((idx, b)) => (
        _resolve-tick(
          labels-cb,
          typst-mark,
          idx,
          b,
          _axis-label(trained, b),
          typst-eval,
        )
      ))
  }
  if labels.len() == 0 { return _empty-extents(size) }
  measure-labels-cm(labels, size)
}

// Same as `_axis-label-extents` but for the secondary axis: each break is
// routed through the user's transformation before formatting. Returns zero
// extents when no secondary axis is configured. Mirrors the draw in
// `panel-draw.typ`, so the secondary's own breaks and labels win here too and
// the reserved margin matches the labels actually drawn.
#let _secondary-label-extents(trained, sec, size, typst-eval: false) = {
  if trained == none or sec == none { return (width: 0.0, height: 0.0) }
  if trained.type != "continuous" { return (width: 0.0, height: 0.0) }
  let labels-cb = sec.at("labels", default: auto)
  let typst-mark = trained.at("typst-mark", default: false)
  let labels = _secondary-breaks(trained, sec, _axis-breaks(trained))
    .enumerate()
    .map(((idx, b)) => {
      let transformed = secondary-mod.apply-transform(sec, b)
      _resolve-tick(
        labels-cb,
        typst-mark,
        idx,
        transformed,
        format-break(transformed),
        typst-eval,
      )
    })
  if labels.len() == 0 { return (width: 0.0, height: 0.0) }
  measure-labels-cm(labels, size)
}

// Perpendicular extent of x-axis tick labels (cm). Inputs are the measured
// ink-bbox width and height of the longest label; rotating composes them
// trigonometrically, and `n-dodge > 1` adds the staggered rows.
#let _x-label-depth(angle, n-dodge, label-w-cm, label-h-cm) = {
  let a = calc.abs(angle) * 1deg
  label-w-cm * calc.sin(a) + label-h-cm * calc.cos(a) + (n-dodge - 1) * 0.35
}

// Perpendicular extent of y-axis tick labels (cm). At angle 0 the labels
// extend leftward by their full measured width; rotating swaps the extents
// according to the rotated bounding box, and `n-dodge > 1` adds dodge cols.
#let _y-label-width(angle, n-dodge, label-w-cm, label-h-cm) = {
  let a = calc.abs(angle) * 1deg
  label-w-cm * calc.cos(a) + label-h-cm * calc.sin(a) + (n-dodge - 1) * 0.5
}

// Perpendicular extent (cm) reserved for an axis title rotated by its resolved
// angle. `axis` picks both the rotated-bbox formula and the natural default
// angle: `"x"` titles read horizontally (0deg) and occupy a depth below the
// panel, `"y"` titles read bottom-to-top (90deg) and a width beside it. The
// along-reading dimension is the measured title width (`ext.width`, `0` when
// unmeasured); the perpendicular thickness stays one line height, so a title
// at its natural angle reserves exactly `_ax-text-cm(size)` as before. A title
// that `_axis-title-extents` had to wrap is thicker than one line, so take
// whichever is larger and the single-line case stays untouched.
#let _title-extent-cm(style, ext, axis) = {
  let title-w = if ext != none { ext.width } else { 0.0 }
  let line-h = _ax-text-cm(style.size)
  let line-h = if ext != none and ext.at("along", default: none) != none {
    calc.max(line-h, ext.height)
  } else { line-h }
  let a = _title-angle(style, if axis == "x" { 0 } else { 90 }).deg()
  if axis == "x" {
    _x-label-depth(a, 1, title-w, line-h)
  } else {
    _y-label-width(a, 1, title-w, line-h)
  }
}

// Reading length (cm) an axis title has before its projection onto the panel's
// own axis overruns the panel. A title at angle `a` projects `len * cos(a)`
// along an x axis and `len * sin(a)` along a y axis, so invert that. When the
// projection vanishes the title reads across the axis rather than along it (a
// vertical x title, a horizontal y title) and nothing constrains its length,
// since the perpendicular depth is reserved either way: `none` means unbounded.
#let _title-along-cm(style, axis, panel-cm) = {
  if panel-cm <= 0 { return none }
  let default-deg = if axis == "x" { 0 } else { 90 }
  let a = calc.abs(_title-angle(style, default-deg).deg()) * 1deg
  let projection = if axis == "x" { calc.cos(a) } else { calc.sin(a) }
  if projection <= 1e-6 { return none }
  panel-cm / projection
}

// The drawable body for an axis title: the same box `_axis-title-extents`
// measured, so what the canvas reserves and what cetz lays out agree. A title
// that fitted on one line carries no `along` and is drawn bare, exactly as
// before. `fallback-align` is the surface's default when the theme leaves
// `align` unset; it only bites once a title wraps and the lines differ in
// length.
#let _title-body(title, style, ext, fallback-align) = {
  let body = text(.._text-args(style))[#resolve-prose(
    title,
    eval-strings: style.typst,
  )]
  let along = if ext == none { none } else {
    ext.at("along", default: none)
  }
  if along == none { return body }
  let a = if style.align != none { style.align } else { fallback-align }
  _title-boxed(body, along, a)
}

// How far (cm) a title still overruns its box once wrapped: the widest run the
// layout cannot break, less the box. Zero when it fits, and zero for content
// titles, whose break opportunities `measure-wrapped-cm` cannot see.
#let _title-overrun-cm(ext) = {
  let along = ext.at("along", default: none)
  if along == none { return 0.0 }
  calc.max(0.0, ext.at("min-width", default: 0.0) - along)
}

// Inter-row gap between dodged labels on the x and y axes (cm). The depth
// helpers and the per-label draw closures both apply these so the reserved
// axis area stays in sync with the actual ink.
#let _X-LABEL-ROW-GAP = 0.35
#let _Y-LABEL-COL-GAP = 0.5

// Default gap between axis tick labels and axis title (all sides). Used as
// the fallback for `axis-title-*` margin sides left at `auto`. Absolute pt so
// the gap stays stable when users tune the axis-title font size.
#let _AX-TITLE-LABEL-GAP = 5pt

// One-element tuple for stand-alone guides, so callers can iterate uniformly
// across stacks and singletons. Shared between x and y; placement on either
// axis flows through the same rendering path.
#let _axis-guide-rows(g) = if g.stack { g.guides } else { (g,) }

// Stack-aware variants: a `guide-axis-stack` carries multiple sub-guides
// rendered as separate label rows. Inter-row spacing is added once per gap
// between successive rows; non-stack guides degenerate to a single row.
#let _stacked-extent(g, per-row-fn) = {
  let rows = _axis-guide-rows(g)
  let spacing = if g.stack { g.spacing } else { 0 }
  rows.map(per-row-fn).sum() + (rows.len() - 1) * spacing
}
#let _x-label-depth-stack(g, w, h) = _stacked-extent(
  g,
  s => _x-label-depth(s.angle, s.n-dodge, w, h),
)
#let _y-label-width-stack(g, w, h) = _stacked-extent(
  g,
  s => _y-label-width(s.angle, s.n-dodge, w, h),
)

// Reserved extent between the panel and the canvas edge for the secondary
// axis ticks, labels, and title. `axis` selects orientation: `"y"` (right
// edge, label width) or `"x"` (top edge, label depth). Matches the primary
// formula so the title-to-label gap stays symmetric on opposing edges.
// `title-ext` carries the secondary title's measured extents when it had to
// wrap, so the reserved thickness follows its line count like the primary's.
#let _sec-extent(
  sec,
  tick-len,
  sec-extents,
  ax-title,
  axis,
  title-ext: none,
) = {
  if sec == none { return 0.0 }
  let label-extent = if axis == "y" {
    _y-label-width(0, 1, sec-extents.width, sec-extents.height)
  } else {
    _x-label-depth(0, 1, sec-extents.width, sec-extents.height)
  }
  let title-cm = if sec.at("name", default: none) != none {
    _title-extent-cm(ax-title, title-ext, axis)
  } else { 0.0 }
  let gap-side = if axis == "y" { "left" } else { "bottom" }
  let gap = _text-margin-cm(ax-title, gap-side, _AX-TITLE-LABEL-GAP)
  tick-len + 0.1 + label-extent + gap + title-cm + 0.05
}
