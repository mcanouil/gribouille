// Composition: stacking primitives away from the panel, and the layout record
// that the measure and the draw pass both read.

#import "../../src/guide/gctx.typ": gctx, place-cartesian
#import "../../src/guide/entry.typ": entries-manual, train-entries
#import "../../src/guide/compose.typ": (
  COMPOSITION, compose-stack, draw, layout-of, train,
)
#import "../../src/guide/primitive/labels.typ": prim-labels
#import "../../src/guide/primitive/line.typ": prim-line
#import "../../src/guide/primitive/spacer.typ": prim-spacer
#import "../../src/guide/primitive/ticks.typ": prim-ticks
#import "../../src/guide/primitive/title.typ": prim-title
#import "../../src/utils/errors.typ": error-text, type-text

#let styles = _ => (render: label => [#label], align: left)

#let ctx-for(position, aesthetic) = gctx(
  position,
  aesthetic,
  tick-length: _ => 0.1,
  surface-stroke: _ => 0.5pt + black,
  text-style: styles,
  tick-gap: 0.0,
  place: place-cartesian(position, (2.0, 7.0), (1.0, 5.0)),
)

#let ctx-bottom = ctx-for("bottom", "x")
#let ctx-left = ctx-for("left", "y")

#let rows = train-entries(entries-manual((0, 5, 10)), v => v / 10).map(e => (
  ..e,
  width: 1.0,
  height: 0.4,
))

// Two spacers stack to the sum of their depths, and each starts where the
// previous one ended.
#let two = compose-stack(prim-spacer(0.2), prim-spacer(0.3))
#assert.eq(two.kind, COMPOSITION)
#let flat = layout-of(two, ctx-bottom)
#assert.eq(flat.across, 0.5)
#assert.eq(flat.cells.map(c => c.off-across), (0.0, 0.2))
#assert.eq(flat.cells.map(c => c.drawn), (true, true))

// The same tree on a vertical side measures the same depth: `across` is the
// thickness whichever way the guide runs, which is the whole side-agnosticism
// claim in one assertion.
#assert.eq(layout-of(two, ctx-left).across, 0.5)

// Offsets accumulate monotonically away from the panel.
#let three = compose-stack(
  prim-spacer(0.2),
  prim-spacer(0.3),
  prim-spacer(0.1),
)
#let acc = layout-of(three, ctx-bottom)
#assert.eq(calc.round(acc.across, digits: 9), 0.6)
#assert.eq(acc.cells.map(c => c.off-across), (0.0, 0.2, 0.5))

// Spacing separates neighbours, but only once both of them occupy room.
#let spaced = compose-stack(
  prim-spacer(0.2),
  prim-spacer(0.3),
  spacing: 0.1,
)
#let sp = layout-of(spaced, ctx-bottom)
#assert.eq(
  sp.cells.map(c => calc.round(c.off-across, digits: 9)),
  (0.0, 0.3),
)
#assert.eq(calc.round(sp.across, digits: 9), 0.6)

// A spine draws on the panel edge and has no thickness of its own, so the ticks
// after it still start on that edge. The gap separates depth from depth, and a
// zero-depth child owes none of it.
#let spined = train(
  compose-stack(prim-line(), prim-ticks(), spacing: 0.1),
  inherited: rows,
)
#let sl = layout-of(spined, ctx-bottom)
#assert.eq(sl.cells.first().drawn, true)
#assert.eq(sl.cells.first().measure.across, 0.0)
#assert.eq(sl.cells.last().off-across, 0.0)
#assert.eq(sl.across, 0.1)

// The same holds for a zero-depth child sitting between two thick ones: it
// neither takes a gap nor gives one away.
#let sandwiched = train(
  compose-stack(prim-ticks(), prim-line(), prim-labels(), spacing: 0.1),
  inherited: rows,
)
#let sw = layout-of(sandwiched, ctx-bottom)
#assert.eq(sw.cells.at(1).off-across, 0.1)
#assert.eq(calc.round(sw.cells.at(2).off-across, digits: 9), 0.2)

// A child that reserves nothing takes no offset and no gap, so an axis with its
// ticks blanked puts its labels where the ticks would have started.
#let blank-ctx = gctx(
  "bottom",
  "x",
  tick-length: _ => 0.0,
  surface-stroke: _ => 0.5pt + black,
  text-style: styles,
  tick-gap: 0.0,
  place: place-cartesian("bottom", (2.0, 7.0), (1.0, 5.0)),
)
#let axis = compose-stack(prim-ticks(), prim-labels(), spacing: 0.1)
#let stripped = layout-of(train(axis, inherited: rows), blank-ctx)
#assert.eq(stripped.cells.first().drawn, false)
#assert.eq(stripped.cells.first().off-across, 0.0)
#assert.eq(stripped.cells.last().off-across, 0.0)
// Only the labels reserve, so the band is exactly their depth.
#assert.eq(stripped.across, 0.4)

// With ticks drawn, the labels clear them and the gap applies once.
#let full = layout-of(train(axis, inherited: rows), ctx-bottom)
#assert.eq(full.cells.first().off-across, 0.0)
#assert.eq(calc.round(full.cells.last().off-across, digits: 9), 0.2)
#assert.eq(calc.round(full.across, digits: 9), 0.6)

// Entries flow down to children that did not bring their own, and a child that
// declares its own table keeps it.
#let own = train-entries(entries-manual((1, 2)), v => v / 2)
#let mixed = train(
  compose-stack(prim-ticks(), prim-ticks(entries: own)),
  inherited: rows,
)
#assert.eq(mixed.children.first().entries, rows)
#assert.eq(mixed.children.last().entries, own)
#assert.eq(mixed.entries, rows)

// A closure is as legal on a primitive as on the composition above it, so a
// leaf spec is resolved rather than reaching the primitive unresolved.
#let deferred = train(
  compose-stack(prim-ticks(entries: () => own)),
  inherited: rows,
)
#assert.eq(deferred.children.first().entries, own)

// A composition resolves its own table once and passes that down instead.
#let bound = train(compose-stack(prim-ticks(), entries: own), inherited: rows)
#assert.eq(bound.entries, own)
#assert.eq(bound.children.first().entries, own)

// A nested composition measures as one child, and its layout is kept so the
// draw pass reads it back rather than measuring the subtree twice.
#let nested = compose-stack(
  prim-spacer(0.2),
  compose-stack(prim-spacer(0.3), prim-spacer(0.1)),
)
#let nest = layout-of(nested, ctx-bottom)
#assert.eq(calc.round(nest.across, digits: 9), 0.6)
#assert.eq(calc.round(nest.cells.last().measure.across, digits: 9), 0.4)
#assert.eq(nest.cells.last().layout.cells.len(), 2)
#assert.eq(nest.cells.first().layout, none)

// A guide is as long as its longest child that has a length of its own, and it
// fills when any child fills. The two are never added together.
#let titled = compose-stack(
  prim-ticks(),
  prim-title([Speed], extent: (2.0, 0.3)),
)
#let tl = layout-of(train(titled, inherited: rows), ctx-bottom)
#assert.eq(tl.along, 2.0)
#assert.eq(tl.fills, true)

// Reach is the furthest any child overhangs, not the sum.
#let turned = compose-stack(prim-labels(angle: 30))
#let tr = layout-of(train(turned, inherited: rows), ctx-bottom)
#assert(tr.reach.near > 0.0)
#assert.eq(
  tr.reach.near,
  layout-of(
    train(
      compose-stack(prim-labels(angle: 30), prim-spacer(0.1)),
      inherited: rows,
    ),
    ctx-bottom,
  )
    .reach
    .near,
)

// A measurement-only context carries no `place`, so drawing through one is a
// no-op rather than a panic. The chrome stage measures long before any canvas
// exists, so this path is real.
#let measure-only = gctx("bottom", "x", tick-length: _ => 0.1)
#assert.eq(draw(two, measure-only, layout-of(two, measure-only)), none)

// Rejection wording.
#assert.eq(
  error-text(
    "guide-compose",
    "a stack needs at least one child",
    hint: "Pass the primitives to stack as positional arguments.",
  ),
  "guide-compose: a stack needs at least one child. Pass the primitives to stack as positional arguments.",
)
#assert.eq(
  type-text("guide-compose", "child 0", 3, "a primitive or a composition"),
  "guide-compose: child 0 must be a primitive or a composition; got 3.",
)
#assert.eq(
  error-text(
    "guide-compose",
    "the layout has 2 cells for 3 children",
    hint: "Pass the record `layout-of` returned for this same node.",
  ),
  "guide-compose: the layout has 2 cells for 3 children. Pass the record `layout-of` returned for this same node.",
)

Guide-compose tests passed.
