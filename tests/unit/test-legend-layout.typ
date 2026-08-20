// Verify the swatch grid index mapping for both fill orders. `byrow: false`
// is the default column-major layout; `byrow: true` fills rows left-to-right
// then wraps. `grid-shape` also defaults to a single row when direction is
// horizontal so a top/bottom legend lays out as a single line of entries.

#import "../../src/guide/grid.typ": grid-index, grid-rc, grid-shape
#import "../../src/render/legend.typ": (
  _LABEL-SLACK-CM, _guide-title, _legend-title-style, _title-box, guides-for,
)
#import "../../src/theme/defaults.typ": merge-theme
#import "../../lib.typ": element-text, guide-custom, theme

// Default vertical layout: single column.
#let s-vert = grid-shape(4, none, none, "vertical")
#assert.eq(s-vert.rows, 4)
#assert.eq(s-vert.cols, 1)

// Default horizontal layout: single row.
#let s-horiz = grid-shape(4, none, none, "horizontal")
#assert.eq(s-horiz.rows, 1)
#assert.eq(s-horiz.cols, 4)

// Explicit `ncol` wins regardless of direction.
#let s-ncol = grid-shape(5, none, 2, "horizontal")
#assert.eq(s-ncol.cols, 2)
#assert.eq(s-ncol.rows, 3)

// Column-major (byrow: false) in a 2x3 grid: items go down each column.
//   (0,0)=0  (0,1)=2  (0,2)=4
//   (1,0)=1  (1,1)=3  (1,2)=5
#let s23 = (rows: 2, cols: 3)
#assert.eq(grid-index(0, 0, s23, false), 0)
#assert.eq(grid-index(1, 0, s23, false), 1)
#assert.eq(grid-index(0, 1, s23, false), 2)
#assert.eq(grid-index(0, 2, s23, false), 4)

// Row-major (byrow: true) in the same 2x3 grid: items go across each row.
//   (0,0)=0  (0,1)=1  (0,2)=2
//   (1,0)=3  (1,1)=4  (1,2)=5
#assert.eq(grid-index(0, 0, s23, true), 0)
#assert.eq(grid-index(0, 1, s23, true), 1)
#assert.eq(grid-index(0, 2, s23, true), 2)
#assert.eq(grid-index(1, 0, s23, true), 3)

// `grid-rc` inverts `grid-index`.
#for i in range(6) {
  let rc-col = grid-rc(i, s23, false)
  assert.eq(grid-index(rc-col.row, rc-col.col, s23, false), i)
  let rc-row = grid-rc(i, s23, true)
  assert.eq(grid-index(rc-row.row, rc-row.col, s23, true), i)
}

// `labels(colour: none)` sets `spec.blank`, suppressing the legend title; a
// named scale keeps it.
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

// The reserved guide height tracks the resolved `legend-title` surface: the
// title band is `1.6em` of that surface, so scaling it from the default 8pt to
// 16pt grows every titled guide by exactly `1.6 * 8pt` in cm.
#let _title-spec = (
  mapping: (colour: "g"),
  layers: (
    (
      name: "point",
      mapping: none,
      inherit-aes: true,
      params: (colour: auto, fill: auto, shape: auto),
    ),
  ),
  guides: (:),
)
#let _title-trained = (colour: (type: "discrete", domain: ("a", "b")))
#let _titled-height(title-pt) = {
  let guides = guides-for(
    _title-spec,
    _title-trained,
    theme: merge-theme(theme(legend-title: element-text(size: title-pt))),
  )
  guides.at(0).height
}
#context {
  let delta = _titled-height(16pt) - _titled-height(8pt)
  assert(
    calc.abs(delta - 1.6 * 8 * (1pt / 1cm)) < 1e-9,
    message: "title band delta was " + repr(delta),
  )
}

// The reserved guide width tracks the same surface: a title wider than the key
// column drives the box, and the title is measured, so doubling the
// `legend-title` size doubles the ink it reserves past the layout slack.
#let _wide = "a-legend-title-wider-than-its-keys"
#let _wide-spec = (
  mapping: (colour: _wide),
  layers: _title-spec.layers,
  guides: (:),
)
#let _titled-width(title-pt) = {
  let guides = guides-for(
    _wide-spec,
    _title-trained,
    theme: merge-theme(theme(legend-title: element-text(size: title-pt))),
  )
  guides.at(0).width
}
#context {
  let narrow = _titled-width(8pt)
  let delta = _titled-width(16pt) - narrow
  assert(
    calc.abs(delta - (narrow - _LABEL-SLACK-CM)) < 1e-6,
    message: "title width delta was "
      + repr(delta)
      + " against a 8pt width of "
      + repr(narrow),
  )
}

// A custom guide reserves room for the title it draws: a title wider than the
// requested block width widens the box rather than overhanging it, at the
// width the `legend-title` surface actually advances to.
#let _custom-title = "Notes wider than the block"
#context {
  let guides = guides-for(
    (
      mapping: (:),
      layers: (),
      guides: (notes: guide-custom([Block], width: 1cm, title: _custom-title)),
    ),
    (:),
    theme: merge-theme(theme()),
  )
  assert.eq(guides.len(), 1)
  let expected = _title-box(
    (title: _custom-title),
    _legend-title-style(merge-theme(theme())),
  ).width
  assert(expected > 1.0, message: "the title has to beat the 1cm block")
  assert(
    calc.abs(guides.at(0).width - expected) < 1e-9,
    message: "custom guide width was " + repr(guides.at(0).width),
  )
}

Legend-layout tests passed.
