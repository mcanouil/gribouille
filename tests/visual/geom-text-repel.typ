// Visual: a cluttered scatter where labels would overlap each other.
// `repel: true` should spread them out while `segment: true` keeps every
// label visually tied to its anchor point. Final connectors should not
// cross any other label box (eyeball check vs. ggrepel).

#import "../../lib.typ": aes, arrow, geom-label, geom-point, geom-text, plot

#let d = (
  (x: 1.0, y: 1.0, lab: "alpha"),
  (x: 1.1, y: 1.05, lab: "beta"),
  (x: 1.2, y: 1.02, lab: "gamma"),
  (x: 1.05, y: 1.15, lab: "delta"),
  (x: 1.15, y: 1.18, lab: "epsilon"),
  (x: 1.3, y: 1.05, lab: "zeta"),
  (x: 1.25, y: 1.2, lab: "eta"),
)

#plot(
  data: d,
  mapping: aes(x: "x", y: "y", label: "lab"),
  layers: (
    geom-point(size: 3pt),
    geom-text(repel: true, segment: true, arrow: arrow(), seed: 1),
  ),
  width: 10cm,
  height: 6cm,
)

#plot(
  data: d,
  mapping: aes(x: "x", y: "y", label: "lab"),
  layers: (
    geom-point(size: 3pt),
    geom-label(repel: true, segment: true, seed: 3),
  ),
  width: 10cm,
  height: 6cm,
)
