// A radial panel draws its theta tick labels outside the circle, at `r-max`
// plus a pad. The circle has to leave them that band inside the panel, or the
// labels land outside it and, since the canvas bounds are the union of
// everything drawn, stretch the figure past the requested `width`/`height`.

#import "../../lib.typ": *

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

Radial theta label fit tests passed.
