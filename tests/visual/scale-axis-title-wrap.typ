// Axis titles longer than the panel they label. Each plot is deliberately
// small, so both titles have to wrap. Check that: the rotated y title reads
// bottom-to-top over two or more lines and stays clear of the tick labels; the
// x title wraps under the panel; and neither pushes ink outside the drawn
// frame, which is the requested plot size.

#import "/lib.typ": *

#let d = ((x: 1, y: 1), (x: 2, y: 4), (x: 3, y: 9))

#let framed(body) = box(stroke: 0.4pt + red, body)

#let sized(width, height, ..scale-args) = framed(plot(
  data: d,
  mapping: aes(x: "x", y: "y"),
  layers: (geom-point(),),
  scales: scales(..scale-args),
  width: width,
  height: height,
))

= Long y title, wide plot

#sized(
  12cm,
  4cm,
  y: scale-continuous(
    name: "Share of the year's kilos landing in China, a very long axis title",
  ),
)

= Long x title, narrow plot

#sized(
  8cm,
  6cm,
  x: scale-continuous(
    name: "An extremely long horizontal axis title that is wider than its panel",
  ),
)

= Both titles long, small plot

#sized(
  7cm,
  5cm,
  x: scale-continuous(
    name: "An extremely long horizontal axis title that is wider than its panel",
  ),
  y: scale-continuous(
    name: "Share of the year's kilos landing in China, a very long axis title",
  ),
)

= A caption below a wrapped title still clears the frame

#framed(plot(
  data: d,
  mapping: aes(x: "x", y: "y"),
  layers: (geom-point(),),
  scales: scales(
    y: scale-continuous(
      name: "Share of the year's kilos landing in China, a very long axis title",
    ),
  ),
  labels: labels(
    title: "Wrapped axis title",
    caption: [First caption line. \ Second caption line. \ Third caption line.],
  ),
  width: 12cm,
  height: 5cm,
))
