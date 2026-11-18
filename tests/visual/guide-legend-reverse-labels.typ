// Regression: `guide-legend(reverse: true)` keeps custom labels with their keys.
//
// Read the legend: "label B" with a blue swatch comes first, then "label A"
// with a red swatch. Before the fix the labels kept their original order, so
// the blue swatch read "label A" and the red one "label B".

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.3cm)

#plot(
  data: (
    (x: 1, y: 1, g: "a"),
    (x: 2, y: 2, g: "a"),
    (x: 3, y: 3, g: "b"),
    (x: 4, y: 4, g: "b"),
  ),
  mapping: aes(x: "x", y: "y", fill: "g"),
  layers: (geom-point(size: 3pt, shape: "square"),),
  scales: scales(
    fill: scale-discrete(palette: (red, blue), labels: ("label A", "label B")),
  ),
  guides: guides(fill: guide-legend(reverse: true)),
  width: 8cm,
  height: 5cm,
)
