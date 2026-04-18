// Ribbon + line: explicit ymin/ymax bounds around a fitted trend.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#let df = ()
#for i in range(0, 20) {
  let mid = i * 0.5 + 1
  df.push((t: i, y: mid, lo: mid - 1.2, hi: mid + 1.2))
}

#plot(
  data: df,
  mapping: aes(x: "t", y: "y", ymin: "lo", ymax: "hi"),
  layers: (
    geom-ribbon(fill: rgb("#4c78a8"), alpha: 0.3),
    geom-line(colour: rgb("#4c78a8")),
  ),
  labs: labs(title: "Trend with ribbon bounds"),
  width: 10cm,
  height: 7cm,
)
