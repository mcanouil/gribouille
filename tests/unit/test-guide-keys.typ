// The key grid: the geometry helpers in `src/guide/grid.typ` and the primitive
// that owns the whole grid. The reserved box is asserted against the formulas
// the legend renderer sized a swatch with before the port, on the same inputs,
// so the move is checked mechanically rather than by eye.

#import "../../src/guide/gctx.typ": gctx
#import "../../src/guide/grid.typ": (
  COL-GAP-MIN, COL-GAP-RATIO, METRIC-FIELDS, align-offset, column-widths,
  grid-index, grid-rc, grid-shape, key-metrics, pin-right-of, row-overflows,
  stack-offsets,
)
#import "../../src/guide/primitive/common.typ": PRIMITIVE, measured
#import "../../src/guide/primitive/keys.typ": prim-keys
#import "../../src/guide/primitive/registry.typ" as registry
#import "../../src/utils/errors.typ": error-text, type-text

// One entry per level, carrying the label geometry the render stage stamps.
#let entry(value, width, lines: 1) = (
  value: value,
  label: value,
  width: width,
  lines: lines,
)

#let metrics = key-metrics(
  diam: 0.24,
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

// Each column sizes to its own widest label plus the lead, and the gap grows
// with the widest column once a tenth of it beats the minimum.
#let cols = column-widths(
  4,
  i => (0.5, 2.0, 1.0, 0.6).at(i),
  shape22,
  false,
  0.4,
)
#assert.eq(cols.widths, (2.4, 1.4))
#assert.eq(cols.gap, COL-GAP-RATIO * 2.4)
#assert.eq(cols.offsets, (0.0, 2.4 + cols.gap))
#assert.eq(cols.total, 2.4 + cols.gap + 1.4)

// Narrow columns keep the floor rather than closing up.
#assert.eq(
  column-widths(2, _ => 0.2, (rows: 1, cols: 2), true, 0.1).gap,
  COL-GAP-MIN,
)

// The grid a count flows into, and the index mapping both ways.
#assert.eq(grid-shape(5, none, 2, "vertical"), (rows: 3, cols: 2))
#assert.eq(grid-index(1, 1, shape22, false), 3)
#assert.eq(grid-rc(3, shape22, false), (row: 1, col: 1))

// A part is justified inside the guide, and a label inside its own column.
#assert.eq(align-offset(center, 10.0, 4.0), 3.0)
#assert.eq(pin-right-of(right, 1.0, 2.0), (3.0, "mid-east"))

// The reserved box: as wide as the columns, and a full stride for every row but
// the last, which spends only the glyph and the slack below it.
#let keys = prim-keys(
  entries: (entry("a", 0.5), entry("b", 2.0), entry("c", 1.0), entry("d", 0.6)),
  shape: shape22,
  metrics: metrics,
)
#assert.eq(keys.kind, PRIMITIVE)
#let box = registry.measure(keys, legend)
#assert.eq(box.along, cols.total)
#assert.eq(box.across, 0.5 + 0.24 + 0.1)
// A grid reports the length it needs rather than filling what it is given: a
// legend box is sized from its keys, unlike a tick row.
#assert.eq(box.fills, false)

// A multi-line label deepens only the row it lands in, by one stride per extra
// line, and the whole box grows by exactly that.
#let wrapped = prim-keys(
  entries: (
    entry("a", 0.5),
    entry("b", 2.0),
    entry("c", 1.0, lines: 3),
    entry("d", 0.6),
  ),
  shape: shape22,
  metrics: metrics,
)
#assert.eq(registry.measure(wrapped, legend).across, box.across + 2 * 0.5)

// An empty grid takes no room at all, including the shape a guide with no
// levels resolves to, which is no rows at all.
#assert.eq(registry.measure(prim-keys(metrics: metrics), legend), measured())
#assert.eq(
  registry.measure(
    prim-keys(metrics: metrics, shape: (rows: 0, cols: 1)),
    legend,
  ),
  measured(),
)

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

// Both alignments go through the shared guard, so the string \"center\" fails
// by the name of the field it was passed as rather than silently drawing
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
  assert.eq(prim-keys(metrics: metrics, justify: a, label-align: a).justify, a)
}

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
  "guide-keys: metrics must be the record `key-metrics` builds; got (:). Build it with `key-metrics`, which carries diam, line-h, slack, lead, label-lead.",
)

// A table that never went past the render stage is rejected where it is
// supplied, rather than sizing every column to its glyph.
#assert.eq(
  type-text(
    "guide-keys",
    "entry 0 width",
    none,
    "a number of centimetres of at least 0",
    hint: "The render stage measures each label and stamps its extent on the "
      + "entry.",
  ),
  "guide-keys: entry 0 width must be a number of centimetres of at least 0; got none. The render stage measures each label and stamps its extent on the entry.",
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
