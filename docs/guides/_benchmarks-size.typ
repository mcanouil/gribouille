// Output size versus element count, read from the committed benchmark dataset
// and drawn with gribouille itself.
//
// Compile from the project root for debugging:
//
//   typst compile --root . docs/guides/_benchmarks-size.typ docs/guides/_benchmarks-size.pdf
//
// The .qmd page reuses this file via the `file: _benchmarks-size.typ` chunk
// option; do not move or rename it without updating that reference.

#import "/lib.typ": *

#set page(width: auto, height: auto, margin: 0.25cm)

#let rows = csv("/docs/benchmarks/results.csv", row-type: dictionary)
#let done = (
  rows
    .filter(r => r.status == "ok" and r.bytes != "")
    .map(r => (
      case: r.case,
      n: int(r.n),
      format: r.format,
      kb: float(r.bytes) / 1024,
    ))
)

#plot(
  data: done,
  mapping: aes(x: "n", y: "kb", colour: "format"),
  layers: (
    geom-line(),
    geom-point(size: 2.5pt),
  ),
  scales: (scale-x-log10(), scale-y-log10()),
  facet: facet-wrap("case", ncolumn: 4),
  labels: labels(
    title: "Vector output balloons with element count, raster stays compact",
    subtitle: "SVG carries one node per mark; PNG and PDF grow far more slowly",
    x: "Elements (log scale)",
    y: "Output size, KB (log scale)",
    colour: "Format",
  ),
  theme: theme-minimal(),
  width: 24cm,
  height: 11cm,
)
