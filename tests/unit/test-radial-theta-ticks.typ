// A radial panel draws its theta tick marks outward from the circle, so the
// circle owes them the same kind of band it owes the labels ringing it. These
// tests pin what the band costs, which surface it is read from, and that a
// weight which never draws costs nothing.

#import "../../lib.typ": *
#import "../../src/theme/defaults.typ": merge-theme
#import "../../src/render/guides.typ": (
  _THETA-CAP-FRAC, _THETA-CAP-MAX-RAD, _read-theta-guide,
)
#import "../../src/render/panel-radial.typ": _arc-span, theta-band
#import "../../src/utils/radial.typ": THETA-LABEL-PAD, radial-ctx

#let PANEL = (px: (0.0, 6.0), py: (0.0, 5.0))

// Stand-in for the trained sweep scale: the marks resolve off the theme, but
// an axis that never trained draws nothing and so reserves nothing.
#let TRAINED = (type: "continuous", domain: (0, 1))

// The band the angular axis reserves, over a sweep whose labels are blanked:
// these tests are about the tick weights, and a label ringing the circle is
// solved per angle rather than as part of the band.
#let BLANK-TEXT = (size: 0pt, typst: false)
#let band-of(theme, axis, guide, trained: TRAINED, text: BLANK-TEXT) = (
  theta-band(
    theme,
    coord-radial(theta: axis),
    guide,
    trained,
    axis,
    (labels: auto, typst-mark: false),
    text,
    (width: 0.6, height: 0.3),
  )
)

// The sub-decade rows a band carries, which is what says whether a minor weight
// is drawn at all.
#let minors-of(band) = if band.node == none { () } else {
  band.node.entries.filter(e => e.at("tier", default: "major") == "minor")
}

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
  let sweep-on-y = band-of(ticked-y, "y", none)
  assert(
    calc.abs(sweep-on-y.reach - 0.4) < 1e-9,
    message: "a pie read its theta ticks as " + repr(sweep-on-y.reach),
  )
  // `x` keeps the inherited base length, so it cannot have read the `y` one.
  assert(
    calc.abs(band-of(ticked-y, "x", none).reach - 0.1) < 1e-9,
    message: "a rose read the y-axis tick surface",
  )
}

// A blank surface draws nothing, so it must not hold radius back either. This
// is the shipped default: `theme-minimal` blanks `axis-ticks`.
#{
  let band = band-of(merge-theme(none), "x", none)
  assert.eq(band.reach, 0.0)
}

// An untrained sweep draws no tick, so it must not reserve one either.
#{
  let ticked = merge-theme(theme(
    axis-ticks: element-tick(colour: black, stroke: 0.5pt, length: 0.4cm),
  ))
  assert.eq(band-of(ticked, "x", none, trained: none).reach, 0.0)
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
  assert.eq(band-of(ticked, "x", suppressed).reach, 0.0)
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

  let off = band-of(ticked, "x", theta-guide-of(guides()))
  assert.eq(minors-of(off).len(), 0)
  assert(calc.abs(off.reach - 0.4) < 1e-9, message: repr(off.reach))

  let on = band-of(ticked, "x", minors-on)
  assert(
    minors-of(on).len() > 0,
    message: "minor-ticks: true carried no minor row",
  )
  // A minor bisects each gap between majors, and a full turn closes the ring,
  // so a sweep with four gaps between five breaks bisects all four.
  assert.eq(minors-of(on).len(), 4)
  assert(calc.abs(on.reach - 0.4) < 1e-9, message: repr(on.reach))

  // A longer minor than major still fits: the band is the longer of the two.
  let long-minor = merge-theme(theme(
    axis-ticks: element-tick(colour: black, stroke: 0.5pt, length: 0.1cm),
    axis-ticks-minor: element-tick(length: 0.5cm),
  ))
  let both = band-of(long-minor, "x", minors-on)
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

// A cap fades the arc out short of the end it names and leaves the other end
// whole. The trim is a fraction of the span, bounded in radians.
#{
  let turn = 2 * calc.pi
  let trim = calc.min(turn * _THETA-CAP-FRAC, _THETA-CAP-MAX-RAD) / turn
  assert.eq(_arc-span(none, turn), (lo: 0.0, hi: 1.0))
  assert.eq(_arc-span((cap: "none"), turn), (lo: 0.0, hi: 1.0))
  assert.eq(_arc-span((cap: "lower"), turn), (lo: trim, hi: 1.0))
  assert.eq(_arc-span((cap: "upper"), turn), (lo: 0.0, hi: 1.0 - trim))
  assert.eq(_arc-span((cap: "both"), turn), (lo: trim, hi: 1.0 - trim))
  // A sweep of no width has nothing to trim, and dividing by it would fail.
  assert.eq(_arc-span((cap: "both"), 0), (lo: 0.0, hi: 1.0))
}

// A capped end keeps its tick label and gives up its tick mark: the cap has
// just opened a gap in the arc, and a tick would float in it.
#{
  let ticked = merge-theme(theme(
    axis-ticks: element-tick(colour: black, stroke: 0.5pt, length: 0.4cm),
  ))
  let capped = theta-guide-of(guides(theta: guide-axis-theta(cap: "both")))
  let rows = band-of(ticked, "x", capped, text: (size: 9pt, typst: false))
    .node
    .entries
  let unticked = rows.filter(e => e.tier == none)
  assert(unticked.len() > 0, message: "a capped end still carried a tick")
  assert(
    unticked.all(e => e.label != none),
    message: "a capped end dropped the label it still draws",
  )
  // The ends are the only rows that give up their tick; every other break
  // keeps one.
  assert(
    rows.filter(e => e.tier == "major").len() > 0,
    message: "a capped axis dropped every tick",
  )
}

Radial theta tick tests passed.
