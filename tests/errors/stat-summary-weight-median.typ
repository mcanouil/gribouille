// A summary with no weighted form fails when the layer maps `weight`.
//
// `median` used to drop the weights in silence.
//
// expect: stat-summary: fun "median" cannot use the weight aesthetic

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#plot(
  data: ((x: "a", y: 1, w: 2), (x: "a", y: 3, w: 1)),
  mapping: aes(x: "x", y: "y", weight: "w"),
  layers: (geom-point(stat: stat-summary(fun: "median")),),
)
