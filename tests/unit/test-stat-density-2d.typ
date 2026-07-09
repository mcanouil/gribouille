// kde-2d and the 2D density stats (iso-lines and filled bands).

#import "../../src/utils/kde.typ": bw-nrd, kde-2d
#import "../../src/stat/apply.typ": apply-stat, stat-default-params

#let close(a, b, tol: 1e-9) = calc.abs(a - b) < tol

// --- kde-2d numeric references ------------------------------------------------
// Exact product-kernel references computed externally: per-axis kernel
// standard deviation bw-nrd / 4, grid spanning the data range extended by
// three bandwidths, density = Σ w · K((gx−x)/hx) · K((gy−y)/hy) / (2π hx hy Σw).

#let pts = (
  (x: 1.0, y: 2.0, w: 1.0),
  (x: 2.0, y: 1.0, w: 1.0),
  (x: 2.5, y: 3.0, w: 1.0),
  (x: 4.0, y: 4.0, w: 1.0),
  (x: 5.0, y: 2.5, w: 1.0),
)
#let g = kde-2d(pts, n: 4)

#assert.eq(g.xs.len(), 4)
#assert.eq(g.ys.len(), 4)
#assert(close(g.bw.at(0), 0.286666583394909))
#assert(close(g.bw.at(1), 0.143333291697455))
#assert(close(g.xs.first(), 0.140000249815272))
#assert(close(g.xs.last(), 5.859999750184729))
#assert(close(g.ys.first(), 0.570000124907636))
#assert(close(g.ys.last(), 4.429999875092364))
#assert(close(g.z.at(0).at(0), 6.210438292176104e-12, tol: 1e-20))
#assert(close(g.z.at(1).at(1), 0.000598685402865, tol: 1e-12))
#assert(close(g.z.at(2).at(2), 0.000001287417401, tol: 1e-12))
#assert(close(g.z.at(3).at(1), 0.000000363297626, tol: 1e-12))
#assert(close(g.z-hi, 0.134565696113793))

// Weights shift the estimate: tripling the first point's weight raises the
// density near it.
#let wpts = ((x: 1.0, y: 2.0, w: 3.0),) + pts.slice(1)
#let gw = kde-2d(wpts, n: 4)
#assert(close(gw.z.at(1).at(1), 0.001282878173552, tol: 1e-12))

// Tuple forms: per-axis grid resolution and bandwidth.
#let gt = kde-2d(pts, n: (3, 5), bw: (0.5, 0.25))
#assert.eq(gt.xs.len(), 3)
#assert.eq(gt.ys.len(), 5)
#assert(close(gt.bw.at(0), 0.5))
#assert(close(gt.bw.at(1), 0.25))

// bw-nrd is the 1.06-factor variant of bw-nrd0.
#assert(close(
  bw-nrd((1, 2, 2, 3, 4, 4, 4, 5, 6, 7)),
  1.059443302298832 * 1.06 / 0.9,
))

// --- stat-density-2d: iso-line rows -------------------------------------------

#let d = range(0, 40).map(i => {
  let lobe = calc.rem(i, 2)
  (
    x: 2 + lobe * 4 + calc.sin(i * 1.7) * 0.8,
    y: 2 + lobe * 3 + calc.cos(i * 2.3) * 0.8,
  )
})
#let params(name, ..over) = stat-default-params(name) + over.named()
#let r = apply-stat(
  "density-2d",
  d,
  (x: "x", y: "y"),
  params("density-2d", n: 20, bins: 6),
)
#assert(r.data.len() > 0)
#assert.eq(r.mapping.x, "x")
#assert.eq(r.mapping.y, "y")
#assert.eq(r.mapping.group, "group")
// Segment endpoints come in pairs sharing a group and a level.
#assert.eq(calc.rem(r.data.len(), 2), 0)
#assert.eq(r.data.at(0).group, r.data.at(1).group)
#assert.eq(r.data.at(0)._level, r.data.at(1)._level)
// Every vertex stays inside the density grid's span.
#let gx = kde-2d(
  d.map(row => (x: row.x, y: row.y, w: 1.0)),
  n: 20,
)
#assert(r.data.all(row => row.x >= gx.xs.first() and row.x <= gx.xs.last()))
#assert(r.data.all(row => row.y >= gx.ys.first() and row.y <= gx.ys.last()))
// Levels lie strictly inside the surface's range.
#assert(r.data.all(row => row._level > gx.z-lo and row._level < gx.z-hi))

// --- stat-density-2d-filled: band polygons ------------------------------------

#let rf = apply-stat(
  "density-2d-filled",
  d,
  (x: "x", y: "y"),
  params("density-2d-filled", n: 20, bins: 6),
)
#assert(rf.data.len() > 0)
#assert.eq(rf.mapping.fill, "_level")
// The lowest band starts at the surface minimum.
#let level-lo = calc.min(..rf.data.map(row => row._level))
#assert(close(level-lo, gx.z-lo))

// --- edge cases -----------------------------------------------------------------

// Fewer than two usable points emits no rows.
#assert.eq(
  apply-stat(
    "density-2d",
    ((x: 1, y: 1),),
    (x: "x", y: "y"),
    params("density-2d"),
  ).data,
  (),
)

// Missing y mapping emits no rows.
#assert.eq(
  apply-stat("density-2d", d, (x: "x"), params("density-2d")).data,
  (),
)

stat-density-2d tests passed.
