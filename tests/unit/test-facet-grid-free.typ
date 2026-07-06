// `_train-grid-panels`: facet-grid free scales share x per column and y per
// row. A 2x2 grid with distinct per-column x ranges and per-row y ranges must
// yield equal x-domain within each column and equal y-domain within each row,
// differing across columns and rows.

#import "../../src/render/canvas.typ": _train-grid-panels
#import "../../src/facet/grid.typ": facet-grid

// --- constructor accepts the free policies (was: panic on non-fixed) -------

#assert.eq(facet-grid(rows: "a", scales: "free").scales, "free")
#assert.eq(facet-grid(columns: "b", scales: "free_x").scales, "free_x")
#assert.eq(
  facet-grid(rows: "a", columns: "b", scales: "free_y").scales,
  "free_y",
)
#assert.eq(facet-grid(rows: "a").scales, "fixed")

// --- grouping semantics ----------------------------------------------------

#let layer(xs, ys) = (
  mapping: none,
  data: xs.zip(ys).map(((x, y)) => (x: x, y: y)),
  inherit-aes: true,
)
#let panel(xs, ys) = (layers: (layer(xs, ys),))

// Row-major index r * n-cols + c. Columns differ in x; rows differ in y.
//   col 0 -> x in [0, 1]      col 1 -> x in [10, 11]
//   row 0 -> y in [0, 1]      row 1 -> y in [100, 101]
#let panels = (
  panel((0, 1), (0, 1)), // r0 c0
  panel((10, 11), (0, 1)), // r0 c1
  panel((0, 1), (100, 101)), // r1 c0
  panel((10, 11), (100, 101)), // r1 c1
)
#let spec = (mapping: (kind: "aes", x: "x", y: "y"), scales: (:), data: none)

#let pt = _train-grid-panels(
  spec,
  panels,
  (:),
  none,
  none,
  2,
  2,
  true,
  true,
)

#assert.eq(pt.len(), 4)

// x is shared down each column, differs across columns.
#assert.eq(pt.at(0).x.domain, pt.at(2).x.domain)
#assert.eq(pt.at(1).x.domain, pt.at(3).x.domain)
#assert(pt.at(0).x.domain != pt.at(1).x.domain)
#assert.eq(pt.at(0).x.domain, (0.0, 1.0))
#assert.eq(pt.at(1).x.domain, (10.0, 11.0))

// y is shared across each row, differs across rows.
#assert.eq(pt.at(0).y.domain, pt.at(1).y.domain)
#assert.eq(pt.at(2).y.domain, pt.at(3).y.domain)
#assert(pt.at(0).y.domain != pt.at(2).y.domain)
#assert.eq(pt.at(0).y.domain, (0.0, 1.0))
#assert.eq(pt.at(2).y.domain, (100.0, 101.0))

// free_x only: y stays the shared global (here empty), x still per column.
#let pt-x = _train-grid-panels(spec, panels, (:), none, none, 2, 2, true, false)
#assert.eq(pt-x.at(0).x.domain, (0.0, 1.0))
#assert.eq(pt-x.at(1).x.domain, (10.0, 11.0))
#assert(not pt-x.at(0).keys().contains("y"))

Facet-grid free scale tests passed.
