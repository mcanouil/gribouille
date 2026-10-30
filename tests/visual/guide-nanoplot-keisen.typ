// nanoplot() in a keisen table: one strip of points per row on a shared salary
// scale, with the column axis above the first row and below the last.
//
// The labels of both axes must sit over the dashed guides drawn in every cell
// at the same breaks. The default expansion keeps the points at 0 and 115000
// whole, inside the left and right edges of the column content.
//
// keisen has no release with the nanoplot protocol yet, so this test imports
// the local checkout; it moves to @preview/keisen once that release is out.

#import "../../lib.typ": *
#import "@preview/keisen:0.2.0" as keisen

#set page(width: auto, height: auto, margin: 0.4cm)
#set text(size: 7pt)

#let breaks = (25000, 50000, 75000, 100000)
#let strip(salaries) = (
  salaries
    .enumerate()
    .map(((i, salary)) => (salary: salary, y: calc.rem(i, 3) - 1))
)
#let rows = (
  (field: "Engineering", majors: strip((0, 52000, 61000, 68000, 74000, 83000))),
  (field: "Business", majors: strip((38000, 44000, 47000, 51000, 58000))),
  (field: "Education", majors: strip((31000, 34000, 36000, 40000, 115000))),
)

#keisen.display-table(
  rows,
  keisen.table-stub(rowname: "field", label: [Broad field]),
  keisen.columns-label(majors: [Median starting salary]),
  keisen.format-nanoplot(
    "majors",
    plot: nanoplot(
      mapping: aes(x: "salary", y: "y"),
      layers: (
        geom-vline(xintercept: breaks, linetype: "dashed", stroke: 0.3pt),
        geom-point(size: 2pt),
      ),
      scales: scales(
        x: scale-continuous(breaks: breaks, labels: format-comma(prefix: "$")),
        y: scale-continuous(limits: (-1.5, 1.5), expand: (0%, 0%)),
      ),
      domain-field: "salary",
    ),
    width: 8cm,
    height: 0.6cm,
    domain: (0, 115000),
  ),
)
