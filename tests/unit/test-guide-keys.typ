// The key grid: the geometry helpers in `src/guide/grid.typ` and the primitive
// that owns the whole grid. The reserved box is asserted against the formulas
// the legend renderer sized a swatch and a size ladder with before the port, on
// the same inputs, so the move is checked mechanically rather than by eye.

#import "../../src/guide/gctx.typ": gctx
#import "../../src/guide/grid.typ": (
  COL-GAP-MIN, COL-GAP-RATIO, METRIC-FIELDS, align-offset, column-widths,
  flat-rows, grid-index, grid-rc, grid-shape, key-metrics, pin-below,
  pin-right-of, row-overflows, stack-offsets, uniform-columns,
)
#import "../../src/guide/primitive/common.typ": PRIMITIVE, measured
#import "../../src/guide/primitive/keys.typ": FLOWS, prim-keys
#import "../../src/guide/primitive/registry.typ" as registry
#import "../../src/utils/errors.typ": enum-text, error-text, type-text

// One entry per level, carrying the label geometry the render stage stamps.
#let entry(value, width, lines: 1) = (
  value: value,
  label: value,
  width: width,
  lines: lines,
)

#let metrics = key-metrics(
  off: 0.12,
  last: 0.24,
  line-h: 0.5,
  slack: 0.1,
  lead: 0.4,
  label-lead: 0.39,
)

#let styles = _ => (render: label => [#label], align: left)

#let legend = gctx(
  "right",
  "colour",
  span: 10.0,
  text-style: styles,
  place: (frac, across) => (frac * 10.0, -across),
)

// A key that reads beside its label sits at its own radius and reserves its own
// diameter, so a caller states neither.
#assert.eq(metrics.drop, metrics.off)
#assert.eq(key-metrics(off: 0.12).last, 0.24)

// Cumulative overflow: each row is pushed down past every row above it, and the
// total is what the stack grows by.
#let stacked = stack-offsets((0.0, 0.5, 0.0, 0.25))
#assert.eq(stacked.before, (0.0, 0.0, 0.5, 0.5))
#assert.eq(stacked.total, 0.75)

// A row takes the tallest overflow across its columns. In a 2x2 column-major
// grid, entry 2 is row 0 of column 1, so its two extra lines land on row 0.
#let shape22 = (rows: 2, cols: 2)
#let rows22 = row-overflows(
  4,
  i => if i == 2 { 1.0 } else { 0.0 },
  shape22,
  false,
)
#assert.eq(rows22.extra, (1.0, 0.0))
#assert.eq(rows22.total, 1.0)

// Rows that never stack, for a grid whose stride already carries the tallest
// label in the guide.
#assert.eq(flat-rows(3).before, (0.0, 0.0, 0.0))
#assert.eq(flat-rows(3).total, 0.0)

// Each column sizes to its own widest label plus the lead, and the gap grows
// with the widest column once a tenth of it beats the minimum.
#let widths = (0.5, 2.0, 1.0, 0.6)
#let cols = column-widths(4, i => widths.at(i), shape22, false, 0.4)
#assert.eq(cols.widths, (2.4, 1.4))
#assert.eq(cols.gap, COL-GAP-RATIO * 2.4)
#assert.eq(cols.offsets, (0.0, 2.4 + cols.gap))
#assert.eq(cols.total, 2.4 + cols.gap + 1.4)

// Narrow columns keep the floor rather than closing up.
#assert.eq(
  column-widths(2, _ => 0.2, (rows: 1, cols: 2), true, 0.1).gap,
  COL-GAP-MIN,
)

// A size ladder sizes every column alike instead, and a horizontal one packs
// them edge to edge.
#let uniform = uniform-columns(3, 1.5, gap: COL-GAP-MIN)
#let stride = 1.5 + COL-GAP-MIN
#assert.eq(uniform.widths, (1.5, 1.5, 1.5))
#assert.eq(uniform.offsets, (0.0, stride, 2 * stride))
#assert.eq(uniform.total, 3 * 1.5 + 2 * COL-GAP-MIN)
#assert.eq(uniform-columns(3, 1.5).total, 4.5)
#assert.eq(uniform-columns(0, 1.5).total, 0.0)

// The grid a count flows into, and the index mapping both ways.
#assert.eq(grid-shape(5, none, 2, "vertical"), (rows: 3, cols: 2))
#assert.eq(grid-index(1, 1, shape22, false), 3)
#assert.eq(grid-rc(3, shape22, false), (row: 1, col: 1))

// A part is justified inside the guide, a label inside its own column, and a
// label under a key keeps that key's centre.
#assert.eq(align-offset(center, 10.0, 4.0), 3.0)
#assert.eq(pin-right-of(right, 1.0, 2.0), (3.0, "mid-east"))
#assert.eq(pin-below(center, 1.0), (1.0, "north"))
#assert.eq(pin-below(left, 1.0), (1.0, "north-west"))

// The reserved box: as wide as its columns, and a full stride for every row but
// the last, which spends only what that row reserves and the slack below it.
#let entries = (
  entry("a", widths.at(0)),
  entry("b", widths.at(1)),
  entry("c", widths.at(2)),
  entry("d", widths.at(3)),
)
#let keys = prim-keys(
  entries: entries,
  shape: shape22,
  metrics: metrics,
  columns: cols,
  rows: flat-rows(2),
)
#assert.eq(keys.kind, PRIMITIVE)
#let box = registry.measure(keys, legend)
#assert.eq(box.along, cols.total)
#assert.eq(box.across, 0.5 + 0.24 + 0.1)
// A grid reports the length it needs rather than filling what it is given: a
// legend box is sized from its keys, unlike a tick row.
#assert.eq(box.fills, false)

// A multi-line label deepens only the row it lands in, and the whole box grows
// by exactly what that row stacked.
#let wrapped = prim-keys(
  entries: entries,
  shape: shape22,
  metrics: metrics,
  columns: cols,
  rows: row-overflows(4, i => if i == 2 { 1.0 } else { 0.0 }, shape22, false),
)
#assert.eq(registry.measure(wrapped, legend).across, box.across + 1.0)

// A horizontal size ladder spends its whole stride on every row, including the
// last, which is what `last` carries and why it reserves no slack.
#let below = prim-keys(
  entries: entries,
  shape: shape22,
  flow: "below",
  metrics: key-metrics(off: 0.16, drop: 0.32, last: 0.9, line-h: 0.9),
  columns: uniform-columns(2, 1.2),
  rows: flat-rows(2),
)
#assert.eq(registry.measure(below, legend).across, 2 * 0.9)
#assert.eq(registry.measure(below, legend).along, 2 * 1.2)

// An empty grid takes no room at all, including the shape a guide with no
// levels resolves to, which is no rows at all.
#let empty = prim-keys(
  metrics: metrics,
  shape: (rows: 0, cols: 1),
  columns: uniform-columns(1, 0.4),
  rows: flat-rows(0),
)
#assert.eq(registry.measure(empty, legend), measured())

// A grid too small for its keys fails by name. Without this the extra key
// reaches a column that was never sized and fails on a bare missing offset.
#assert.eq(
  error-text(
    "guide-keys",
    "a 1 by 1 grid has no room for 4 keys",
    hint: "Size the shape from the entry count, as `grid-shape` does.",
  ),
  "guide-keys: a 1 by 1 grid has no room for 4 keys. Size the shape from the entry count, as `grid-shape` does.",
)

// A grid record built from another shape is caught where it arrives, for the
// same reason, in every field the walk indexes.
#assert.eq(
  error-text(
    "guide-keys",
    "columns.offsets describes 3 of 2",
    hint: "Build the record from the same shape the keys flow into.",
  ),
  "guide-keys: columns.offsets describes 3 of 2. Build the record from the same shape the keys flow into.",
)

// Both alignments go through the shared guard, so the string "center" fails by
// the name of the field it was passed as rather than silently drawing
// left-aligned.
#assert.eq(
  type-text(
    "guide-keys",
    "justify",
    "center",
    "a Typst alignment `left`, `center`, or `right`",
    hint: "Use the alignment value `left`, not the string \"left\".",
  ),
  "guide-keys: justify must be a Typst alignment `left`, `center`, or `right`; got \"center\". Use the alignment value `left`, not the string \"left\".",
)
// An alignment is still optional, and every legal one is accepted.
#for a in (none, left, center, right) {
  assert.eq(
    prim-keys(
      metrics: metrics,
      columns: uniform-columns(1, 0.4),
      rows: flat-rows(1),
      justify: a,
      label-align: a,
    ).justify,
    a,
  )
}

// Only the two flows the primitive draws are accepted.
#assert.eq(FLOWS, ("right", "below"))
#assert.eq(
  enum-text("guide-keys", "flow", "above", FLOWS),
  "guide-keys: flow must be one of \"right\", \"below\"; got \"above\".",
)

// The metrics are taken as a whole record, so a half-built one fails where it
// is supplied rather than as a missing key inside the layout.
#assert.eq(
  type-text(
    "guide-keys",
    "metrics",
    (:),
    "the record `key-metrics` builds",
    hint: "Build it with `key-metrics`, which carries "
      + METRIC-FIELDS.join(", ")
      + ".",
  ),
  "guide-keys: metrics must be the record `key-metrics` builds; got (:). Build it with `key-metrics`, which carries off, drop, last, line-h, slack, lead, label-lead, label-drop.",
)

// An entry has to carry what the walk reads, and only that: the value its glyph
// is inked from, and the label beside it. The label geometry the render stage
// stamps is its own input to the records above, so it is not demanded here.
#assert.eq(
  error-text(
    "guide-keys",
    "entry 0 carries no `label`",
    hint: "Use `label: none` for a key that shows no label.",
  ),
  "guide-keys: entry 0 carries no `label`. Use `label: none` for a key that shows no label.",
)
#assert.eq(
  registry
    .measure(
      prim-keys(
        entries: ((value: "a", label: none),),
        shape: (rows: 1, cols: 1),
        metrics: metrics,
        columns: uniform-columns(1, 0.4),
        rows: flat-rows(1),
      ),
      legend,
    )
    .along,
  0.4,
)

// A context with no span could only put every key at the near edge, so the
// grid refuses to draw under one.
#assert.eq(
  error-text(
    "guide-keys",
    "the context spans none centimetres",
    hint: "A key grid places itself in centimetres; pass `span:` on the "
      + "context it draws under.",
  ),
  "guide-keys: the context spans none centimetres. A key grid places itself in centimetres; pass `span:` on the context it draws under.",
)

Guide-keys tests passed.
