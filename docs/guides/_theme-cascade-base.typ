// Base-record fan-out for docs/guides/theming.qmd.
//
// Compile from the project root for debugging:
//
//   typst compile --root . docs/guides/_theme-cascade-base.typ docs/guides/_theme-cascade-base.pdf
//
// The .qmd page reuses this file via the `file: _theme-cascade-base.typ`
// chunk option; do not move or rename it without updating that reference.

#import "@preview/cetz:0.5.3": canvas, draw

#set page(width: auto, height: auto, margin: 0.5cm)

#let _ink = {
  let v = sys.inputs.at("typst-render-foreground", default: "")
  if v == "" { rgb("#1f2328") } else { rgb(v) }
}
#let _paper = {
  let v = sys.inputs.at("typst-render-background", default: "")
  if v == "" { rgb("#ffffff") } else { rgb(v) }
}
#let _muted = rgb("#666666")
#let _accent-text = rgb("#1f77b4")
#let _accent-line = rgb("#2ca02c")
#let _accent-rect = rgb("#d6604d")

#let _node(label, stroke: _ink, txt: _ink, mono: true) = {
  let body = if mono {
    text(size: 7pt, font: "DejaVu Sans Mono", fill: txt)[#raw(label)]
  } else {
    text(size: 7pt, weight: "bold", fill: txt)[#label]
  }
  box(
    inset: (x: 4pt, y: 2.5pt),
    fill: _paper,
    stroke: 0.4pt + stroke,
    radius: 2pt,
    body,
  )
}

#let _base-fanout(origin, label, accent, children) = {
  import draw: *
  let (ox, oy) = origin
  content((ox, oy), anchor: "west", _node(
    label,
    stroke: accent,
    txt: accent,
    mono: false,
  ))

  // Root box width: 4-char label ("text"/"line"/"rect") at 7pt bold +
  // 4pt x-padding on each side. Lines start past the right edge of the box.
  let root-right = ox + 0.85
  let step = 0.55
  let cx = ox + 2.4
  let top = oy - 0.4
  for (i, child) in children.enumerate() {
    let cy = top - step * i
    line((root-right, oy), (cx - 0.1, cy), stroke: 0.3pt + accent)
    content(
      (cx, cy),
      anchor: "west",
      _node(child, stroke: _muted, txt: _muted),
    )
  }
}

#canvas(length: 1cm, {
  import draw: *
  set-style(content: (frame: none))

  _base-fanout(
    (0.0, 0.0),
    "text",
    _accent-text,
    (
      "axis-text",
      "axis-title",
      "legend-text",
      "legend-title",
      "strip-text",
      "plot-title",
      "plot-subtitle",
      "plot-caption",
    ),
  )

  _base-fanout(
    (6.2, 0.0),
    "line",
    _accent-line,
    ("panel-grid", "axis-line", "axis-ticks", "legend-ticks"),
  )

  _base-fanout(
    (12.0, 0.0),
    "rect",
    _accent-rect,
    (
      "panel-background",
      "plot-background",
      "strip-background",
      "legend-background",
      "legend-bar",
    ),
  )
})
