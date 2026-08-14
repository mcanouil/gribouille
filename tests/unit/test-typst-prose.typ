// End-to-end check that typst() wraps render the wrapped string as Typst
// markup at every static-prose surface (titles, axis titles, legend
// titles). The compile is the assertion: a malformed flow path would
// raise at render time.

#import "../../lib.typ": aes, geom-point, labels, plot, typst

#let d = (
  (x: 1, y: 1, sp: "a"),
  (x: 2, y: 4, sp: "b"),
  (x: 3, y: 9, sp: "c"),
)

#plot(
  data: d,
  mapping: aes(x: "x", y: "y", colour: "sp"),
  layers: (geom-point(size: 3pt),),
  labels: labels(
    title: typst("Mean $macron(x)$ over time"),
    subtitle: typst("$p < 0.001$"),
    caption: typst("Source: $italic(\"made up\")$"),
    x: typst("Distance ($mu$m)"),
    y: typst("$y = x^2$"),
    colour: typst("Group $k$"),
  ),
  width: 10cm,
  height: 6cm,
)

typst() static-prose smoke test passed.
