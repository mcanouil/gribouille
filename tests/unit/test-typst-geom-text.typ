// End-to-end check that `aes(label: typst("col"))` evaluates each row's
// label as Typst markup at render time, for both geom-text and
// geom-label. The compile is the assertion: a malformed flow path would
// raise at render time.

#import "../../lib.typ": (
  aes, geom-label, geom-point, geom-text, labels, plot, typst,
)

#let d = (
  (x: 1, y: 1, lab: "$alpha$"),
  (x: 2, y: 4, lab: "$beta$"),
  (x: 3, y: 9, lab: "$gamma$"),
)

#plot(
  data: d,
  mapping: aes(x: "x", y: "y"),
  layers: (
    geom-point(size: 3pt),
    geom-text(mapping: aes(label: typst("lab")), dy: 0.2),
  ),
  width: 10cm,
  height: 6cm,
)

#plot(
  data: d,
  mapping: aes(x: "x", y: "y"),
  layers: (
    geom-point(size: 3pt),
    geom-label(mapping: aes(label: typst("lab")), dy: 0.3),
  ),
  width: 10cm,
  height: 6cm,
)

// Plain string labels still render verbatim (regression check).
#plot(
  data: d,
  mapping: aes(x: "x", y: "y", label: "lab"),
  layers: (
    geom-point(size: 3pt),
    geom-text(dy: 0.2),
  ),
  width: 10cm,
  height: 6cm,
)

typst() data-label smoke test passed.
