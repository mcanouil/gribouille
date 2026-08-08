// A plot occupies exactly the width and height it was asked for. An axis title
// longer than the panel used to enlarge the cetz canvas past `width-units` /
// `height-units`, because the bounds rect only contributes to the bounds union
// and cannot clamp it; the surplus then shifted the composed stack and ate the
// plot-background outset under the caption.

#import "../../lib.typ": *
#import "../../src/render/extents.typ": (
  _axis-title-extents, _fit-title-extents, _title-along-cm, _title-extent-cm,
  _title-overrun-cm, _title-span-cm,
)
#import "../../src/utils/measure.typ": longest-unbreakable-cm

#let LONG-Y = (
  "Share of the year's kilos landing in China, a very long axis title indeed"
)
#let LONG-X = (
  "An extremely long horizontal axis title that is far wider than its panel"
)

#let d = (a: (1, 2, 3), b: (2, 4, 3))

#let fitted(
  y-name: none,
  x-name: none,
  width: 12cm,
  height: 4cm,
  theme: none,
) = plot(
  data: d,
  mapping: aes(x: "a", y: "b"),
  layers: (geom-point(),),
  scales: scales(
    x: scale-continuous(name: x-name),
    y: scale-continuous(name: y-name),
  ),
  labels: labels(title: "T", caption: [C]),
  theme: theme,
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

// A themed font changes where the title breaks, and the wrapped branch
// measures through the full text style while the "does it fit" check measures
// at the size alone. The reservation still has to match the drawing.
#context {
  let m = measure(plot(
    data: d,
    mapping: aes(x: "a", y: "b"),
    layers: (geom-point(),),
    scales: scales(y: scale-continuous(name: LONG-Y)),
    theme: theme-grey(
      axis-title: element-text(font: "DejaVu Sans Mono", size: 11pt),
    ),
    width: 12cm,
    height: 4cm,
  ))
  assert(
    m.height <= 4cm + SLACK and m.width <= 12cm + SLACK,
    message: "a themed title font grew the plot to "
      + repr(m.width)
      + " x "
      + repr(m.height),
  )
}

// A title the theme rotates off its natural angle spans the panel with both
// its length and its thickness, so it is bounded against a different
// projection. Given room, it still has to fit exactly.
#context {
  for angle in (30deg, 45deg, 60deg) {
    let m = measure(plot(
      data: d,
      mapping: aes(x: "a", y: "b"),
      layers: (geom-point(),),
      scales: scales(y: scale-continuous(name: LONG-Y)),
      theme: theme-grey(axis-title-y: element-text(angle: angle)),
      width: 16cm,
      height: 9cm,
    ))
    assert(
      m.height <= 9cm + SLACK and m.width <= 16cm + SLACK,
      message: "a title at "
        + repr(angle)
        + " grew the plot to "
        + repr(m.width)
        + " x "
        + repr(m.height),
    )
  }
}

// Secondary axis titles are wrapped and reserved through the same path.
#context {
  let m = measure(plot(
    data: d,
    mapping: aes(x: "a", y: "b"),
    layers: (geom-point(),),
    scales: scales(y: scale-continuous(
      name: "y",
      secondary: sec-axis(transform: v => v * 2, name: LONG-Y),
    )),
    width: 12cm,
    height: 4cm,
  ))
  assert(
    m.height <= 4cm + SLACK and m.width <= 12cm + SLACK,
    message: "a long secondary y title grew the plot to "
      + repr(m.width)
      + " x "
      + repr(m.height),
  )
}

// `theme-void` drops the titles entirely; the wrapping path must not resurrect
// a reservation for ink that never draws.
#context {
  let m = measure(fitted(y-name: LONG-Y, x-name: LONG-X, theme: theme-void()))
  assert(
    m.height <= 4cm + SLACK and m.width <= 12cm + SLACK,
    message: "theme-void grew the plot to "
      + repr(m.width)
      + " x "
      + repr(m.height),
  )
}

// A suppressed title reserves nothing, wrapped or not.
#context {
  let m = measure(plot(
    data: d,
    mapping: aes(x: "a", y: "b"),
    layers: (geom-point(),),
    scales: scales(y: scale-continuous(name: LONG-Y)),
    labels: labels(y: none),
    width: 12cm,
    height: 4cm,
  ))
  assert(
    m.height <= 4cm + SLACK and m.width <= 12cm + SLACK,
    message: "a suppressed title grew the plot to "
      + repr(m.width)
      + " x "
      + repr(m.height),
  )
}

// `compose(align-panels: true)` forces a shared margin over the per-panel one,
// which is the branch that overrides what the wrapping settled on.
#context {
  let panel(name) = defer(
    plot,
    data: d,
    mapping: aes(x: "a", y: "b"),
    layers: (geom-point(),),
    scales: scales(y: scale-continuous(name: name)),
  )
  let m = measure(compose(
    panel(LONG-Y),
    panel("y"),
    ncolumn: 2,
    align-panels: true,
    width: 14cm,
    height: 5cm,
  ))
  assert(
    m.height <= 5cm + SLACK and m.width <= 14cm + SLACK,
    message: "aligned panels grew the composition to "
      + repr(m.width)
      + " x "
      + repr(m.height),
  )
}

#let approx(a, b) = assert(
  calc.abs(a - b) < 1e-6,
  message: repr(a) + " != " + repr(b),
)
// At a natural angle the thickness lies across the constrained span and costs
// the title nothing, so the whole panel extent is available.
#let plain = (angle: none, size: 9pt)
#approx(_title-along-cm(plain, "x", 6.0, 20.0), 6.0)
#approx(_title-along-cm(plain, "y", 4.0, 20.0), 4.0)

// Off the natural angles both the reading length and the thickness project
// onto the span, so the bound is the larger root of the resulting quadratic.
#let LINE = 9 * 0.0353
#let root(panel, natural, s, c) = {
  let bulk = natural * LINE * c
  (panel + calc.sqrt(panel * panel - 4 * s * bulk)) / (2 * s)
}
#approx(
  _title-along-cm((angle: 45deg, size: 9pt), "x", 6.0, 20.0),
  root(6.0, 20.0, calc.cos(45deg), calc.sin(45deg)),
)
#approx(
  _title-along-cm((angle: 60deg, size: 9pt), "y", 4.0, 20.0),
  root(4.0, 20.0, calc.sin(60deg), calc.cos(60deg)),
)

// That root really does span no more than the panel, which is the whole point.
#context {
  let a = 45deg
  let len = _title-along-cm((angle: a, size: 9pt), "y", 4.0, 20.0)
  let thickness = 20.0 * LINE / len
  approx(len * calc.sin(a) + thickness * calc.cos(a), 4.0)
}

// A title reading across its own axis has its length reserved as perpendicular
// depth instead, so nothing bounds it.
#assert.eq(_title-along-cm((angle: 90deg, size: 9pt), "x", 6.0, 20.0), none)
#assert.eq(_title-along-cm((angle: 0deg, size: 9pt), "y", 4.0, 20.0), none)
// Below the panel minimum nothing is bounded: those layouts are degenerate
// already, and turning what used to render into a failure would be worse than
// the cramped title. The canvas-minimum guard in `render-plot` owns them.
#assert.eq(_title-along-cm(plain, "y", 0.0, 20.0), none)
#assert.eq(_title-along-cm(plain, "y", 0.49, 20.0), none)
#approx(_title-along-cm(plain, "y", 0.5, 20.0), 0.5)
// No box fits a long title into a short panel at 45deg, because the span has a
// floor. Hand back the length that comes closest rather than nothing.
#context {
  let a = 45deg
  let len = _title-along-cm((angle: a, size: 9pt), "y", 1.0, 20.0)
  // The closest is the span minimum, `sqrt(bulk / along-share)`.
  approx(len, calc.sqrt(20.0 * LINE * calc.cos(a) / calc.sin(a)))
}

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

// Rotated off its axis, a title spans the panel with both its length and its
// thickness, and narrowing the box trades one for the other. Past a point that
// trade stops paying, so a long title in a short panel has a span floor no
// wrapping can get under.
#context {
  let style = (
    size: 9pt,
    typst: false,
    angle: 45deg,
    fill: black,
    weight: (
      "regular"
    ),
    font: none,
  )
  let natural = _axis-title-extents(LONG-Y, style).width
  let best = _fit-title-extents(LONG-Y, style, "y", 2.0, natural)
  assert(
    _title-span-cm(style, best.ext, "y") > 2.0,
    message: "expected no box to fit a 2cm panel at 45deg",
  )
  // Given room, the search finds one, and it spans no more than the panel.
  let roomy = _fit-title-extents(LONG-Y, style, "y", 6.0, natural)
  assert(
    _title-span-cm(style, roomy.ext, "y") <= 6.0 + 1e-6,
    message: "expected a fitting box in a 6cm panel at 45deg",
  )
}

// Typst cannot catch panics in-process, so the two `fail`s these feed are
// verified manually. An unbreakable y title on a 12cm x 4cm plot reports "the
// y-axis title has a 8.88 cm word that cannot wrap into the 2.82 cm the panel
// leaves it"; a long y title at 45deg on the same plot reports "the y-axis
// title spans 3.11 cm along a panel of 2.69 cm, and no wrapping of it at
// 45deg spans less".
