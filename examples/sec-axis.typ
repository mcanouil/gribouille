// dup-axis duplicates an axis; sec-axis derives a transformed companion.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#stack(
  dir: ttb,
  spacing: 0.8cm,
  plot(
    data: mpg,
    mapping: aes(x: "displ", y: "hwy", colour: "class"),
    layers: (geom-point(size: 3pt, alpha: 0.8),),
    scales: scales(
      x: scale-continuous(
        name: "Engine displacement (L)",
        secondary: dup-axis(name: "Displacement (L)"),
      ),
      y: scale-continuous(name: "Highway mpg", secondary: sec-axis(
        transform: v => v * 0.4251,
        name: "Highway km/L",
      )),
    ),
    labels: labels(
      title: "Fuel Economy with a Derived Secondary Axis",
      subtitle: "Right axis converts mpg to km/L (× 0.4251)",
      colour: "Class",
    ),
    theme: theme-minimal(),
    width: 12cm,
    height: 9cm,
  ),
  // Under facets the secondary axis is drawn between each panel and its
  // strip, and its title once at the edge of the panel grid.
  plot(
    data: mpg,
    mapping: aes(x: "displ", y: "hwy"),
    layers: (geom-point(size: 2pt, alpha: 0.8),),
    facet: facet-wrap("drv", ncolumn: 3),
    scales: scales(
      x: scale-continuous(
        name: "Engine displacement (L)",
        secondary: dup-axis(name: "Displacement (L)"),
      ),
      y: scale-continuous(name: "Highway mpg"),
    ),
    labels: labels(title: "Faceted, with the secondary axis under the strips"),
    theme: theme-minimal(),
    width: 12cm,
    height: 6cm,
  ),
)
