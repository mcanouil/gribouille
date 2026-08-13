// Every geom taking an `arrow` parameter defaults it to `none` and passes the
// spec through untouched. The renders at the bottom exercise the draw path for
// each geom; the compile is the assertion.

#import "../../src/aes.typ": aes
#import "../../src/geom/curve.typ": geom-curve
#import "../../src/geom/label.typ": geom-label
#import "../../src/geom/line.typ": geom-line
#import "../../src/geom/path.typ": geom-path
#import "../../src/geom/segment.typ": geom-segment
#import "../../src/geom/spoke.typ": geom-spoke
#import "../../src/geom/step.typ": geom-step
#import "../../src/geom/text.typ": geom-text
#import "../../src/geom/typst.typ": geom-typst
#import "../../src/plot.typ": plot
#import "../../src/utils/arrow.typ": arrow

#let head = arrow(length: 9pt, ends: "both", type: "closed")

#let builders = (
  ("geom-segment", geom-segment),
  ("geom-curve", geom-curve),
  ("geom-spoke", geom-spoke),
  ("geom-path", geom-path),
  ("geom-line", geom-line),
  ("geom-step", geom-step),
  ("geom-text", geom-text),
  ("geom-label", geom-label),
  ("geom-typst", geom-typst),
)

#for (name, build) in builders {
  assert.eq(build().params.arrow, none, message: name + " default")
  assert.eq(build(arrow: head).params.arrow, head, message: name + " override")
}

#let ends = ((x: 0, y: 0, xend: 3, yend: 2),)
#let pts = ((x: 1, y: 1), (x: 2, y: 3), (x: 3, y: 2))

#plot(
  data: ends,
  mapping: aes(x: "x", y: "y", xend: "xend", yend: "yend"),
  layers: (
    geom-segment(arrow: arrow()),
    geom-curve(arrow: arrow(ends: "first")),
  ),
  width: 8cm,
  height: 5cm,
)

#plot(
  data: pts,
  mapping: aes(x: "x", y: "y"),
  layers: (
    geom-path(arrow: arrow(ends: "both")),
    geom-line(arrow: arrow(type: "closed")),
    geom-step(arrow: arrow()),
  ),
  width: 8cm,
  height: 5cm,
)

// A spoke of zero radius collapses to a point, leaving no direction to point
// along: the head is skipped rather than failing.
#plot(
  data: ((x: 1, y: 1, r: 0), (x: 2, y: 2, r: 1)),
  mapping: aes(x: "x", y: "y", radius: "r"),
  layers: (geom-spoke(angle: 45deg, arrow: arrow()),),
  width: 8cm,
  height: 5cm,
)

geom arrow parameter tests passed.
