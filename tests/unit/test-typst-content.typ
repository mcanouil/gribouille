// Three equivalent ways to write Typst markup in static prose:
//   1. typst[content]         -- bracket form, no quoting needed.
//   2. [content]               -- pass content directly (no helper).
//   3. typst("string")         -- string + eval.
// All three render identically.

#import "../../lib.typ": aes, geom-point, labels, plot, typst

#let d = ((x: 1, y: 1), (x: 2, y: 4), (x: 3, y: 9))

// Form 1: typst[…]
#plot(
  data: d,
  mapping: aes(x: "x", y: "y"),
  layers: (geom-point(size: 3pt),),
  labels: labels(
    title: typst[Penguins *Dataset*],
    subtitle: typst[#text(fill: rgb("#b22222"))[Flipper] _length_ vs _body_ mass],
    caption: typst[Source: $E = m c^2$],
    x: typst[Distance ($mu$m)],
  ),
  width: 10cm,
  height: 6cm,
)

// Form 2: plain [content]
#plot(
  data: d,
  mapping: aes(x: "x", y: "y"),
  layers: (geom-point(size: 3pt),),
  labels: labels(
    title: [Penguins *Dataset*],
    subtitle: [#text(fill: rgb("#b22222"))[Flipper] _length_ vs _body_ mass],
    caption: [Source: $E = m c^2$],
    x: [Distance ($mu$m)],
  ),
  width: 10cm,
  height: 6cm,
)

// Form 3: typst("…")
#plot(
  data: d,
  mapping: aes(x: "x", y: "y"),
  layers: (geom-point(size: 3pt),),
  labels: labels(
    title: typst("Penguins *Dataset*"),
    caption: typst("Source: $E = m c^2$"),
  ),
  width: 10cm,
  height: 6cm,
)

typst() three-form smoke test passed.
