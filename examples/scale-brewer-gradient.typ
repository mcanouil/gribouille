// ColorBrewer plus gradient/gradient2 scales.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let discrete-d = (
  (x: 1, y: 1, g: "alpha"),
  (x: 2, y: 2, g: "beta"),
  (x: 3, y: 3, g: "gamma"),
  (x: 4, y: 4, g: "delta"),
  (x: 5, y: 5, g: "epsilon"),
)

#let continuous-d = range(0, 16).map(i => (x: i, y: i, z: i * 1.0))
#let diverging-d = range(-7, 8).map(i => (x: i, y: i, z: i * 1.0))

#let theme0 = theme-minimal()

#grid(
  columns: 1,
  row-gutter: 0.5cm,
  plot(
    data: discrete-d,
    mapping: aes(x: "x", y: "y", fill: "g"),
    layers: (geom-point(size: 4pt),),
    scales: (scale-fill-brewer(palette: "Set1"),),
    labels: labels(
      title: "Scale-Fill-Brewer (Set1)",
      x: "X",
      y: "Y",
      fill: "Group",
    ),
    theme: theme0,
    width: 12cm,
    height: 9cm,
  ),
  plot(
    data: discrete-d,
    mapping: aes(x: "x", y: "y", fill: "g"),
    layers: (geom-point(size: 4pt),),
    scales: (scale-fill-brewer(palette: "Spectral"),),
    labels: labels(
      title: "Scale-Fill-Brewer (Spectral)",
      x: "X",
      y: "Y",
      fill: "Group",
    ),
    theme: theme0,
    width: 12cm,
    height: 9cm,
  ),
  plot(
    data: continuous-d,
    mapping: aes(x: "x", y: "y", fill: "z"),
    layers: (geom-point(size: 4pt),),
    scales: (scale-fill-gradient(),),
    labels: labels(
      title: "Scale-Fill-Gradient (two-stop)",
      x: "X",
      y: "Y",
      fill: "z",
    ),
    theme: theme0,
    width: 12cm,
    height: 9cm,
  ),
  plot(
    data: diverging-d,
    mapping: aes(x: "x", y: "y", fill: "z"),
    layers: (geom-point(size: 4pt),),
    scales: (scale-fill-gradient2(midpoint: 0),),
    labels: labels(
      title: "scale-fill-gradient2 (Around 0)",
      x: "X",
      y: "Y",
      fill: "z",
    ),
    theme: theme0,
    width: 12cm,
    height: 9cm,
  ),
)
