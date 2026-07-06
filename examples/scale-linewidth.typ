// scale-linewidth family: continuous, manual per-level lengths, and binned.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let cont = (
  (x: 1, y: 1, w: 1, g: "low"),
  (x: 2, y: 2, w: 1, g: "low"),
  (x: 3, y: 3, w: 1, g: "low"),
  (x: 4, y: 4, w: 1, g: "low"),
  (x: 1, y: 2, w: 5, g: "mid"),
  (x: 2, y: 3, w: 5, g: "mid"),
  (x: 3, y: 4, w: 5, g: "mid"),
  (x: 4, y: 5, w: 5, g: "mid"),
  (x: 1, y: 3, w: 9, g: "high"),
  (x: 2, y: 4, w: 9, g: "high"),
  (x: 3, y: 5, w: 9, g: "high"),
  (x: 4, y: 6, w: 9, g: "high"),
)

#let manual = (
  (x: 1, y: 1, g: "thin"),
  (x: 2, y: 2, g: "thin"),
  (x: 1, y: 2, g: "medium"),
  (x: 2, y: 3, g: "medium"),
  (x: 1, y: 3, g: "thick"),
  (x: 2, y: 4, g: "thick"),
)

#grid(
  columns: 1,
  row-gutter: 0.4cm,
  plot(
    data: cont,
    mapping: aes(x: "x", y: "y", linewidth: "w", group: "g"),
    layers: (geom-line(),),
    scales: scales(linewidth: scale-continuous(range: (0.4pt, 2.4pt))),
    labels: labels(
      title: "Scale-Linewidth-Continuous",
      x: "X",
      y: "Y",
      linewidth: "w",
    ),
    theme: theme-minimal(),
    width: 12cm,
    height: 9cm,
  ),
  plot(
    data: manual,
    mapping: aes(x: "x", y: "y", linewidth: "g", group: "g"),
    layers: (geom-line(),),
    scales: scales(linewidth: scale-manual(values: (0.4pt, 1.2pt, 2.4pt),
        limits: ("thin", "medium", "thick"),)),
    labels: labels(
      title: "Scale-Linewidth-Manual",
      x: "X",
      y: "Y",
      linewidth: "Stroke",
    ),
    theme: theme-minimal(),
    width: 12cm,
    height: 9cm,
  ),
  plot(
    data: cont,
    mapping: aes(x: "x", y: "y", linewidth: "w", group: "g"),
    layers: (geom-line(),),
    scales: scales(linewidth: scale-binned(n-breaks: 4, range: (0.4pt, 2.4pt))),
    labels: labels(
      title: "Scale-Linewidth-Binned",
      x: "X",
      y: "Y",
      linewidth: "w",
    ),
    theme: theme-minimal(),
    width: 12cm,
    height: 9cm,
  ),
)
