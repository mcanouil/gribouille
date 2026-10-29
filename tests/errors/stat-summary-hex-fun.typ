// `stat-summary-hex` names itself and lists the valid reductions.
//
// `fun: "bogus"` used to fail as `reduce-scalar` with no list.
//
// expect: stat-summary-hex: fun must be one of "mean", "median", "sum", "min", "max"

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#let d = ((x: 1, y: 2, z: 3), (x: 2, y: 4, z: 1), (x: 3, y: 3, z: 2))

#plot(
  data: d,
  mapping: aes(x: "x", y: "y", z: "z"),
  layers: (geom-hex(stat: stat-summary-hex(fun: "bogus", bins: 3)),),
  width: 8cm,
  height: 5cm,
)
