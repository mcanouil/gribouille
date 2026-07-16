// Showcase: filled bars comparing cylinder shares across classes; every bar
// normalises to 1 so composition, not volume, is the message.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let shares = count(mpg, "class", "cyl")

#plot(
  data: shares,
  mapping: aes(x: "class", y: "n", fill: as-factor("cyl")),
  layers: (geom-col(position: "fill"),),
  scales: scales(
    y: scale-continuous(labels: format-percent(scale: 100)),
    fill: scale-okabe-ito(),
  ),
  labels: labels(
    title: "Small cars run on four cylinders, pickups and SUVs rarely do",
    subtitle: "Share of cylinder counts within each vehicle class",
    x: "",
    y: "Share of vehicles",
    fill: "Cylinders",
    caption: "Source: bundled mpg dataset.",
  ),
  theme: theme-minimal(),
  width: 13cm,
  height: 7.5cm,
)
