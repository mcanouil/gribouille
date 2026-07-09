// stat-density-ridges: per-y-bucket Gaussian kernel density estimate along x.

#import "../../src/stat/apply.typ": apply-stat, stat-default-params
#import "../../src/stat/density-ridges.typ": stat-density-ridges

#let close(a, b, tol: 1e-9) = calc.abs(a - b) < tol
#let params(..over) = stat-default-params("density-ridges") + over.named()

// --- two buckets, trimmed grid, shared normalisation -------------------------
// Same externally computed references as the stat-ydensity test, transposed:
// bucket a's x sample has bw.nrd0 = 1.059443302298832, bucket b is
// c(10, 12, 14) with bw.nrd0 = 1.078309560573444. Trimmed five-point grids:
//   a: x = 1, 2.5, 4, 5.5, 7
//      density = 0.094314212244519, 0.158837607172092, 0.181588503950945,
//                0.125310944162145, 0.070195226473284
//   b: x = 10, 11, 12, 13, 14
//      density = 0.145531885863866, 0.163015600431199, 0.167486880305183,
//                0.163015600431199, 0.145531885863866
// `height` divides every density by the shared peak 0.181588503950945.

#let xs-a = (1, 2, 2, 3, 4, 4, 4, 5, 6, 7)
#let xs-b = (10, 12, 14)
#let d = xs-a.map(v => (grp: "a", x: v)) + xs-b.map(v => (grp: "b", x: v))
#let r = apply-stat(
  "density-ridges",
  d,
  (x: "x", y: "grp"),
  params(n: 5, trim: true),
)

#assert.eq(r.data.len(), 10)
#assert.eq(r.mapping.x, "x")
#assert.eq(r.mapping.y, "grp")
#assert.eq(r.mapping.height, "height")

#let rows-a = r.data.filter(row => row.grp == "a")
#let rows-b = r.data.filter(row => row.grp == "b")
#assert.eq(rows-a.len(), 5)
#assert.eq(rows-b.len(), 5)

#let dens-a = (
  0.094314212244519,
  0.158837607172092,
  0.181588503950945,
  0.125310944162145,
  0.070195226473284,
)
#let grid-a = (1.0, 2.5, 4.0, 5.5, 7.0)
#for (i, e) in dens-a.enumerate() {
  assert(close(rows-a.at(i).x, grid-a.at(i)))
  assert(close(rows-a.at(i)._density, e))
  assert(close(rows-a.at(i).height, e / 0.181588503950945))
}
#assert.eq(rows-a.at(0)._n, 10)

#let dens-b = (
  0.145531885863866,
  0.163015600431199,
  0.167486880305183,
  0.163015600431199,
  0.145531885863866,
)
#for (i, e) in dens-b.enumerate() {
  assert(close(rows-b.at(i).x, 10.0 + i))
  assert(close(rows-b.at(i)._density, e))
  assert(close(rows-b.at(i).height, e / 0.181588503950945))
}
#assert.eq(rows-b.at(0)._n, 3)

// The shared normalisation peaks at exactly 1 in the tallest bucket only.
#assert(close(rows-a.at(2).height, 1.0))
#assert(rows-b.map(row => row.height).all(h => h < 1.0))

// `_scaled` normalises per bucket: each bucket's own peak reaches 1.
#assert(close(rows-a.at(2)._scaled, 1.0))
#assert(close(rows-b.at(2)._scaled, 1.0))

// --- trim: false (default) extends each grid by three bandwidths -------------

#let rt = apply-stat(
  "density-ridges",
  d.filter(row => row.grp == "a"),
  (x: "x", y: "grp"),
  params(n: 5),
)
#assert(close(rt.data.first().x, 1 - 3 * 1.059443302298832))
#assert(close(rt.data.last().x, 7 + 3 * 1.059443302298832))

// --- edge cases ----------------------------------------------------------------

// Empty input emits no rows.
#assert.eq(
  apply-stat("density-ridges", (), (x: "x", y: "grp"), params()).data,
  (),
)

// A bucket with fewer than two numeric x values is dropped; others survive.
#let sparse = ((grp: "a", x: 1),) + xs-b.map(v => (grp: "b", x: v))
#let rs = apply-stat(
  "density-ridges",
  sparse,
  (x: "x", y: "grp"),
  params(n: 5),
)
#assert.eq(rs.data.len(), 5)
#assert(rs.data.all(row => row.grp == "b"))

// Missing y mapping emits no rows.
#assert.eq(apply-stat("density-ridges", d, (x: "x"), params()).data, ())

// Constructor carries its params.
#assert.eq(
  stat-density-ridges(bw: 2, adjust: 0.5, n: 64, trim: true).params,
  (bw: 2, adjust: 0.5, n: 64, trim: true),
)

stat-density-ridges tests passed.
