// facet-grid: panels arranged on a row × column grid of two discrete variables.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#plot(
  data: penguins,
  mapping: aes(x: "flipper-len", y: "body-mass", colour: "species"),
  layers: (geom-point(size: 2pt, alpha: 0.85),),
  facet: facet-grid(rows: "sex", columns: "species", labeller: label-both()),
  scales: (scale-y-continuous(labels: format-comma()),),
  guides: guides(colour: none),
  labs: labs(
    title: "Penguin Morphology by Sex and Species",
    x: "Flipper Length (mm)",
    y: "Body Mass (g)",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
