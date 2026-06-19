// guide-axis-stack pairs a rotated-label pass with the log-tick minor pass
// on the same axis: one row carries readable labels, the next adds dense
// minor ticks below.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = (
  (x: 1, y: 1),
  (x: 3, y: 5),
  (x: 10, y: 100),
  (x: 30, y: 800),
  (x: 100, y: 10000),
)

#plot(
  data: d,
  mapping: aes(x: "x", y: "y"),
  layers: (geom-point(size: 3pt),),
  scales: (
    scale-x-continuous(transform: "log10"),
    scale-y-continuous(transform: "log10"),
  ),
  guides: guides(
    x: guide-axis-stack(
      guides: (
        guide-axis(angle: 30),
        guide-axis-logticks(),
      ),
      spacing: 6pt,
    ),
  ),
  labels: labels(title: "Guide-Axis-Stack: Rotated Labels + Log Minor Ticks"),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
