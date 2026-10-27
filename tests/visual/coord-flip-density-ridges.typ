// Smoke render: geom-density-ridges follows coord-flip.
//
// The left panel is unflipped: the buckets run up the y axis and each ridge
// rises from its baseline. Under coord-flip the buckets run along the x axis
// and each ridge rises to the right of its baseline, with the same shapes.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let xs = (1, 2, 2, 3, 3, 3, 4, 4, 5, 7)
#let d = ()
#for (i, grp) in ("a", "b", "c").enumerate() {
  for x in xs { d.push((grp: grp, x: x * (1 + i * 0.4) + i)) }
}

#grid(
  columns: 2,
  column-gutter: 0.5cm,
  ..(false, true).map(flip => plot(
    data: d,
    mapping: aes(x: "x", y: "grp", fill: "grp"),
    layers: (geom-density-ridges(scale: 1.4, alpha: 0.7),),
    coord: if flip { coord-flip() } else { coord-cartesian() },
    width: 6cm,
    height: 5cm,
  )),
)
