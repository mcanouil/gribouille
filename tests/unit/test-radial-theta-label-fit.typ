// A radial panel draws its theta tick labels outside the circle, at `r-max`
// plus a pad. The chrome margin has to reserve that band, or the labels land
// outside the panel and, since the canvas bounds are the union of everything
// drawn, stretch the figure past the requested `width`/`height`.

#import "../../lib.typ": *

// Rounding in the chrome arithmetic is sub-point; anything larger is overflow.
#let SLACK = 0.5pt

#let clock(secondary: none, theta: "x", width: 6cm, height: 5cm) = plot(
  data: (h: range(0, 24), v: range(0, 24).map(i => 10 + calc.rem(i * 7, 13))),
  mapping: aes(x: "h", y: "v"),
  layers: (geom-point(),),
  coord: coord-radial(theta: theta),
  scales: scales(x: scale-continuous(secondary: secondary)),
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

// The plain case: theta labels ring the circle at the top, bottom, and both
// sides, so every margin has to hold one.
#context fits(clock(), 6cm, 5cm, "radial plot")

// Taller than wide, so the circle is bounded by the width and the horizontal
// labels are the ones with no slack to fall into.
#context fits(clock(width: 5cm, height: 7cm), 5cm, 7cm, "tall radial plot")

// A secondary spec reserves nothing under radial, so it must not change the
// answer either way.
#context fits(
  clock(secondary: sec-axis(name: "Secondary")),
  6cm,
  5cm,
  "radial plot with a secondary spec",
)

// `theta: "y"` puts the angular axis on y, so the labels come from the other
// scale.
#context fits(clock(theta: "y"), 6cm, 5cm, "pie-orientation radial plot")

Radial theta label fit tests passed.
