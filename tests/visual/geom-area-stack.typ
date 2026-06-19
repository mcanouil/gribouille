// Smoke render: stacked areas over mismatched x must align cleanly.
//
// The two groups carry interleaved x values (a at 1, 3, 5; b at 2, 4, 6),
// so the default `stat: "align"` resamples them onto a shared grid before
// stacking. Each band's lower edge sits at the cumulated top of the band
// below it. Where one group has not started yet, the other steps down to the
// baseline rather than rising diagonally toward the first vertex.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = (
  (g: "a", x: 1, y: 2),
  (g: "a", x: 3, y: 5),
  (g: "a", x: 5, y: 1),
  (g: "b", x: 2, y: 3),
  (g: "b", x: 4, y: 6),
  (g: "b", x: 6, y: 7),
)

#plot(
  data: d,
  mapping: aes(x: "x", y: "y", fill: "g"),
  layers: (geom-area(alpha: 0.6),),
  labels: labels(title: "geom-area stacked over mismatched x"),
  theme: theme-minimal(),
  width: 10cm,
  height: 6cm,
)
