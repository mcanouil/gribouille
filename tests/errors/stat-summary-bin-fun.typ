// `stat-summary-bin` names itself and lists the valid summaries.
//
// `fun: "bogus"` used to fail as `apply-summary`.
//
// expect: stat-summary-bin: fun must be one of "mean-se"

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#let d = ((x: 1, y: 2, z: 3), (x: 2, y: 4, z: 1), (x: 3, y: 3, z: 2))

#plot(
  data: d,
  mapping: aes(x: "x", y: "y"),
  layers: (geom-point(stat: stat-summary-bin(fun: "bogus", bins: 3)),),
  width: 8cm,
  height: 5cm,
)
