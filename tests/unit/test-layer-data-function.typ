// A layer's `data` may be a function applied to the inherited plot data,
// returning the per-layer frame. The closure receives the normalised plot data
// and may return row- or column-store; the result is normalised
// to canonical row-store.

#import "../../src/render/layer-prep.typ": _prepare-layer
#import "../../src/render/common.typ": _resolve-data
#import "../../src/aes.typ": aes
#import "../../src/geom/point.typ": geom-point

#let plot-rows = (
  (x: 1, y: 1, cyl: 4),
  (x: 2, y: 2, cyl: 6),
  (x: 3, y: 3, cyl: 8),
  (x: 4, y: 4, cyl: 8),
)

// `none` data still inherits the plot data unchanged.
#assert.eq(_resolve-data((data: none), plot-rows), plot-rows)

// A closure returning a row-store subset is applied to the plot data.
#let subset8 = _resolve-data(
  (data: rows => rows.filter(r => r.cyl == 8)),
  plot-rows,
)
#assert.eq(subset8.len(), 2)
#assert.eq(subset8.at(0).x, 3)
#assert.eq(subset8.at(1).x, 4)

// A closure may return column-store; the result is normalised to row-store.
#let derived = _resolve-data(
  (
    data: rows => (
      x: rows.map(r => r.x),
      doubled: rows.map(r => r.y * 2),
    ),
  ),
  plot-rows,
)
#assert.eq(derived.len(), 4)
#assert.eq(derived.at(2).doubled, 6)

// End-to-end: a geom layer built with function data resolves to the filtered
// rows through the full prepare pipeline.
#let layer = geom-point(data: rows => rows.filter(r => r.cyl == 8))
#let prepared = _prepare-layer(layer, aes(x: "x", y: "y"), plot-rows)
#assert.eq(prepared.data.len(), 2)
#assert.eq(prepared.data.at(0).x, 3)

// The closure runs against the inherited plot data, not a separate dataset, so
// an empty filter yields no rows rather than falling back to the plot data.
#let empty = _resolve-data(
  (data: rows => rows.filter(r => r.cyl == 12)),
  plot-rows,
)
#assert.eq(empty, ())

// A closure may ignore its argument and return a literal frame, generating the
// layer's data even when the plot itself carries none.
#let generated = _resolve-data(
  (data: _ => (a: (1, 2), b: (3, 4))),
  none,
)
#assert.eq(generated, ((a: 1, b: 3), (a: 2, b: 4)))

// The closure result is validated like any other layer data: returning a
// non-frame panics via `_normalise-data`. Uncomment to verify locally:
//
//   #let _ = _resolve-data((data: _ => 42), plot-rows)
//     panics with: data: value must be an array of dicts or a dict of arrays; got 42.

layer data function tests passed.
