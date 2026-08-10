// A radial panel draws its theta tick labels outside the circle, at `r-max`
// plus a pad. The circle has to leave them that band inside the panel, or the
// labels land outside it and, since the canvas bounds are the union of
// everything drawn, stretch the figure past the requested `width`/`height`.

#import "../../lib.typ": *
#import "../../src/render/extents.typ": _axis-label-extents
#import "../../src/utils/measure.typ": measure-labels-cm

// Rounding in the chrome arithmetic is sub-point; anything larger is overflow.
#let SLACK = 0.5pt

// Long labels on the angular axis, so the band is worth reserving and a
// failure is unambiguous.
#let LABELS = v => "Hour-number-" + str(v)

#let clock(
  theta: "x",
  width: 6cm,
  height: 5cm,
  guides: guides(),
  theme: none,
) = plot(
  data: (h: range(0, 12), v: range(0, 12).map(i => 10 + calc.rem(i * 7, 13))),
  mapping: aes(x: "h", y: "v"),
  layers: (geom-point(),),
  coord: coord-radial(theta: theta),
  // Only the angular axis gets the long labels: the radial axis draws its own
  // inside the circle, and long ones there would crush the panel through the
  // left margin rather than testing this band.
  scales: scales(
    x: scale-continuous(labels: if theta == "x" { LABELS } else { auto }),
    y: scale-continuous(labels: if theta == "y" { LABELS } else { auto }),
  ),
  guides: guides,
  theme: theme,
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

// Wider than tall, so the circle is bounded by the height and the labels at
// the top and bottom of the sweep are the ones with no slack to fall into.
#context fits(clock(), 6cm, 5cm, "radial plot")

// Taller than wide, which puts the same question to the labels at the sides.
#context fits(clock(width: 5cm, height: 7cm), 5cm, 7cm, "tall radial plot")

// `theta: "y"` reads the angular labels off the other scale, and the pie
// proportions leave the horizontal ones nothing to spare.
#context fits(
  clock(theta: "y", width: 5cm, height: 7cm),
  5cm,
  7cm,
  "pie-orientation radial plot",
)

// Rotated labels present a different bounding box to each side.
#context fits(
  clock(guides: guides(theta: guide-axis-theta(angle: 45))),
  6cm,
  5cm,
  "radial plot with rotated theta labels",
)

// The band is only owed while the labels are drawn: suppressing the theta axis
// or blanking `axis-text` gives it back, so the circle is the one a plot with
// no theta labels would get. Compare against the same plot drawn with a
// blank theta axis rather than asserting a number.
#context {
  fits(
    clock(guides: guides(theta: none)),
    6cm,
    5cm,
    "radial plot with a suppressed theta axis",
  )
  let suppressed = measure(clock(guides: guides(theta: none)))
  let blanked = measure(clock(theme: theme(axis-text-x: element-blank())))
  assert(
    suppressed.width >= blanked.width - SLACK,
    message: (
      "a suppressed theta axis renders "
        + repr(suppressed.width)
        + " wide against "
        + repr(blanked.width)
        + " for a blank one"
    ),
  )
}

// The labels the wrap cases read, short enough that only the merged pair is
// wide enough to spill.
#let HOUR = v => "Hour-" + str(v)

// Two extents in cm are the same band when they agree to within float noise.
#let same-width(got, want, what) = assert(
  calc.abs(got - want) < 1e-9,
  message: what + " measures " + repr(got) + " cm against " + repr(want) + " cm",
)

// A full sweep puts its first and last break on one angle, and the draw merges
// them into a single "24/0" label. That merged label is about twice as wide as
// either break alone, so measuring the breaks one by one reserves too small a
// band and the label spills wherever the sweep happens to wrap.
#let wrap-clock(coord: coord-radial()) = plot(
  data: (h: range(0, 25), v: range(0, 25).map(i => 10 + calc.rem(i * 7, 13))),
  mapping: aes(x: "h", y: "v"),
  layers: (geom-point(),),
  coord: coord,
  scales: scales(
    x: scale-continuous(
      limits: (0, 24),
      breaks: (0, 4, 8, 12, 16, 20, 24),
      expand: false,
      labels: HOUR,
    ),
  ),
  width: 5cm,
  height: 9cm,
)

// The wrap sits at 9 o'clock here and at 3 o'clock there. Either way it is the
// horizontal extreme, where a panel this narrow leaves no slack.
#context fits(
  wrap-clock(coord: coord-radial(start: -calc.pi / 2)),
  5cm,
  9cm,
  "radial plot wrapping at 9 o'clock",
)

#context fits(
  wrap-clock(coord: coord-radial(start: calc.pi / 2, direction: -1)),
  5cm,
  9cm,
  "radial plot wrapping at 3 o'clock",
)

// The band reserved for the merged label is only right if the chrome stage
// measures the merged string, so assert that directly rather than only through
// the figure size.
//
// Only `expand: false` puts two breaks on one angle: the default expansion
// pushes the view out to (-1.2, 25.2), where the sweep endpoints no longer
// coincide. The record carries no `view-transform` for that reason.
#let wrap-trained(labels: HOUR) = (
  type: "continuous",
  domain: (0, 24),
  spec: (breaks: (0, 4, 8, 12, 16, 20, 24), labels: labels),
)

#context {
  let size = 8pt
  let theta = _axis-label-extents(
    wrap-trained(),
    size,
    "x",
    coord-radial(),
  )
  // Same coord, radial axis: the grouping must be gated on the angular axis
  // alone, or the r labels would be merged too and reserve twice their band.
  let per-break = _axis-label-extents(
    wrap-trained(),
    size,
    "y",
    coord-radial(),
  )
  assert(
    theta.width > per-break.width,
    message: (
      "the merged theta label measures "
        + repr(theta.width)
        + " cm against "
        + repr(per-break.width)
        + " cm per break; it should be the wider of the two"
    ),
  )
  same-width(
    theta.width,
    measure-labels-cm(([Hour-24/Hour-0],), size).width,
    "the merged theta label",
  )
}

// A `labels` callback that returns `none` for the wrap-side break leaves one
// label at that angle, so the band owed is the single one, not the joined one.
#context {
  let size = 8pt
  let hidden = _axis-label-extents(
    wrap-trained(labels: v => if v == 24 { none } else { "Hour-" + str(v) }),
    size,
    "x",
    coord-radial(),
  )
  same-width(
    hidden.width,
    measure-labels-cm(([Hour-20],), size).width,
    "a hidden wrap-side break",
  )
}

// Hiding every theta label draws nothing, so it owes nothing: the band has to
// collapse rather than fall back to the single-line height an axis with no
// breaks at all is given.
#context {
  let hidden-all = _axis-label-extents(
    wrap-trained(labels: v => none),
    8pt,
    "x",
    coord-radial(),
  )
  assert(
    hidden-all.width == 0.0 and hidden-all.height == 0.0,
    message: (
      "a theta axis with every label hidden reserves "
        + repr(hidden-all)
        + " cm, and should reserve nothing"
    ),
  )
}

// A faceted radial plot owes the same fit. Its shared axis titles are placed
// once for the whole grid, and they have to sit where the chrome reserved for
// them: against the panel edge, since a radial panel draws no tick or label
// band outside it, exactly as the single-panel titles do.
#context fits(
  plot(
    data: (
      g: ("a",) * 5 + ("b",) * 5,
      s: ("x", "y", "z", "w", "v") * 2,
      v: (0, 0.25, 0.5, 0.75, 1.0) * 2,
    ),
    mapping: aes(x: "s", y: "v"),
    layers: (geom-point(),),
    coord: coord-radial(theta: "y"),
    scales: scales(
      y: scale-continuous(
        limits: (0, 1),
        breaks: (0, 0.25, 0.5, 0.75, 1),
        expand: false,
        labels: v => "Level-" + str(v),
      ),
    ),
    facet: facet-wrap("g"),
    width: 10cm,
    height: 6cm,
  ),
  10cm,
  6cm,
  "faceted radial plot",
)

Radial theta label fit tests passed.
