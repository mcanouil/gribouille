// guide-legend(order:, direction:, byrow:): stacking priority and grid flow.
//
// `order` overrides the default aesthetic order (colour, fill, size, ...);
// `direction` flips the swatch flow between vertical and horizontal;
// `byrow` switches the grid fill from column-major to row-major.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = (
  (x: 1, y: 1, g: "a", w: 1),
  (x: 2, y: 2, g: "b", w: 2),
  (x: 3, y: 3, g: "c", w: 3),
  (x: 4, y: 4, g: "d", w: 4),
)

#grid(
  columns: 1,
  row-gutter: 0.6cm,
  plot(
    data: d,
    mapping: aes(x: "x", y: "y", colour: "g", size: "w"),
    layers: (geom-point(),),
    labels: labels(title: "default order: colour before size"),
    width: 12cm,
    height: 5cm,
  ),
  plot(
    data: d,
    mapping: aes(x: "x", y: "y", colour: "g", size: "w"),
    layers: (geom-point(),),
    guides: guides(
      colour: guide-legend(order: 2),
      size: guide-legend(order: 1),
    ),
    labels: labels(title: "order swap: size before colour"),
    width: 12cm,
    height: 5cm,
  ),
  plot(
    data: d,
    mapping: aes(x: "x", y: "y", colour: "g"),
    layers: (geom-point(size: 4pt),),
    guides: guides(colour: guide-legend(
      direction: "horizontal",
      ncolumn: 2,
      byrow: true,
    )),
    labels: labels(title: "direction: \"horizontal\", ncolumn: 2, byrow: true"),
    width: 12cm,
    height: 5cm,
  ),
)
