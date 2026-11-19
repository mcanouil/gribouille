// A missing group on a discrete linetype scale draws with a loosely dotted
// line.
//
// Group a is solid, group b is dashed, and the rows with no group form a third
// line that is loosely dotted. The legend lists a, b and (missing) with the matching
// dashes.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#let data = ()
#for i in range(1, 6) {
  data.push((x: i, y: i, g: "a"))
  data.push((x: i, y: i + 1.5, g: "b"))
  data.push((x: i, y: i + 3, g: none))
}

#plot(
  data: data,
  mapping: aes(x: "x", y: "y", linetype: "g"),
  layers: (geom-line(),),
  width: 10cm,
  height: 7cm,
)
