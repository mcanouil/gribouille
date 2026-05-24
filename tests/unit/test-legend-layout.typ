// Verify the swatch grid index mapping for both fill orders. `byrow: false`
// is the default column-major layout; `byrow: true` fills rows left-to-right
// then wraps. `_grid-shape` also defaults to a single row when direction is
// horizontal so a top/bottom legend lays out as a single line of entries.

#import "../../src/legend.typ": (
  _grid-shape, _guide-title, _swatch-index, _swatch-rc, _title-prefix,
)

// Default vertical layout: single column.
#let s-vert = _grid-shape(4, none, none, "vertical")
#assert.eq(s-vert.rows, 4)
#assert.eq(s-vert.cols, 1)

// Default horizontal layout: single row.
#let s-horiz = _grid-shape(4, none, none, "horizontal")
#assert.eq(s-horiz.rows, 1)
#assert.eq(s-horiz.cols, 4)

// Explicit `ncol` wins regardless of direction.
#let s-ncol = _grid-shape(5, none, 2, "horizontal")
#assert.eq(s-ncol.cols, 2)
#assert.eq(s-ncol.rows, 3)

// Column-major (byrow: false) in a 2x3 grid: items go down each column.
//   (0,0)=0  (0,1)=2  (0,2)=4
//   (1,0)=1  (1,1)=3  (1,2)=5
#let s23 = (rows: 2, cols: 3)
#assert.eq(_swatch-index(0, 0, s23, false), 0)
#assert.eq(_swatch-index(1, 0, s23, false), 1)
#assert.eq(_swatch-index(0, 1, s23, false), 2)
#assert.eq(_swatch-index(0, 2, s23, false), 4)

// Row-major (byrow: true) in the same 2x3 grid: items go across each row.
//   (0,0)=0  (0,1)=1  (0,2)=2
//   (1,0)=3  (1,1)=4  (1,2)=5
#assert.eq(_swatch-index(0, 0, s23, true), 0)
#assert.eq(_swatch-index(0, 1, s23, true), 1)
#assert.eq(_swatch-index(0, 2, s23, true), 2)
#assert.eq(_swatch-index(1, 0, s23, true), 3)

// `_swatch-rc` inverts `_swatch-index`.
#for i in range(6) {
  let rc-col = _swatch-rc(i, s23, false)
  assert.eq(_swatch-index(rc-col.row, rc-col.col, s23, false), i)
  let rc-row = _swatch-rc(i, s23, true)
  assert.eq(_swatch-index(rc-row.row, rc-row.col, s23, true), i)
}

// `labs(colour: none)` sets `spec.blank`, suppressing the legend title; a named
// scale keeps it, and a titleless guide reserves no title height.
#let _pspec = (mapping: (colour: "sp"))
#assert.eq(
  _guide-title(
    (spec: (aesthetic: "colour", name: "Species")),
    _pspec,
    "colour",
  ),
  "Species",
)
#assert.eq(
  _guide-title(
    (spec: (aesthetic: "colour", name: "Species", blank: true)),
    _pspec,
    "colour",
  ),
  none,
)
#assert.eq(_title-prefix((title: none), 0.5), 0.0)
#assert.eq(_title-prefix((title: "X"), 0.5), 0.5)

Legend-layout tests passed.
