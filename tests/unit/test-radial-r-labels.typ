// The radial axis labels a spoke rather than an edge: each break sits on the
// radius at the fraction of `r-max` it marks, and a break outside the circle is
// not drawn at all. These pin the table the labels are built from, which is
// what says where each one lands.

#import "../../lib.typ": *
#import "../../src/render/panel-radial.typ": _r-entries

// A continuous r scale over 0 to 10, drawn into a circle of radius 4cm. The
// stand-in stays a plain trained record: the table is arithmetic on the mapped
// radius, and a real scale would only add a training step to read.
#let TRAINED = (type: "continuous", domain: (0, 10))
#let R-MAX = 4.0
#let R-RANGE = (0.0, R-MAX)
#let DISP = (labels: auto, typst-mark: false)
#let TEXT = (size: 9pt, typst: false)
#let EXT = (width: 0.6, height: 0.3)

#let rows-of(
  trained: TRAINED,
  style: TEXT,
  r-max: R-MAX,
  r-range: R-RANGE,
) = _r-entries(trained, DISP, style, r-max, r-range, EXT)

// One row per break, at the fraction of the radius the break maps to: the
// mapped radius over `r-max` is what `place-r` multiplies back out.
#{
  let rows = rows-of()
  assert(rows.len() > 0, message: "a trained r scale carried no labels")
  for row in rows {
    assert(
      row.frac >= 0.0 and row.frac <= 1.0,
      message: "a row landed outside the circle at " + repr(row.frac),
    )
    assert.eq(row.width, EXT.width)
    assert.eq(row.height, EXT.height)
    assert(row.label != none, message: "a row carried no label")
  }
  // The breaks run up the domain, so the fractions do too.
  assert.eq(rows.map(r => r.frac), rows.map(r => r.frac).sorted())
}

// A range wider than the circle pushes its outer breaks past `r-max`, and those
// rows are dropped rather than drawn outside it.
#{
  let inside = rows-of()
  let overflowing = rows-of(r-range: (0.0, 2 * R-MAX))
  assert(
    overflowing.len() < inside.len(),
    message: "a break past the circle was still labelled",
  )
  for row in overflowing {
    assert(
      row.frac <= 1.0,
      message: "a dropped row was kept at " + repr(row.frac),
    )
  }
}

// A circle with no radius labels nothing, rather than dividing by it.
#assert.eq(rows-of(r-max: 0.0).len(), 0)

// A blank `axis-text` draws no labels, so it builds no rows either.
#assert.eq(rows-of(style: (size: 0pt, typst: false)).len(), 0)

// The radial labels are a continuous-scale feature: a discrete r scale, and an
// axis that never trained, both label nothing.
#assert.eq(rows-of(trained: (type: "discrete", levels: ("a", "b"))).len(), 0)
#assert.eq(rows-of(trained: none).len(), 0)

Radial r-label tests passed.
