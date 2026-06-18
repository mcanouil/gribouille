// Character symbols: shape values that are not built-in keywords render as
// literal glyphs, here a letter per species drawn at each point.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#plot(
  data: penguins,
  mapping: aes(
    x: "flipper-len",
    y: "body-mass",
    shape: "species",
    colour: "species",
  ),
  layers: (
    geom-point(size: 4pt),
  ),
  scales: (
    scale-shape-manual(values: ("A", "C", "G")),
    scale-colour-brewer(palette: "Dark2"),
  ),
  labs: labs(
    title: "Character Symbols as Markers",
    subtitle: "shape values outside the built-in keywords render as literal glyphs",
    x: "Flipper length",
    y: "Body mass",
    shape: "Species",
    colour: "Species",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
