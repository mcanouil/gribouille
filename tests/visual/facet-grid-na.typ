// Rows with a missing facet variable get a trailing row of panels.
//
// The rows read male, female and NA, with NA last, and the NA row holds the
// penguins that have no recorded sex.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#plot(
  data: penguins,
  mapping: aes(x: "flipper-len", y: "body-mass"),
  layers: (geom-point(size: 1.2pt),),
  facet: facet-grid(rows: "sex", columns: "island"),
  width: 12cm,
  height: 7cm,
)
