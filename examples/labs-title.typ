// labs(): title, subtitle, caption, and axis labels in one call.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#let df = range(1, 16).map(i => (x: i, y: i + calc.rem(i * 7, 5)))

#plot(
  data: df,
  mapping: aes(x: "x", y: "y"),
  layers: (geom-point(size: 3pt), geom-line()),
  labs: labs(
    title: "Monthly counts",
    subtitle: "First half of the experiment",
    caption: "Source: simulated dataset.",
    x: "Month",
    y: "Count",
  ),
  width: 10cm,
  height: 7cm,
)
