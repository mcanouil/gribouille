// Smoke render: the guide primitives drawn straight onto a bare cetz canvas,
// with no plot around them.
//
// Each primitive draws from its own edge outward and knows nothing about its
// neighbours. The first panel is stacked by a composition, which measures each
// part and hands the next an edge past everything before it. The second panel
// places two label rows directly, to isolate the label geometry from the
// stacking.
//
// Read the first panel for the side mirroring: every tick points away from the
// rectangle, labels sit outside their edge, and each title clears its labels.
// The bottom and top should mirror, as should the left and right. Read the
// second panel for the two paths a flat single row cannot show: turned labels
// whose ink stays under its break, and dodged labels cycling through their rows
// rather than drifting outward.

#import "../../src/deps.typ": cetz
#import "../../src/guide/gctx.typ": gctx, place-cartesian
#import "../../src/guide/entry.typ": entries-manual, train-entries
#import "../../src/guide/compose.typ": compose-stack, draw, layout-of, train
#import "../../src/guide/primitive/labels.typ": prim-labels
#import "../../src/guide/primitive/line.typ": prim-line
#import "../../src/guide/primitive/ticks.typ": prim-ticks
#import "../../src/guide/primitive/title.typ": prim-title
#import "../../src/guide/primitive/registry.typ" as registry
#import "../../src/theme/theme.typ": _line-stroke, _tick-length
#import "../../src/theme/defaults.typ": default-theme, resolve-colour

#set page(width: auto, height: auto, margin: 0.5cm)

#let th = default-theme
#let ink = resolve-colour(th, "ink")
#let len-of = surface => _tick-length(th, surface) / 1cm
#let stroke-of = surface => _line-stroke(th, surface, fallback-colour: ink)
#let styles = _ => (render: label => text(7pt)[#label], align: left)

// Five breaks across the span, so the ends and the middle are both visible.
// Each carries the ink extents the render stage would have measured, since a
// label primitive reads them rather than measuring text itself.
#let rows = train-entries(
  entries-manual((0, 1, 2, 3, 4), labels: v => str(v * 25)),
  v => v / 4,
).map(e => (..e, width: 0.5, height: 0.3))

// Build a context whose `place` is pushed `lead` cm further from the panel, so
// a primitive drawn through it sits past whatever came before.
#let shifted(position, aesthetic, px, py, lead) = {
  let base = place-cartesian(position, px, py)
  gctx(
    position,
    aesthetic,
    tick-length: len-of,
    surface-stroke: stroke-of,
    text-style: styles,
    place: (frac, across) => base(frac, across + lead),
  )
}

#cetz.canvas({
  import cetz.draw: rect

  let px = (1.0, 6.0)
  let py = (1.0, 4.0)
  rect((px.at(0), py.at(0)), (px.at(1), py.at(1)), stroke: 0.4pt + luma(70%))

  for (position, aesthetic) in (
    ("bottom", "x"),
    ("top", "x"),
    ("left", "y"),
    ("right", "y"),
  ) {
    // The composition does the stacking: it measures each part and hands the
    // next one an edge past everything before it.
    let ctx = shifted(position, aesthetic, px, py, 0.0)
    let axis = train(
      compose-stack(
        prim-line(),
        prim-ticks(),
        prim-labels(),
        prim-title(text(7pt)[#position], align: center, extent: (1.0, 0.3)),
        spacing: 0.1,
      ),
      inherited: rows,
    )
    draw(axis, ctx, layout-of(axis, ctx))
  }

  // Turned and dodged labels, each under its own panel.
  let px2 = (9.0, 14.0)
  for (i, (angle, n-dodge)) in ((45, 1), (0, 3)).enumerate() {
    let py2 = (1.0 + i * 3.4, 2.5 + i * 3.4)
    rect(
      (px2.at(0), py2.at(0)),
      (px2.at(1), py2.at(1)),
      stroke: 0.4pt + luma(70%),
    )
    let at-edge = shifted("bottom", "x", px2, py2, 0.0)
    registry.draw(prim-ticks(), at-edge, entries: rows)
    let ticks-deep = registry.measure(prim-ticks(), at-edge, entries: rows)
    registry.draw(
      prim-labels(angle: angle, n-dodge: n-dodge),
      shifted("bottom", "x", px2, py2, ticks-deep.across + 0.1),
      entries: rows,
    )
  }
})
