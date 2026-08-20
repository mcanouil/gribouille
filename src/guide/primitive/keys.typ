///! A legend's key grid: every glyph and its label, in rows and columns.
///!
///! Ported from `_draw-swatch` in `render/legend.typ` and from the width and
///! height estimates that reserve the room it draws into. The three shared a
///! grid computed three times over and kept in step by comment; here the grid is
///! computed from one set of formulas in `src/guide/grid.typ` and the estimates
///! are what this primitive measures.
///!
///! This is the one primitive that is not a band. A tick row or a label row runs
///! along the guide and has a single thickness; a key grid has a width per
///! column, an offset per row, and a glyph beside a label in every cell. No
///! stack of primitives can express that, so the grid is one primitive that owns
///! the whole of it.
///!
///! Nothing is measured here. The render stage stamps each entry with the extent
///! of its label and hands the glyph draw down as a closure on the context,
///! because the aesthetic bundle a glyph is inked from lives with the scales,
///! downstream of this module.

#import "../../deps.typ": cetz
#import "../../utils/errors.typ": check, fail-type
#import "../entry.typ": check-grid-entries
#import "../grid.typ": (
  align-offset, column-widths, grid-rc, pin-right-of, row-overflows,
)
#import "../surface.typ": surface-for
#import "common.typ": NOTHING, measured, primitive

// `metrics` is the record `grid.key-metrics` builds; `shape` the `(rows, cols)`
// the keys flow into. `label-align` justifies a label inside its own column and
// `justify` justifies the whole grid inside the guide, which is what puts a
// horizontal legend's keys under the centre of its title.
#let prim-keys(
  entries: auto,
  shape: (rows: 1, cols: 1),
  byrow: false,
  key: "rect",
  metrics: none,
  angle: 0,
  label-align: none,
  justify: none,
) = {
  if (
    type(shape) != dictionary or ("rows", "cols").any(k => k not in shape)
  ) {
    fail-type(
      "guide-keys",
      "shape",
      shape,
      "a dictionary with `rows` and `cols`",
    )
  }
  if type(metrics) != dictionary {
    fail-type(
      "guide-keys",
      "metrics",
      metrics,
      "the record `key-metrics` builds",
    )
  }
  primitive(
    "keys",
    entries: entries,
    shape: shape,
    byrow: byrow,
    key: key,
    metrics: metrics,
    angle: angle,
    label-align: label-align,
    justify: justify,
  )
}

// The table this grid draws, checked at the boundary between the builder that
// stamped it and the primitive that reads it back.
#let _rows-of(prim, inherited) = {
  let own = prim.at("entries", default: auto)
  let rows = if own != auto { own } else if (
    inherited == auto or inherited == none
  ) { () } else { inherited }
  if rows.len() == 0 { return () }
  check-grid-entries(rows, "guide-keys")
}

// The column widths and the row overflows, from the extents the render stage
// stamped. Measure and draw both read this, so the room and the ink come from
// one grid.
#let _grid-of(prim, rows) = {
  let m = prim.metrics
  (
    columns: column-widths(
      rows.len(),
      i => rows.at(i).width,
      prim.shape,
      prim.byrow,
      m.lead,
    ),
    stack: row-overflows(
      rows.len(),
      i => (rows.at(i).lines - 1) * m.line-h,
      prim.shape,
      prim.byrow,
    ),
  )
}

// A grid is as wide as its columns and as deep as its rows: a full stride for
// every row but the last, which spends only the glyph and a slack below it, plus
// whatever the multi-line rows added.
//
// It reports a length of its own rather than filling: a legend box is sized from
// its keys, unlike a tick row, which is as long as the axis it sits on.
#let measure(prim, gctx, entries: auto) = {
  let rows = _rows-of(prim, entries)
  if rows.len() == 0 { return NOTHING }
  let m = prim.metrics
  let (columns, stack) = _grid-of(prim, rows)
  measured(
    across: (prim.shape.rows - 1) * m.line-h + m.diam + m.slack + stack.total,
    along: columns.total,
  )
}

#let draw(prim, gctx, entries: auto) = {
  let rows = _rows-of(prim, entries)
  if rows.len() == 0 { return }
  let place = gctx.at("place", default: none)
  if place == none { return }
  let m = prim.metrics
  let (columns, stack) = _grid-of(prim, rows)
  // The grid lays itself out in centimetres, so it needs to know what a
  // fraction of the guide is worth. A context that never stated one would put
  // every key at the near edge, so it fails here instead.
  let span = gctx.at("span", default: none)
  check(
    type(span) in (int, float) and span > 0,
    "guide-keys",
    "the context spans " + repr(span) + " centimetres",
    hint: "A key grid places itself in centimetres; pass `span:` on the "
      + "context it draws under.",
  )
  let at-cm = (along, across) => place(along / span, across)
  // A horizontal legend centres or right-justifies its grid under its title; a
  // vertical one keeps the near edge, which is what `justify: none` says.
  let indent = if prim.justify == none { 0.0 } else {
    align-offset(prim.justify, span, columns.total)
  }
  let ink-key = gctx.at("key-draw", default: none)
  let surface = surface-for(gctx, "text")
  let styles = gctx.at("text-style", default: none)
  let style = if surface == none or styles == none { none } else {
    (styles)(surface)
  }
  let radius = m.diam / 2
  for (i, e) in rows.enumerate() {
    let rc = grid-rc(i, prim.shape, prim.byrow)
    let start = indent + columns.offsets.at(rc.col)
    // Push the row down past every multi-line row above it, then drop this key
    // half its own overflow, so its block grows downward and the glyph stays
    // centred on the first line.
    let across = (
      rc.row * m.line-h
        + stack.before.at(rc.row)
        + radius
        + stack.extra.at(rc.row) / 2
    )
    if ink-key != none {
      (ink-key)(prim.key, e.value, at-cm(start + radius, across), radius)
    }
    if style == none or e.at("label", default: none) == none { continue }
    let (along, anchor) = pin-right-of(
      prim.label-align,
      start + m.label-lead,
      columns.widths.at(rc.col) - m.lead,
    )
    cetz.draw.content(
      at-cm(along, across),
      (style.render)(e.label),
      anchor: anchor,
      angle: prim.angle * 1deg,
    )
  }
}
