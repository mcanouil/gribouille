// Standalone anatomy figure for docs/guides/theming.qmd.
//
// Compile from the project root for debugging:
//
//   typst compile --root . docs/guides/_theme-anatomy.typ docs/guides/_theme-anatomy.pdf
//
// The .qmd page reuses this file via the `file: _theme-anatomy.typ` chunk
// option; do not move or rename it without updating that reference.

#import "/lib.typ": *
#import "@preview/cetz:0.5.2": canvas, draw

#set page(width: auto, height: auto, margin: 0.5cm)

#let _ink = {
  let v = sys.inputs.at("typst-render-foreground", default: "")
  if v == "" { rgb("#1f2328") } else { rgb(v) }
}
#let _muted = rgb("#666666")

// Okabe-Ito palette (colour-blind friendly); reddish purple dropped per house style,
// black added as the eighth hue.
#let _palette = (
  c1: okabe-ito.at(0),
  c2: okabe-ito.at(4),
  c3: okabe-ito.at(2),
  c4: okabe-ito.at(5),
  c5: rgb("#000000"),
  c6: okabe-ito.at(1),
  c7: okabe-ito.at(3),
  c8: okabe-ito.at(7),
)

#let _demo-data = (
  (g: "A", x: 1, y: 2.4),
  (g: "A", x: 2, y: 3.1),
  (g: "A", x: 3, y: 3.8),
  (g: "A", x: 4, y: 4.2),
  (g: "B", x: 1, y: 1.6),
  (g: "B", x: 2, y: 2.0),
  (g: "B", x: 3, y: 2.7),
  (g: "B", x: 4, y: 3.1),
)

#let _demo-plot = plot(
  data: _demo-data,
  mapping: aes(x: "x", y: "y", colour: "g"),
  layers: (geom-point(size: 3pt),),
  facet: facet-wrap("g"),
  labs: labs(
    title: "Anatomy of a plot",
    subtitle: "Each region is one theme() key",
    caption: "Caption text lives in plot-caption",
    x: "x (axis-title)",
    y: "y (axis-title)",
    colour: "Group",
  ),
  theme: theme(
    plot-background: element-rect(
      fill: _palette.c1.lighten(85%),
      colour: _palette.c1,
      stroke: 1.2pt,
    ),
    plot-title: element-text(colour: _palette.c2),
    plot-subtitle: element-text(colour: _palette.c2),
    plot-caption: element-text(colour: _palette.c3),
    axis-text-y-left: element-text(colour: _palette.c4),
    axis-title-y-left: element-text(colour: _palette.c4),
    axis-ticks-y-left: element-line(colour: _palette.c4, stroke: 0.8pt),
    legend-title: element-text(colour: _palette.c7.darken(60%)),
    legend-text: element-text(colour: _palette.c7.darken(60%)),
    strip-background: element-rect(
      fill: _palette.c5.lighten(85%),
      colour: _palette.c5,
      stroke: 1pt,
    ),
    panel-background: element-rect(
      fill: _palette.c6.lighten(85%),
      colour: _palette.c6,
      stroke: 1pt,
    ),
    panel-grid: element-line(colour: _palette.c6, stroke: 0.5pt),
    legend-background: element-rect(
      fill: _palette.c7.lighten(85%),
      colour: _palette.c7,
      stroke: 1.5pt,
    ),
    axis-text-x-bottom: element-text(colour: _palette.c8),
    axis-title-x-bottom: element-text(colour: _palette.c8),
    axis-ticks-x-bottom: element-line(colour: _palette.c8, stroke: 0.8pt),
    axis-line: element-blank(),
  ),
  width: 12cm,
  height: 9cm,
)

// Flip to `true` to overlay a coord grid for tuning badge / legend positions.
#let _debug = false

#canvas(length: 1cm, {
  import draw: *
  set-style(content: (frame: none))

  let px = 4.5
  let py = 4.0
  let pw = 12.0
  let ph = 6.5

  content(
    (px, py),
    anchor: "south-west",
    _demo-plot,
  )

  if _debug {
    let gx-max = 22
    let gy-max = 14
    let minor = rgb("#dddddd")
    let major = rgb("#888888")
    for x in range(0, gx-max + 1) {
      line((x, 0), (x, gy-max), stroke: 0.2pt + major)
      content((x, -0.2), anchor: "north", text(size: 5pt, fill: major)[#x])
    }
    for y in range(0, gy-max + 1) {
      line((0, y), (gx-max, y), stroke: 0.2pt + major)
      content((-0.2, y), anchor: "east", text(size: 5pt, fill: major)[#y])
    }
    for i in range(0, gx-max * 2 + 1) {
      let x = i / 2
      if calc.rem(i, 2) != 0 {
        line((x, 0), (x, gy-max), stroke: 0.1pt + minor)
      }
    }
    for i in range(0, gy-max * 2 + 1) {
      let y = i / 2
      if calc.rem(i, 2) != 0 {
        line((0, y), (gx-max, y), stroke: 0.1pt + minor)
      }
    }
  }

  // White marker text reads on every palette entry except yellow.
  let _num-fill(c) = if c == _palette.c7 { rgb("#1f2328") } else { white }

  let badge(e) = text(size: 7pt, weight: "bold", fill: _num-fill(
    e.colour,
  ))[#e.num]

  let entry(e) = block(width: 2.5cm)[
    #box(
      baseline: 25%,
      width: 1em,
      height: 1em,
      fill: e.colour,
      stroke: 0.3pt + _ink,
      inset: 0pt,
      align(center + horizon, text(
        size: 7pt,
        weight: "bold",
        fill: _num-fill(e.colour),
      )[#e.num]),
    )
    #h(0.35em)
    #text(size: 7.5pt, fill: _ink, weight: "bold")[#e.name] \
    #text(size: 7pt, font: "DejaVu Sans Mono", fill: _muted)[#e.keys]
  ]

  let entries = (
    (
      num: 1,
      colour: _palette.c1,
      marker: (4.4, 13.1),
      legend: (3.2 + 1, 13.0 - 1.5),
      legend-anchor: "north-east",
      name: "Outer canvas",
      keys: [`plot-background`],
    ),
    (
      num: 2,
      colour: _palette.c2,
      marker: (9, 12.5),
      legend: (3.2 + 1, 11.5 - 1.5),
      legend-anchor: "north-east",
      name: "Title block",
      keys: [`plot-title` \ `plot-subtitle`],
    ),
    (
      num: 3,
      colour: _palette.c4,
      marker: (5, 10),
      legend: (3.2 + 1, 9.7 - 1.5),
      legend-anchor: "north-east",
      name: "Left axis",
      keys: [
        `axis-line-y-left` \
        `axis-ticks-y-left` \
        `axis-text-y-left` \
        `axis-title-y-left`
      ],
    ),
    (
      num: 4,
      colour: _palette.c3,
      marker: (12, 4.5),
      legend: (3.2 + 1, 7.0 - 1.5),
      legend-anchor: "north-east",
      name: "Caption",
      keys: [`plot-caption`],
    ),
    (
      num: 5,
      colour: _palette.c5,
      marker: (14.85, 11.85),
      legend: (18.0 - 0.7, 13.0 - 0.8),
      legend-anchor: "north-west",
      name: "Facet strip",
      keys: [`strip-background` \ `strip-text`],
    ),
    (
      num: 6,
      colour: _palette.c6,
      marker: (12.6, 8.7),
      legend: (18.0 - 0.7, 11.5 - 0.8),
      legend-anchor: "north-west",
      name: "Panel",
      keys: [`panel-background` \ `panel-grid`],
    ),
    (
      num: 7,
      colour: _palette.c7,
      marker: (16.3, 9.5),
      legend: (18.0 - 0.7, 10.0 - 0.8),
      legend-anchor: "north-west",
      name: "Legend",
      keys: [
        `legend-background` \
        `legend-title` \
        `legend-text` \
        `legend-bar` \
        `legend-ticks`
      ],
    ),
    (
      num: 8,
      colour: _palette.c8,
      marker: (9, 4.9),
      legend: (18.0 - 0.7, 6.5),
      legend-anchor: "north-west",
      name: "Bottom axis",
      keys: [
        `axis-line-x-bottom` \
        `axis-ticks-x-bottom` \
        `axis-text-x-bottom` \
        `axis-title-x-bottom`
      ],
    ),
  )

  for e in entries {
    let target = e.at("target", default: none)
    if target != none {
      line(e.marker, target, stroke: 0.6pt + e.colour)
    }
  }
  for e in entries {
    circle(e.marker, radius: 0.22, fill: e.colour, stroke: 0.3pt + _ink)
    content(e.marker, anchor: "center", badge(e))
  }
  for e in entries {
    content(e.legend, anchor: e.legend-anchor, entry(e))
  }
})
