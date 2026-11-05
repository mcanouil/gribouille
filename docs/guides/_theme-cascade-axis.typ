// Axis-family cascade template for docs/guides/theming.qmd.
//
// Compile from the project root for debugging:
//
//   typst compile --root . docs/guides/_theme-cascade-axis.typ docs/guides/_theme-cascade-axis.pdf
//
// The .qmd page reuses this file via the `file: _theme-cascade-axis.typ`
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
#let _accent-axis = rgb("#7c3aed")

#let _node(label, stroke: _ink, txt: _ink) = {
  box(
    inset: (x: 4pt, y: 2.5pt),
    fill: _paper,
    stroke: 0.4pt + stroke,
    radius: 2pt,
    text(size: 7pt, font: "DejaVu Sans Mono", fill: txt)[#raw(label)],
  )
}

#canvas(length: 1cm, {
  import draw: *
  set-style(content: (frame: none))

  let root-pos = (8.6, 3.2)
  let ax-x = (4.4, 1.6)
  let ax-y = (12.8, 1.6)
  let xb = (1.4, 0.0)
  let xt = (6.6, 0.0)
  let yl = (10.6, 0.0)
  let yr = (15.8, 0.0)

  let edge(a, b) = line(a, b, stroke: 0.5pt + _accent-axis)

  edge(root-pos, ax-x)
  edge(root-pos, ax-y)
  edge(ax-x, xb)
  edge(ax-x, xt)
  edge(ax-y, yl)
  edge(ax-y, yr)

  content(root-pos, _node("<family>", stroke: _accent-axis, txt: _accent-axis))
  content(ax-x, _node("<family>-x", stroke: _accent-axis, txt: _ink))
  content(ax-y, _node("<family>-y", stroke: _accent-axis, txt: _ink))
  content(xb, _node("<family>-x-bottom", stroke: _muted, txt: _muted))
  content(xt, _node("<family>-x-top", stroke: _muted, txt: _muted))
  content(yl, _node("<family>-y-left", stroke: _muted, txt: _muted))
  content(yr, _node("<family>-y-right", stroke: _muted, txt: _muted))
})
