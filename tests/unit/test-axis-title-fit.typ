// A plot occupies exactly the width and height it was asked for. An axis title
// longer than the panel used to enlarge the cetz canvas past `width-units` /
// `height-units`, because the bounds rect only contributes to the bounds union
// and cannot clamp it; the surplus then shifted the composed stack and ate the
// plot-background outset under the caption.

#import "../../lib.typ": *
#import "../../src/render/extents.typ": (
  _axis-title-extents, _title-along-cm, _title-extent-cm, _title-overrun-cm,
)
#import "../../src/utils/measure.typ": longest-unbreakable-cm

#let LONG-Y = (
  "Share of the year's kilos landing in China, a very long axis title indeed"
)
#let LONG-X = (
  "An extremely long horizontal axis title that is far wider than its panel"
)

#let fitted(y-name: none, x-name: none, width: 12cm, height: 4cm) = plot(
  data: (a: (1, 2, 3), b: (2, 4, 3)),
  mapping: aes(x: "a", y: "b"),
  layers: (geom-point(),),
  scales: scales(
    x: scale-continuous(name: x-name),
    y: scale-continuous(name: y-name),
  ),
  labels: labels(title: "T", caption: [C]),
  width: width,
  height: height,
)

// Rounding in the chrome arithmetic is sub-point; anything larger is overflow.
#let SLACK = 0.5pt

// A y-axis title far longer than the panel height wraps instead of stretching
// the canvas vertically.
#context {
  let m = measure(fitted(y-name: LONG-Y))
  assert(
    m.height <= 4cm + SLACK,
    message: "long y-axis title grew the plot to " + repr(m.height),
  )
  assert(
    m.width <= 12cm + SLACK,
    message: "long y-axis title grew the plot to " + repr(m.width),
  )
}

// The mirrored case: an x-axis title wider than the panel wraps instead of
// stretching the canvas horizontally.
#context {
  let m = measure(fitted(x-name: LONG-X, width: 8cm, height: 6cm))
  assert(
    m.width <= 8cm + SLACK,
    message: "long x-axis title grew the plot to " + repr(m.width),
  )
  assert(
    m.height <= 6cm + SLACK,
    message: "long x-axis title grew the plot to " + repr(m.height),
  )
}

// Both at once, on a plot small enough that each title needs several lines.
#context {
  let m = measure(fitted(
    y-name: LONG-Y,
    x-name: LONG-X,
    width: 7cm,
    height: 5cm,
  ))
  assert(
    m.width <= 7cm + SLACK and m.height <= 5cm + SLACK,
    message: "wrapped titles grew the plot to "
      + repr(m.width)
      + " x "
      + repr(m.height),
  )
}

// A short title is untouched: one line, and the plot still measures true.
#context {
  let m = measure(fitted(y-name: "y", x-name: "x"))
  assert(
    m.height <= 4cm + SLACK and m.width <= 12cm + SLACK,
    message: "short titles grew the plot to "
      + repr(m.width)
      + " x "
      + repr(m.height),
  )
}

// The reading length a title has before it overruns the panel. At the natural
// angles the whole panel extent is available; at 45deg the diagonal is longer
// than its projection; a title reading across its own axis is unbounded, since
// the perpendicular depth already reserves it.
#let approx(a, b) = assert(
  calc.abs(a - b) < 1e-6,
  message: repr(a) + " != " + repr(b),
)
#approx(_title-along-cm((angle: none, size: 9pt), "x", 6.0), 6.0)
#approx(_title-along-cm((angle: none, size: 9pt), "y", 4.0), 4.0)
#approx(
  _title-along-cm((angle: 45deg, size: 9pt), "x", 6.0),
  6.0
    / calc.cos(
      45deg,
    ),
)
#assert.eq(_title-along-cm((angle: 90deg, size: 9pt), "x", 6.0), none)
#assert.eq(_title-along-cm((angle: 0deg, size: 9pt), "y", 4.0), none)
// A panel with nothing left in it bounds nothing; the canvas-minimum guard in
// `render-plot` owns that case.
#assert.eq(_title-along-cm((angle: none, size: 9pt), "y", 0.0), none)

// The widest unbreakable run drives the overrun guard. Only strings expose
// their break opportunities, so content reports zero and never trips it.
#context {
  let words = longest-unbreakable-cm("a bb cccccccccccccccc dd", 9pt)
  let longest = longest-unbreakable-cm("cccccccccccccccc", 9pt)
  approx(words, longest)
  assert(words > 0, message: "expected a positive width")
  assert.eq(longest-unbreakable-cm([content], 9pt), 0.0)
}

// An unwrapped title reports no overrun, and neither does one that merely
// wrapped. A single word wider than its box does.
#context {
  let style = (
    size: 9pt,
    typst: false,
    angle: none,
    fill: black,
    weight: (
      "regular"
    ),
    font: none,
  )
  let fits = _axis-title-extents("short", style, along-cm: 6.0)
  assert.eq(fits.along, none)
  assert.eq(_title-overrun-cm(fits), 0.0)

  let wrapped = _axis-title-extents(
    "a title long enough that it has to run onto a second line",
    style,
    along-cm: 3.0,
  )
  assert.eq(wrapped.along, 3.0)
  assert.eq(_title-overrun-cm(wrapped), 0.0)
  // Wrapping is what makes it thicker than the one line it used to reserve.
  assert(
    _title-extent-cm(style, wrapped, "y") > _title-extent-cm(style, fits, "y"),
    message: "a wrapped title should reserve more than an unwrapped one",
  )

  let unbreakable = _axis-title-extents(
    "Sharejlkdsfjlksdjflksdjflksdjlfkjsdlkfjsdlkfjlksdjflksdjf",
    style,
    along-cm: 2.0,
  )
  assert(
    _title-overrun-cm(unbreakable) > 0,
    message: "a word wider than its box should report an overrun",
  )
}

// Typst cannot catch panics in-process, so the `fail` the overrun feeds is
// verified manually: an unbreakable y title on a 12cm x 4cm plot reports
// "the y-axis title has a 8.88 cm word that cannot wrap into the 2.82 cm the
// panel leaves it".
