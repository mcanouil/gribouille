// dup-axis duplicates an axis; sec-axis derives a transformed companion.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#plot(
  data: mpg,
  mapping: aes(x: "displ", y: "hwy", colour: "class"),
  layers: (geom-point(size: 3pt, alpha: 0.8),),
  scales: (
    scale-x-continuous(
      name: "Engine displacement (L)",
      secondary: dup-axis(name: "Displacement (L)"),
    ),
    scale-y-continuous(
      name: "Highway mpg",
      secondary: sec-axis(
        transform: v => v * 0.4251,
        name: "Highway km/L",
      ),
    ),
  ),
  labels: labels(
    title: "Fuel Economy with a Derived Secondary Axis",
    subtitle: "Right axis converts mpg to km/L (× 0.4251)",
    colour: "Class",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
