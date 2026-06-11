// Hex binning. `stat-bin-hex` partitions (x, y) into a pointy-top hex grid
// and counts rows per cell.

#import "../../src/aes.typ": aes
#import "../../src/stat/bin-hex.typ": apply, stat-bin-hex
#import "../../src/utils/hex.typ": (
  hex-bin-of, hex-grid, hex-vertices, panel-hex-grid,
)

#let s = stat-bin-hex(bins: 4)
#assert.eq(s.kind, "stat")
#assert.eq(s.name, "bin-hex")
#assert.eq(s.params.bins, 4)

// hex-grid resolves pitches from extents and bins.
#let xs = (0.0, 1.0, 2.0, 3.0)
#let ys = (0.0, 1.0, 2.0, 3.0)
#let g = hex-grid(xs, ys, 3, none)
#assert.eq(g.x-lo, 0.0)
#assert.eq(g.y-lo, 0.0)
#assert.eq(g.dx, 1.0)
// Default dy: dx * sqrt(3) / 2.
#assert(calc.abs(g.dy - calc.sqrt(3) / 2) < 1e-9)

// Pair binwidth wins on the y axis.
#let g-bw = hex-grid(xs, ys, 3, (0.5, 0.4))
#assert.eq(g-bw.dx, 0.5)
#assert.eq(g-bw.dy, 0.4)

// Two close points land in the same hex cell.
#let g-small = hex-grid((0.0, 1.0), (0.0, 1.0), 4, none)
#let a = hex-bin-of(0.1, 0.1, g-small)
#let b = hex-bin-of(0.12, 0.11, g-small)
#assert.eq((a.ix, a.iy), (b.ix, b.iy))

// The centre returned by hex-bin-of lies on either the even-row lattice
// (iy even) or the odd-row lattice (iy odd, offset by dx/2 horizontally).
#assert(calc.abs(a.cx - g-small.x-lo) < 1.0)

// hex-vertices returns 6 points around a centre.
#let v = hex-vertices(0.0, 0.0, 1.0, calc.sqrt(3) / 2)
#assert.eq(v.len(), 6)
// Top vertex is straight up at q = dy * 2/3.
#let q = (calc.sqrt(3) / 2) * 2 / 3
#assert(calc.abs(v.at(0).at(0)) < 1e-9)
#assert(calc.abs(v.at(0).at(1) - q) < 1e-9)

// apply(): rows have x, y at hex centre, _count, _density.
#let raw = (
  (a: 0.1, b: 0.1),
  (a: 0.12, b: 0.11),
  (a: 2.0, b: 2.0),
)
#let r = apply(raw, aes(x: "a", y: "b"), params: (bins: 4, binwidth: none))
#assert.eq(r.mapping.fill, "_count")
#assert.eq(r.mapping.x, "x")
#assert.eq(r.data.len(), 2)
#let total = r.data.fold(0, (acc, row) => acc + row._count)
#assert.eq(total, 3)
// _density is each cell's fraction of the total count and sums to 1.
#let density-sum = r.data.fold(0.0, (acc, row) => acc + row._density)
#assert(calc.abs(density-sum - 1.0) < 1e-9)
// Hex-specific draw hints come along for the ride.
#assert("_hex-dx" in r.data.first())

// panel-hex-grid stashes the grid for per-group reuse.
#let p = panel-hex-grid(raw, aes(x: "a", y: "b"), (bins: 4, binwidth: none))
#assert.eq(p.grid.dx, hex-grid((0.1, 0.12, 2.0), (0.1, 0.11, 2.0), 4, none).dx)

stat-bin-hex tests passed.
