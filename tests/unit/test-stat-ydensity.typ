// stat-ydensity: per-x-bucket Gaussian kernel density estimate along y.

#import "../../src/stat/apply.typ": apply-stat, stat-default-params
#import "../../src/stat/ydensity.typ": stat-ydensity

#let close(a, b, tol: 1e-9) = calc.abs(a - b) < tol
#let params(..over) = stat-default-params("ydensity") + over.named()

// --- two buckets, default trim, scale = "area" ------------------------------
// Exact references computed externally. Bucket a's y sample matches the
// stat-density test (bw.nrd0 = 1.059443302298832); bucket b is c(10, 12, 14)
// with bw.nrd0 = 1.078309560573444. Trimmed five-point grids:
//   a: y = 1, 2.5, 4, 5.5, 7
//      density = 0.094314212244519, 0.158837607172092, 0.181588503950945,
//                0.125310944162145, 0.070195226473284
//   b: y = 10, 11, 12, 13, 14
//      density = 0.145531885863866, 0.163015600431199, 0.167486880305183,
//                0.163015600431199, 0.145531885863866
// "area" scaling divides every density by the overall peak 0.181588503950945.

#let ys-a = (1, 2, 2, 3, 4, 4, 4, 5, 6, 7)
#let ys-b = (10, 12, 14)
#let d = ys-a.map(v => (grp: "a", y: v)) + ys-b.map(v => (grp: "b", y: v))
#let r = apply-stat("ydensity", d, (x: "grp", y: "y"), params(n: 5))

#assert.eq(r.data.len(), 10)
#assert.eq(r.mapping.x, "grp")
#assert.eq(r.mapping.y, "y")

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
  assert(close(rows-a.at(i).y, grid-a.at(i)))
  assert(close(rows-a.at(i)._density, e))
  assert(close(rows-a.at(i).violinwidth, e / 0.181588503950945))
}
#assert.eq(rows-a.at(0)._n, 10)
#assert(close(rows-a.at(0)._count, dens-a.at(0) * 10))

#let dens-b = (
  0.145531885863866,
  0.163015600431199,
  0.167486880305183,
  0.163015600431199,
  0.145531885863866,
)
#for (i, e) in dens-b.enumerate() {
  assert(close(rows-b.at(i).y, 10.0 + i))
  assert(close(rows-b.at(i)._density, e))
  assert(close(rows-b.at(i).violinwidth, e / 0.181588503950945))
}
#assert.eq(rows-b.at(0)._n, 3)

// `_scaled` normalises per bucket: each bucket's peak reaches 1.
#assert(close(rows-a.at(2)._scaled, 1.0))
#assert(close(rows-b.at(2)._scaled, 1.0))

// --- scale = "count" ---------------------------------------------------------
// Bucket widths additionally weight by observation count: bucket a's peak
// stays at 1 (largest count), bucket b's centre shrinks to
// (0.167486880305183 * 3) / (0.181588503950945 * 10).

#let rc = apply-stat(
  "ydensity",
  d,
  (x: "grp", y: "y"),
  params(n: 5, scale: "count"),
)
#let rc-a = rc.data.filter(row => row.grp == "a")
#let rc-b = rc.data.filter(row => row.grp == "b")
#assert(close(rc-a.at(2).violinwidth, 1.0))
#assert(close(rc-b.at(2).violinwidth, 0.276702891418329))

// --- scale = "width" ---------------------------------------------------------
// Every bucket stretches to the full width: each peak reaches 1.

#let rw = apply-stat(
  "ydensity",
  d,
  (x: "grp", y: "y"),
  params(n: 5, scale: "width"),
)
#let rw-b = rw.data.filter(row => row.grp == "b")
#assert(close(rw-b.at(0).violinwidth, 0.868915138897370))
#assert(close(rw-b.at(2).violinwidth, 1.0))

// --- trim: false extends the grid by three bandwidths ------------------------

#let rt = apply-stat(
  "ydensity",
  d.filter(row => row.grp == "a"),
  (x: "grp", y: "y"),
  params(n: 5, trim: false),
)
#assert(close(rt.data.first().y, 1 - 3 * 1.059443302298832))
#assert(close(rt.data.last().y, 7 + 3 * 1.059443302298832))

// --- edge cases ---------------------------------------------------------------

// Empty input emits no rows.
#assert.eq(apply-stat("ydensity", (), (x: "grp", y: "y"), params()).data, ())

// A bucket with fewer than two numeric y values is dropped; others survive.
#let sparse = ((grp: "a", y: 1),) + ys-b.map(v => (grp: "b", y: v))
#let rs = apply-stat("ydensity", sparse, (x: "grp", y: "y"), params(n: 5))
#assert.eq(rs.data.len(), 5)
#assert(rs.data.all(row => row.grp == "b"))

// Missing y mapping emits no rows.
#assert.eq(apply-stat("ydensity", d, (x: "grp"), params()).data, ())

// Constructor carries its params.
#assert.eq(
  stat-ydensity(bw: 2, adjust: 0.5, n: 64, trim: false, scale: "width").params,
  (bw: 2, adjust: 0.5, n: 64, trim: false, scale: "width"),
)

stat-ydensity tests passed.
