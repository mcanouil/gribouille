// facet-grid with free scales: x is free per column, y is free per row.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

// Each species (column) lives on a distinct x range; each sex (row) on a
// distinct y range, so shared scales would crush most panels to a corner.
#let d = ()
#for (sp, x0) in (("a", 0), ("b", 100)) {
  for (sex, y0) in (("F", 0), ("M", 1000)) {
    for i in range(0, 6) {
      d.push((sp: sp, sex: sex, x: x0 + i, y: y0 + i * 2))
    }
  }
}

#plot(
  data: d,
  mapping: aes(x: "x", y: "y"),
  layers: (geom-point(size: 2pt),),
  facet: facet-grid(rows: "sex", columns: "sp", scales: "free"),
  labels: labels(x: "x", y: "y"),
  width: 12cm,
  height: 8cm,
)
