// Facet wrap: one panel per level of a discrete variable.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0.4cm)

#let cars = (
  (wt: 2.620, mpg: 21.0, cyl: "6"),
  (wt: 2.875, mpg: 21.0, cyl: "6"),
  (wt: 2.320, mpg: 22.8, cyl: "4"),
  (wt: 3.215, mpg: 21.4, cyl: "6"),
  (wt: 3.440, mpg: 18.7, cyl: "8"),
  (wt: 3.460, mpg: 18.1, cyl: "6"),
  (wt: 3.570, mpg: 14.3, cyl: "8"),
  (wt: 3.190, mpg: 24.4, cyl: "4"),
  (wt: 3.150, mpg: 22.8, cyl: "4"),
  (wt: 3.440, mpg: 19.2, cyl: "6"),
  (wt: 3.440, mpg: 17.8, cyl: "6"),
  (wt: 4.070, mpg: 16.4, cyl: "8"),
  (wt: 3.730, mpg: 17.3, cyl: "8"),
  (wt: 3.780, mpg: 15.2, cyl: "8"),
  (wt: 5.250, mpg: 10.4, cyl: "8"),
  (wt: 5.424, mpg: 10.4, cyl: "8"),
  (wt: 5.345, mpg: 14.7, cyl: "8"),
  (wt: 2.200, mpg: 32.4, cyl: "4"),
  (wt: 1.615, mpg: 30.4, cyl: "4"),
  (wt: 1.835, mpg: 33.9, cyl: "4"),
  (wt: 2.465, mpg: 21.5, cyl: "4"),
  (wt: 3.520, mpg: 15.5, cyl: "8"),
  (wt: 3.435, mpg: 15.2, cyl: "8"),
  (wt: 3.840, mpg: 13.3, cyl: "8"),
  (wt: 3.845, mpg: 19.2, cyl: "8"),
  (wt: 1.935, mpg: 27.3, cyl: "4"),
  (wt: 2.140, mpg: 26.0, cyl: "4"),
  (wt: 1.513, mpg: 30.4, cyl: "4"),
  (wt: 3.170, mpg: 15.8, cyl: "8"),
  (wt: 2.770, mpg: 19.7, cyl: "6"),
  (wt: 3.570, mpg: 15.0, cyl: "8"),
  (wt: 2.780, mpg: 21.4, cyl: "4"),
)

#plot(
  data: cars,
  mapping: aes(x: "wt", y: "mpg"),
  layers: (
    geom-point(size: 2pt),
  ),
  facet: facet-wrap("cyl", ncol: 3),
  scales: (
    scale-x-continuous(name: "Weight"),
    scale-y-continuous(name: "MPG"),
  ),
  width: 15cm,
  height: 8cm,
)
