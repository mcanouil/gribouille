// `plot` checks that `width` is a length or `auto`, and prints the value.
//
// The check used to run in an internal helper, with no value in the message.
//
// expect: plot: width must be a length or `auto`; got "10cm"

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#plot(
  data: ((x: 1, y: 1),),
  mapping: aes(x: "x", y: "y"),
  layers: (geom-point(),),
  width: "10cm",
)
