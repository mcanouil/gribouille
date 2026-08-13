// Visual: per-row `nudge-x`/`nudge-y` offsets in data units with `segment: true`.
// Bottom layer overlays geom-label to confirm box-edge clipping. A deliberate
// crowd in the middle exercises the L-bend router.

#import "../../lib.typ": aes, arrow, geom-label, geom-point, geom-text, plot

#let d = (
  (x: 1, y: 1, lab: "alpha", nx: 0.5, ny: 0.6),
  (x: 2, y: 2, lab: "beta", nx: -0.6, ny: 0.4),
  (x: 2.2, y: 2.1, lab: "gamma", nx: 0.6, ny: -0.4),
  (x: 3, y: 3, lab: "delta", nx: 0.5, ny: 0.5),
)

#plot(
  data: d,
  mapping: aes(x: "x", y: "y", label: "lab", nudge-x: "nx", nudge-y: "ny"),
  layers: (
    geom-point(size: 3pt),
    geom-text(segment: true, arrow: arrow()),
  ),
  width: 10cm,
  height: 6cm,
)

#plot(
  data: d,
  mapping: aes(x: "x", y: "y", label: "lab", nudge-x: "nx", nudge-y: "ny"),
  layers: (
    geom-point(size: 3pt),
    geom-label(segment: true),
  ),
  width: 10cm,
  height: 6cm,
)
