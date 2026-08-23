// Compile time versus element count, read from the committed benchmark dataset
// and drawn with gribouille itself.
//
// Compile from the project root for debugging:
//
//   typst compile --root . docs/guides/_benchmarks-time.typ docs/guides/_benchmarks-time.pdf
//
// The .qmd page reuses this file via the `file: _benchmarks-time.typ` chunk
// option; do not move or rename it without updating that reference.

#import "/lib.typ": *

#set page(width: auto, height: auto, margin: 0.25cm)

#let budget = 90

#let rows = csv("/docs/benchmarks/results.csv", row-type: dictionary)
#let done = (
  rows
    .filter(r => r.status == "ok")
    .map(r => (
      case: r.case,
      n: int(r.n),
      format: r.format,
      time: float(r.time_s),
    ))
)
#let stalled = (
  rows
    .filter(r => r.status == "timeout")
    .map(r => (case: r.case, n: int(r.n), format: r.format, time: budget))
)

#plot(
  data: done,
  mapping: aes(x: "n", y: "time", colour: "format"),
  layers: (
    geom-hline(yintercept: budget, linetype: "dashed", colour: rgb("#999999")),
    geom-line(),
    geom-point(size: 2.5pt),
    geom-point(data: stalled, shape: "cross", size: 3.5pt),
  ),
  scales: scales(x: scale-log10(), y: scale-log10()),
  facet: facet-wrap("case", ncolumn: 3),
  labels: labels(
    title: "Per-row layers reach the time budget, path and binning layers do not",
    subtitle: "Crosses mark sizes that exceeded the "
      + str(budget)
      + "s budget",
    x: "Elements (log scale)",
    y: "Compile time, seconds (log scale)",
    colour: "Format",
  ),
  theme: theme-minimal(),
  width: 24cm,
  height: 13cm,
)
