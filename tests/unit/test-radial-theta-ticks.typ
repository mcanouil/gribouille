// A radial panel draws its theta tick marks outward from the circle, so the
// circle owes them the same kind of band it owes the labels ringing it. These
// tests pin what the band costs, which surface it is read from, and that a
// weight which never draws costs nothing.

#import "../../lib.typ": *
#import "../../src/theme/defaults.typ": merge-theme
#import "../../src/render/guides.typ": _read-theta-guide
#import "../../src/render/panel-radial.typ": _theta-tick-marks
#import "../../src/utils/radial.typ": THETA-LABEL-PAD, radial-ctx

#let PANEL = (px: (0.0, 6.0), py: (0.0, 5.0))

// Stand-in for the trained sweep scale: the marks resolve off the theme, but
// an axis that never trained draws nothing and so reserves nothing.
#let TRAINED = (type: "continuous", domain: (0, 1))

#let r-of(bounds: (), tick-cm: 0.0) = {
  radial-ctx(
    coord-radial(),
    (type: "continuous", domain: (0, 1)),
    (type: "continuous", domain: (0, 1)),
    PANEL.px,
    PANEL.py,
    label-bounds: bounds,
    tick-cm: tick-cm,
  ).r-max
}

// An unlabelled circle is the inscribed one, so the ticks come straight off
// the short half-span: nothing else is holding radius back.
#{
  let plain = r-of()
  assert.eq(plain, 2.5)
  assert(
    calc.abs(r-of(tick-cm: 0.3) - 2.2) < 1e-9,
    message: "a 0.3cm tick left r-max at " + repr(r-of(tick-cm: 0.3)),
  )
}

// With a label the tick costs exactly its own length on top of the label
// band, and the label centre does not move: it still sits at
// `r-max + tick + pad`, which is where it sat before the tick existed.
#{
  let top = ((theta: calc.pi / 2, hw: 1.2, hh: 0.16),)
  let bare = r-of(bounds: top)
  let ticked = r-of(bounds: top, tick-cm: 0.3)
  assert(
    calc.abs(bare - (2.5 - 0.16 - THETA-LABEL-PAD)) < 1e-9,
    message: "an unticked label left r-max at " + repr(bare),
  )
  assert(
    calc.abs(ticked - (bare - 0.3)) < 1e-9,
    message: "a 0.3cm tick under a label left r-max at " + repr(ticked),
  )
  assert(
    calc.abs((ticked + 0.3 + THETA-LABEL-PAD) - (bare + THETA-LABEL-PAD))
      < 1e-9,
    message: "the label centre moved when the tick appeared",
  )
}

// The radius can be spent but never overdrawn: a tick longer than the panel
// leaves nothing rather than a circle of negative radius.
#assert.eq(r-of(tick-cm: 9.0), 0)

// The theta ticks are read off the axis the sweep runs along, not off `x`:
// a pie puts theta on `y`, so a `y`-only tick surface has to reach it and an
// `x`-only one must not.
#{
  let ticked-y = merge-theme(theme(
    axis-ticks-y: element-tick(colour: black, stroke: 0.5pt, length: 0.4cm),
  ))
  let sweep-on-y = _theta-tick-marks(ticked-y, "y", none, TRAINED)
  assert(
    calc.abs(sweep-on-y.reach - 0.4) < 1e-9,
    message: "a pie read its theta ticks as " + repr(sweep-on-y.reach),
  )
  // `x` keeps the inherited base length, so it cannot have read the `y` one.
  assert(
    calc.abs(_theta-tick-marks(ticked-y, "x", none, TRAINED).reach - 0.1)
      < 1e-9,
    message: "a rose read the y-axis tick surface",
  )
}

// A blank surface draws nothing, so it must not hold radius back either. This
// is the shipped default: `theme-minimal` blanks `axis-ticks`.
#{
  let marks = _theta-tick-marks(merge-theme(none), "x", none, TRAINED)
  assert.eq(marks.reach, 0.0)
  assert.eq(marks.major, none)
}

// An untrained sweep draws no tick, so it must not reserve one either.
#{
  let ticked = merge-theme(theme(
    axis-ticks: element-tick(colour: black, stroke: 0.5pt, length: 0.4cm),
  ))
  assert.eq(_theta-tick-marks(ticked, "x", none, none).reach, 0.0)
}

// `_read-theta-guide` reads a plot spec, so a bare `guides()` call needs
// wrapping in one.
#let theta-guide-of(gs) = _read-theta-guide((guides: gs))

// `guides(theta: none)` hides the whole angular axis, ticks with it.
#{
  let ticked = merge-theme(theme(
    axis-ticks: element-tick(colour: black, stroke: 0.5pt, length: 0.4cm),
  ))
  let suppressed = theta-guide-of(guides(theta: none))
  assert.eq(_theta-tick-marks(ticked, "x", suppressed, TRAINED).reach, 0.0)
}

// Minor ticks are opt-in through the guide and read the `axis-ticks-minor`
// surface, which halves the major length by default. The reach is the longer
// of the two weights, since both are drawn from the same circle.
#{
  let ticked = merge-theme(theme(
    axis-ticks: element-tick(colour: black, stroke: 0.5pt, length: 0.4cm),
  ))
  let minors-on = theta-guide-of(guides(
    theta: guide-axis-theta(minor-ticks: true),
  ))

  let off = _theta-tick-marks(ticked, "x", theta-guide-of(guides()), TRAINED)
  assert.eq(off.minor, none)
  assert(calc.abs(off.reach - 0.4) < 1e-9, message: repr(off.reach))

  let on = _theta-tick-marks(ticked, "x", minors-on, TRAINED)
  assert(on.minor != none, message: "minor-ticks: true drew no minor stroke")
  assert(
    calc.abs(on.minor-len - 0.2) < 1e-9,
    message: "the minor weight resolved to " + repr(on.minor-len),
  )
  assert(calc.abs(on.reach - 0.4) < 1e-9, message: repr(on.reach))

  // A longer minor than major still fits: the band is the longer of the two.
  let long-minor = merge-theme(theme(
    axis-ticks: element-tick(colour: black, stroke: 0.5pt, length: 0.1cm),
    axis-ticks-minor: element-tick(length: 0.5cm),
  ))
  let both = _theta-tick-marks(long-minor, "x", minors-on, TRAINED)
  assert(calc.abs(both.reach - 0.5) < 1e-9, message: repr(both.reach))
}

// End to end: a themed tick must not push the figure past the size it was
// asked for. The band only works if the draw site and `radial-ctx` agree.
#let SLACK = 0.5pt

#let ticked-plot(
  theta: "x",
  width: 6cm,
  height: 5cm,
  guides: guides(),
  ticks: element-tick(colour: black, stroke: 0.5pt, length: 0.5cm),
) = plot(
  data: (h: range(0, 12), v: range(0, 12).map(i => 10 + calc.rem(i * 7, 13))),
  mapping: aes(x: "h", y: "v"),
  layers: (geom-point(),),
  coord: coord-radial(theta: theta),
  guides: guides,
  theme: theme(
    axis-line: element-line(colour: black, stroke: 0.5pt),
    axis-ticks: ticks,
  ),
  width: width,
  height: height,
)

#let fits(body, width, height, what) = {
  let m = measure(body)
  assert(
    m.width <= width + SLACK,
    message: what + " is " + repr(m.width) + " wide, asked for " + repr(width),
  )
  assert(
    m.height <= height + SLACK,
    message: what
      + " is "
      + repr(m.height)
      + " tall, asked for "
      + repr(height),
  )
}

#context fits(ticked-plot(), 6cm, 5cm, "ticked radial plot")
#context fits(
  ticked-plot(theta: "y", width: 5cm, height: 7cm),
  5cm,
  7cm,
  "ticked pie-orientation plot",
)
#context fits(
  ticked-plot(guides: guides(theta: guide-axis-theta(minor-ticks: true))),
  6cm,
  5cm,
  "ticked radial plot with minor ticks",
)

// Where the marks actually land is a question these assertions cannot answer:
// a plot is content, and two plots built from different specs compare unequal
// whether or not the difference reached the page. The angles and radii are
// covered by the `guide-axis-theta` golden and by the eyeball plot in
// `tests/visual/coord-radial-theta-ticks.typ`.

Radial theta tick tests passed.
