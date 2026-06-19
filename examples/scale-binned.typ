// Binned scale family: stepped fill gradient, fermenter palette, area sizing.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let continuous-d = range(0, 24).map(i => (x: i, y: i, z: i * 1.0))
#let area-d = range(1, 11).map(i => (x: i, y: i, w: i * i))

#let common-theme = theme-minimal()

#grid(
  columns: 1,
  row-gutter: 0.5cm,
  plot(
    data: continuous-d,
    mapping: aes(x: "x", y: "y", fill: "z"),
    layers: (geom-point(size: 4pt),),
    scales: (scale-fill-steps(n-breaks: 5),),
    labels: labels(
      title: "Scale-Fill-Steps (5 Bins)",
      x: "X",
      y: "Y",
      fill: "z",
    ),
    theme: common-theme,
    width: 12cm,
    height: 9cm,
  ),
  plot(
    data: continuous-d,
    mapping: aes(x: "x", y: "y", fill: "z"),
    layers: (geom-point(size: 4pt),),
    scales: (scale-fill-fermenter(palette: "Spectral", n-breaks: 7),),
    labels: labels(
      title: "Scale-Fill-Fermenter (Spectral, 7)",
      x: "X",
      y: "Y",
      fill: "z",
    ),
    theme: common-theme,
    width: 12cm,
    height: 9cm,
  ),
  plot(
    data: area-d,
    mapping: aes(x: "x", y: "y", size: "w"),
    layers: (geom-point(fill: rgb("#1f77b4")),),
    scales: (scale-size-area(range: (1pt, 12pt)),),
    labels: labels(
      title: "Scale-Size-Area (sub-linear)",
      x: "X",
      y: "Y",
      size: "w",
    ),
    theme: common-theme,
    width: 12cm,
    height: 9cm,
  ),
)
