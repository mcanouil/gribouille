// A tick label is centred on its break, so the break nearest a panel edge
// reaches past it. The chrome reserved the label band perpendicular to its own
// axis and nothing along it, so that reach grew the figure past the requested
// `width`/`height`: a six-point scatter at 14mm by 15mm rendered 41.13 x
// 44.74pt against 39.69 x 42.52pt.
//
// The reach is now a floor on the margin, net of the room the opposite band
// already leaves, so the panel shrinks and the figure keeps its size. On a
// plot with room the expansion gap already covers the reach and the floor is
// exactly zero, which is what keeps every existing layout still.

#import "../../lib.typ": *
#import "../../src/render/extents.typ": (
  _label-overhang, _label-reach, _theta-label-bounds, _x-label-anchor,
  _x-label-depth, _y-label-width,
)

// Rounding in the chrome arithmetic is sub-point; anything larger is overflow.
#let SLACK = 0.5pt

#let approx(a, b, tol: 1e-9) = assert(
  calc.abs(a - b) < tol,
  message: repr(a) + " != " + repr(b),
)

#let (W, H) = (2.0, 0.4)

// --- reach: how far a label spreads from the point it is pinned at ---------

// An unrotated x label hangs below its break and spreads either way by half
// its width. That half is the overhang nothing used to reserve.
#let flat = _label-reach(W, H, 0, "north")
#approx(flat.left, W / 2)
#approx(flat.right, W / 2)
#approx(flat.down, H)
#approx(flat.up, 0.0)

// cetz names an anchor on the turned rectangle's own corners, so a rotated
// label swings about its pin: the leading side takes the label's length, the
// trailing side its thickness. Neither is zero.
#context {
  let a = 45deg
  let turned = _label-reach(W, H, 45, "north-east")
  approx(turned.left, W * calc.cos(a))
  approx(turned.right, H * calc.sin(a))
  approx(turned.down, W * calc.sin(a) + H * calc.cos(a))
  // The negative angle mirrors it, which is what keeps a plot readable either
  // way round.
  let mirrored = _label-reach(W, H, -45, "north-west")
  approx(mirrored.right, turned.left)
  approx(mirrored.left, turned.right)
  approx(mirrored.down, turned.down)
}

// A y label hangs left of its break and spreads half its height either way.
#let side = _label-reach(W, H, 0, "mid-east")
#approx(side.left, W)
#approx(side.up, H / 2)
#approx(side.down, H / 2)

// The perpendicular bands the chrome already reserved bound the same reach, so
// the two sides of one label box cannot drift apart. The band measures the
// rotated bounding box and the reach measures from the pin, so the band is
// never the smaller of the two, and at the natural angle the two agree.
#context {
  for deg in range(-90, 91, step: 15) {
    let x = _label-reach(W, H, deg, _x-label-anchor(deg))
    let y = _label-reach(W, H, deg, "mid-east")
    assert(
      x.down <= _x-label-depth(deg, 1, W, H) + 1e-9,
      message: "x reach exceeds its band at " + repr(deg),
    )
    assert(
      y.left <= _y-label-width(deg, 1, W, H) + 1e-9,
      message: "y reach exceeds its band at " + repr(deg),
    )
  }
  approx(_label-reach(W, H, 0, "north").down, _x-label-depth(0, 1, W, H))
  approx(_label-reach(W, H, 0, "mid-east").left, _y-label-width(0, 1, W, H))
  // A corner-pinned label hangs its whole rotated box below the axis, which is
  // exactly the depth the band reserves for it.
  approx(
    _label-reach(W, H, 45, "north-east").down,
    _x-label-depth(45, 1, W, H),
  )
}

// A radial theta label is drawn centred, which is the same helper's `center`
// anchor: the refactor leaves those half-extents where they were.
#context {
  let groups = (
    (theta: 0deg, width: W, height: H),
    (
      theta: 90deg,
      width: 1.0,
      height: 0.3,
    ),
  )
  for deg in (0, 30, 90) {
    for (g, b) in groups.zip(_theta-label-bounds(groups, deg)) {
      let reach = _label-reach(g.width, g.height, deg, "center")
      approx(b.hw, reach.left)
      approx(b.hh, reach.up)
      approx(
        b.hw,
        (
          g.width * calc.abs(calc.cos(deg * 1deg))
            + g.height * calc.abs(calc.sin(deg * 1deg))
        )
          / 2,
      )
    }
  }
}

// No anchor at any angle reaches a negative distance: a negative would let the
// reservation shrink instead of grow.
#context {
  for deg in range(-90, 91, step: 30) {
    for anchor in ("north", "south", "mid-east", "mid-west", "center") {
      let r = _label-reach(W, H, deg, anchor)
      assert(
        r.left >= 0 and r.right >= 0 and r.up >= 0 and r.down >= 0,
        message: "negative reach at " + repr(deg) + " " + anchor,
      )
    }
  }
}

// --- overhang: what that reach costs against a panel ----------------------

#let reach-of = r => (lo: r.width / 2, hi: r.width / 2)
#let zero-pad = (0.0, 0.0)
#let zero-slack = (0.0, 0.0)

// A break in the middle of a roomy panel owes exactly nothing, and exactly is
// the point: the floor has to be the identity on a plot with room.
#let middle = ((frac: 0.5, width: W, height: H),)
#assert.eq(
  _label-overhang(middle, reach-of, 10.0, zero-pad, zero-slack),
  (lo: 0.0, hi: 0.0),
)

// A break flush on the edge, which is what `expand: false` produces, owes its
// whole half-width there and nothing at the far end.
#let flush = ((frac: 0.0, width: W, height: H),)
#context {
  let over = _label-overhang(flush, reach-of, 10.0, zero-pad, zero-slack)
  approx(over.lo, W / 2)
  assert.eq(over.hi, 0.0)
}

// The expansion gap is what covers the reach on a roomy plot, so a wider panel
// owes less until it owes nothing.
#context {
  let near = ((frac: 0.1, width: W, height: H),)
  let tight = _label-overhang(near, reach-of, 4.0, zero-pad, zero-slack)
  let roomy = _label-overhang(near, reach-of, 20.0, zero-pad, zero-slack)
  assert(
    tight.lo > roomy.lo,
    message: "a wider panel should owe less, got "
      + repr(tight.lo)
      + " and "
      + repr(roomy.lo),
  )
  assert.eq(roomy.lo, 0.0)
}

// Canvas the panel does not fill absorbs the reach, which is how `coord-fixed`
// keeps its layout: the panel is pinned bottom-left, so the slack is on the
// far side.
#context {
  let edge = ((frac: 1.0, width: W, height: H),)
  approx(
    _label-overhang(edge, reach-of, 10.0, zero-pad, (0.0, 0.5)).hi,
    W / 2 - 0.5,
  )
  assert.eq(
    _label-overhang(edge, reach-of, 10.0, zero-pad, (0.0, 2.0)).hi,
    0.0,
  )
}

// `view-pad-cm`, the canvas-cm form of expansion, counts against the reach
// exactly as the fractional gap does.
#context {
  assert.eq(
    _label-overhang(flush, reach-of, 10.0, (W, 0.0), zero-slack).lo,
    0.0,
  )
}

// The fold runs over every break, not the outermost: a wide label one break in
// can reach further than a narrow one at the edge.
#context {
  let mixed = (
    (frac: 0.0, width: 0.2, height: H),
    (frac: 0.25, width: 4.0, height: H),
  )
  approx(
    _label-overhang(mixed, reach-of, 2.0, zero-pad, zero-slack).lo,
    2.0 - 0.5,
  )
}

// --- end to end -----------------------------------------------------------

#let d = (a: (1, 2, 3, 4, 5, 6), b: (2, 4, 3, 5, 1, 6), g: ("u", "v", "w") * 2)
#let long = (
  a: ("alpha-level", "beta-level", "gamma-level"),
  b: (2, 4, 3),
)

#let fits(body, width, height, what) = {
  let m = measure(body)
  assert(
    m.width <= width + SLACK and m.height <= height + SLACK,
    message: what + " measured " + repr(m.width) + " x " + repr(m.height),
  )
}

#let scatter(w, h, ..args) = plot(
  data: d,
  mapping: aes(x: "a", y: "b"),
  layers: (geom-point(),),
  width: w,
  height: h,
  ..args,
)

// The reported repro, and the roomy control, which must still fill its box as
// well as fit it: a reservation that fires where it should not would shrink it.
#context {
  fits(scatter(14mm, 15mm), 14mm, 15mm, "a 14 by 15mm scatter")
  fits(scatter(30mm, 15mm), 30mm, 15mm, "a 30 by 15mm scatter")
  let roomy = measure(scatter(60mm, 40mm))
  assert(
    roomy.width <= 60mm + SLACK and roomy.height <= 40mm + SLACK,
    message: "a 60 by 40mm scatter measured " + repr(roomy),
  )
  assert(
    roomy.width >= 60mm - SLACK and roomy.height >= 40mm - SLACK,
    message: "a 60 by 40mm scatter no longer fills its box: " + repr(roomy),
  )
}

// Suppressing one axis fixed one dimension before; both hold now.
#context {
  fits(
    scatter(14mm, 15mm, guides: guides(x: none)),
    14mm,
    15mm,
    "a scatter with no x guide",
  )
  fits(
    scatter(14mm, 15mm, guides: guides(y: none)),
    14mm,
    15mm,
    "a scatter with no y guide",
  )
}

// Without expansion a break lands flush on the panel edge, which is the
// largest reach there is.
#context {
  fits(
    scatter(30mm, 25mm, coord: coord-cartesian(expand: false)),
    30mm,
    25mm,
    "a scatter with no expansion",
  )
}

// A composition carves its panels out of the same canvas, so an overhanging
// label grew the whole stack; `align-panels` forces a shared margin over the
// one each panel solved, which is re-floored against the panel it leaves.
#context {
  let p = defer(
    plot,
    data: d,
    mapping: aes(x: "a", y: "b"),
    layers: (geom-point(),),
  )
  fits(
    compose(p, p, ncolumn: 2, width: 30mm, height: 15mm),
    30mm,
    15mm,
    "a two-panel composition",
  )
  fits(
    compose(p, p, ncolumn: 2, align-panels: true, width: 30mm, height: 15mm),
    30mm,
    15mm,
    "a two-panel composition with aligned panels",
  )
}

// Under facets the outer cells draw the edge axes, so the reservation is
// solved against a cell rather than the whole canvas.
#context {
  fits(
    plot(
      data: d,
      mapping: aes(x: "a", y: "b"),
      layers: (geom-point(),),
      facet: facet-wrap("g"),
      width: 4cm,
      height: 3cm,
    ),
    4cm,
    3cm,
    "a facet-wrap plot",
  )
  fits(
    plot(
      data: d,
      mapping: aes(x: "a", y: "b"),
      layers: (geom-point(),),
      facet: facet-grid(columns: "g"),
      width: 4cm,
      height: 3cm,
    ),
    4cm,
    3cm,
    "a facet-grid plot",
  )
}

// Discrete levels sit a slot pad inside the panel, but a long name still
// reaches past the ends of a narrow one.
#context {
  fits(
    plot(
      data: long,
      mapping: aes(x: "a", y: "b"),
      layers: (geom-col(),),
      width: 4cm,
      height: 3cm,
    ),
    4cm,
    3cm,
    "a discrete axis with long level names",
  )
}

Axis label overhang tests passed.
