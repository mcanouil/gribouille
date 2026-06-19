// Ribbon + line: explicit ymin/ymax bounds around a fitted trend.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let accent = rgb("#1f77b4")

#let df = ()
#for i in range(0, 20) {
  let mid = i * 0.5 + 1
  df.push((t: i, y: mid, lo: mid - 1.2, hi: mid + 1.2))
}

#plot(
  data: df,
  mapping: aes(x: "t", y: "y", ymin: "lo", ymax: "hi"),
  layers: (
    geom-ribbon(fill: accent, alpha: 0.3),
    geom-line(colour: accent, stroke: 1.2pt),
    geom-point(size: 2.5pt, fill: accent),
  ),
  scales: (
    scale-x-continuous(name: "Time step"),
    scale-y-continuous(name: "Value"),
  ),
  labels: labels(
    title: "Trend with an Explicit Ribbon Band",
    subtitle: "ymin and ymax aesthetics drive geom-ribbon directly",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
