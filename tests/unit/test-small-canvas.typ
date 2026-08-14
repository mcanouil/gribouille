// A plot draws at any positive size, down to the sparkline dimensions a table
// cell offers. Getting there means a stripped axis reserving nothing at all:
// the panel-to-band gap and the title-to-edge pad are owed only when there is a
// band or a title to hold off the edge, and `theme-void` paints no
// plot-background padding. Together those are more than half a centimetre per
// axis, which is what used to make sub-centimetre plots impossible.

#import "../../lib.typ": *
#import "../../src/coord/radial.typ": coord-radial
#import "../../src/render/chrome.typ": _chrome-margins
#import "../../src/render/extents.typ": _TICK-LABEL-GAP
#import "../../src/theme/defaults.typ": merge-theme
#import "../../src/theme/theme.typ": _rect-style

#let approx-eq(a, b, eps: 1e-9) = calc.abs(a - b) < eps

// Rounding in the chrome arithmetic is sub-point; anything larger is overflow.
#let SLACK = 0.5pt

#let trained-axis = (type: "continuous", domain: (0, 100), spec: (:))

#let chrome-of(theme: none, coord: none, guides: (:)) = _chrome-margins((
  spec: (mapping: none, guides: guides, coord: coord),
  theme: merge-theme(theme),
  trained: (x: trained-axis, y: trained-axis),
  coord: coord,
  guides: (),
  extents: (top: 0.0, right: 0.0, bottom: 0.0, left: 0.0, inside: ()),
  legend-gap: 0.0,
  width-units: 10.0,
  height-units: 8.0,
  facet-grid-mode: false,
  faceted: false,
  panel-n-cols: 1,
  panel-n-rows: 1,
  free-x: false,
  free-y: false,
  grid-n-rows: 1,
  grid-n-cols: 1,
  panel-trained-list: (),
  margin-override: none,
))

// Label measurement needs a known context, so every chrome call runs inside one.
#context {
  // The control: a default theme draws ticks, labels, and titles, so it
  // reserves a band on the two primary sides and a gap to hold it off the edge.
  let default-chrome = chrome-of()
  for side in ("bottom", "left") {
    assert(
      default-chrome.margin.at(side) > _TICK-LABEL-GAP,
      message: (
        "a default theme reserves only "
          + repr(default-chrome.margin.at(side))
          + " cm on the "
          + side
      ),
    )
  }

  // `theme-void` draws nothing outside the panel, so it reserves nothing: the
  // whole canvas is panel. This is the assertion the sparkline case rests on.
  let void-chrome = chrome-of(theme: theme-void())
  for side in ("top", "right", "bottom", "left") {
    assert(
      approx-eq(void-chrome.margin.at(side), 0.0),
      message: (
        "theme-void reserves "
          + repr(void-chrome.margin.at(side))
          + " cm on the "
          + side
          + ", and should reserve nothing"
      ),
    )
  }

  // A stripped theme draws no tick labels, so none of them reaches past a panel
  // edge and the overhang floor is exactly nothing. The sparkline cases below
  // rest on that: a floor that fired here would take panel back from a canvas
  // that has none to spare.
  for side in ("top", "right", "bottom", "left") {
    assert.eq(void-chrome.overhang.at(side), 0.0)
  }
  // The floor is spent before it is reserved on the two sides that already
  // hold a band: an x label reaching left lands in the y-axis margin.
  let recorded = chrome-of()
  for side in ("bottom", "left") {
    assert(
      recorded.margin.at(side) > recorded.overhang.at(side),
      message: "the "
        + side
        + " band should already cover the reach, got "
        + repr(recorded.overhang.at(side))
        + " against "
        + repr(recorded.margin.at(side)),
    )
  }

  // A radial panel is the one exception. It reserves no band, because its theta
  // labels ring the inside of the panel edge rather than sitting outside it,
  // but that ink is up against the edge and still owes it the gap.
  let radial-chrome = chrome-of(coord: coord-radial())
  for side in ("top", "right", "bottom", "left") {
    assert.eq(radial-chrome.overhang.at(side), 0.0)
  }
  for side in ("bottom", "left") {
    assert(
      radial-chrome.margin.at(side) >= _TICK-LABEL-GAP,
      message: (
        "a radial panel reserves "
          + repr(radial-chrome.margin.at(side))
          + " cm on the "
          + side
          + ", less than the gap its theta labels need"
      ),
    )
  }

  // `guides(x: none, y: none)` reclaims the gap on the default theme too, so
  // the rule is about the band being absent rather than about `theme-void`
  // specifically. It frees strictly more than the gap, since the band goes with
  // it.
  let bare = chrome-of(guides: guides(x: none, y: none))
  for side in ("bottom", "left") {
    assert(
      bare.margin.at(side) < default-chrome.margin.at(side) - _TICK-LABEL-GAP,
      message: (
        "suppressing the axes freed only "
          + repr(default-chrome.margin.at(side) - bare.margin.at(side))
          + " cm on the "
          + side
      ),
    )
  }
}

// `theme-void` reserves no plot-background padding either, on both the
// transparent and the explicitly-painted branch. The 5pt-per-side default that
// `element-rect` ships is a third of a centimetre off each dimension, which at
// sparkline sizes is the difference between drawing and failing.
#for (name, thm) in (
  ("transparent", theme-void()),
  ("painted", theme-void(paper: rgb("#f7f0e7"))),
) {
  let inset = _rect-style(merge-theme(thm), "plot-background").inset-cm
  for side in ("top", "right", "bottom", "left") {
    assert.eq(
      inset.at(side),
      0,
      message: (
        "theme-void("
          + name
          + ") pads its plot-background by "
          + repr(inset.at(side))
          + " cm on the "
          + side
      ),
    )
  }
}

#let spark(width, height) = plot(
  data: (x: range(0, 12), y: range(0, 12).map(i => calc.rem(i * 7, 13))),
  mapping: aes(x: "x", y: "y"),
  layers: (geom-line(),),
  guides: guides(default: none),
  theme: theme-void(),
  width: width,
  height: height,
)

// The point of the exercise: a plot at the size a table cell offers. 4em by
// 0.8em at a 10pt text size is roughly 1.41cm by 0.28cm, well under the half
// centimetre that used to be the floor.
#context {
  let (w, h) = (4em.to-absolute(), 0.8em.to-absolute())
  let m = measure(spark(w, h))
  assert(
    m.width <= w + SLACK and m.height <= h + SLACK,
    message: (
      "a sparkline asked for "
        + repr(w)
        + " x "
        + repr(h)
        + " measured "
        + repr(m.width)
        + " x "
        + repr(m.height)
    ),
  )
  // Sized down, not cropped: the drawn figure fills the box it was given.
  assert(
    m.width >= w - SLACK and m.height >= h - SLACK,
    message: (
      "a sparkline asked for "
        + repr(w)
        + " x "
        + repr(h)
        + " only filled "
        + repr(m.width)
        + " x "
        + repr(m.height)
    ),
  )
}

// A millimetre square is degenerate but not empty, so it draws rather than
// failing. Nothing below this is reachable without a zero or negative canvas.
#context {
  let m = measure(spark(1mm, 1mm))
  assert(
    m.width <= 1mm + SLACK and m.height <= 1mm + SLACK,
    message: "a 1mm square plot measured "
      + repr(m.width)
      + " x "
      + repr(m.height),
  )
}

// Chrome the panel cannot pay for squeezes it to nothing, and a panel of no
// width has no aspect ratio to hold: `coord-fixed` has to hand the degenerate
// box back rather than divide by it. Long tick labels are the sharp case: their
// band is not capped against the canvas, by design, because a plot the axes
// alone fill draws an empty panel rather than failing.
#let squeezed(width) = plot(
  data: (x: (1, 2, 3), y: (1, 2, 3)),
  mapping: aes(x: "x", y: "y"),
  layers: (geom-point(),),
  scales: scales(y: scale-continuous(labels: v => "Very-long-label-" + str(v))),
  coord: coord-fixed(),
  width: width,
  height: 3cm,
)

// Only that it draws at all is asserted here; what changed is that the panel
// between the margins can now be nothing.
#context {
  for width in (1cm, 0.8cm, 0.6cm) {
    let m = measure(squeezed(width))
    assert(
      m.width > 0pt and m.height > 0pt,
      message: (
        "a squeezed coord-fixed plot "
          + repr(width)
          + " wide measured "
          + repr(m.width)
          + " x "
          + repr(m.height)
      ),
    )
  }
}

// The same layout with a legend, at a width that holds it: `coord-fixed` and a
// side legend still meet, and the fit check must not fire on a plot that fits.
#context {
  let m = measure(plot(
    data: (
      x: (1, 2, 3),
      y: (1, 2, 3),
      g: ("alpha-long-level", "beta-long-level", "gamma-long-level"),
    ),
    mapping: aes(x: "x", y: "y", colour: "g"),
    layers: (geom-point(),),
    guides: guides(colour: guide-legend(position: left)),
    coord: coord-fixed(),
    width: 8cm,
    height: 5cm,
  ))
  assert(
    m.width <= 8cm + SLACK and m.height <= 5cm + SLACK,
    message: "a coord-fixed plot with a left legend measured "
      + repr(m.width)
      + " x "
      + repr(m.height),
  )
}

Small canvas tests passed.
