// Scatter with an OLS smoother and 95% CI band.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#let pts = (
  (x: 1.0, y: 2.3),
  (x: 1.6, y: 3.1),
  (x: 2.1, y: 3.2),
  (x: 2.4, y: 3.9),
  (x: 2.8, y: 4.0),
  (x: 3.2, y: 4.8),
  (x: 3.6, y: 4.9),
  (x: 4.1, y: 5.4),
  (x: 4.5, y: 5.9),
  (x: 5.0, y: 6.4),
  (x: 5.4, y: 6.6),
  (x: 5.9, y: 7.3),
  (x: 6.3, y: 7.5),
  (x: 6.8, y: 8.1),
  (x: 7.2, y: 8.4),
  (x: 7.7, y: 9.0),
  (x: 8.1, y: 8.9),
  (x: 8.6, y: 9.5),
  (x: 9.0, y: 10.1),
  (x: 9.5, y: 10.3),
)

#plot(
  data: pts,
  mapping: aes(x: "x", y: "y"),
  layers: (
    geom-smooth(),
    geom-point(size: 2.5pt),
  ),
  scales: (
    scale-x-continuous(name: "x"),
    scale-y-continuous(name: "y"),
  ),
  width: 11cm,
  height: 7cm,
)
