// facet-grid: panels over two discrete variables (row x col).

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#let cells = ()
#let species = ("A", "B", "C")
#let sexes = ("F", "M")
#for (i, s) in species.enumerate() {
  for (j, sex) in sexes.enumerate() {
    for k in range(0, 8) {
      cells.push((
        sp: s,
        sex: sex,
        x: k,
        y: k + i * 3 + j * 2 + calc.rem(k * 3, 5),
      ))
    }
  }
}

#plot(
  data: cells,
  mapping: aes(x: "x", y: "y"),
  layers: (geom-point(size: 3pt),),
  facet: facet-grid(rows: "sex", cols: "sp"),
  labs: labs(title: "facet-grid: species x sex"),
  width: 12cm,
  height: 7cm,
)
