// Promoted alpha and linewidth aesthetics, both mapped to numeric columns.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let scatter-data = ()
#for i in range(0, 24) {
  scatter-data.push((x: i, y: calc.sin(i * 0.4) + i * 0.05, score: i))
}

#let line-data = ()
#for grp-idx in range(0, 5) {
  let weight = grp-idx + 1
  for i in range(0, 12) {
    line-data.push((
      x: i,
      y: i * 0.3 + grp-idx,
      grp: str(grp-idx),
      w: weight,
    ))
  }
}

#grid(
  columns: 1,
  row-gutter: 0.5cm,
  plot(
    data: scatter-data,
    mapping: aes(x: "x", y: "y", alpha: "score"),
    layers: (geom-point(size: 5pt, fill: rgb("#1f77b4")),),
    scales: (scale-alpha-continuous(range: (0.1, 1)),),
    labels: labels(
      title: "Mapped Alpha (Translucent to Opaque)",
      x: "X",
      y: "Y",
      alpha: "Score",
    ),
    theme: theme-minimal(),
    width: 12cm,
    height: 9cm,
  ),
  plot(
    data: line-data,
    mapping: aes(x: "x", y: "y", group: "grp", linewidth: "w"),
    layers: (geom-line(),),
    scales: (scale-linewidth-continuous(range: (0.4pt, 2.4pt)),),
    labels: labels(
      title: "Mapped Linewidth (Thin to Thick)",
      x: "X",
      y: "Y",
      linewidth: "Weight",
    ),
    theme: theme-minimal(),
    width: 12cm,
    height: 9cm,
  ),
)
