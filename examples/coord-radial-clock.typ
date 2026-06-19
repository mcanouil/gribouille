// Clock-face layout: hourly observations wrapped to a circle via coord-radial.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let hours = range(0, 24).map(h => (
  hour: h,
  load: 30 + 25 * calc.sin(2 * calc.pi * h / 24) + calc.rem(h * 7, 11),
))

#plot(
  data: hours,
  mapping: aes(x: "hour", y: "load"),
  layers: (
    geom-line(stroke: 1pt),
    geom-point(size: 2pt),
  ),
  coord: coord-radial(theta: "x"),
  scales: (scale-x-continuous(limits: (0, 24), expand: false),),
  labels: labels(title: "Daily Load"),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
