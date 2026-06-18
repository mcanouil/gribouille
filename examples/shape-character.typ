// Character symbols: shape values outside the built-in keywords render as
// literal glyphs. Values may be a plain character, a Typst `sym.` symbol, or
// an emoji, mixed freely across levels.

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
    geom-point(size: 5pt),
  ),
  scales: (
    scale-shape-manual(values: ("A", sym.star.filled, "🐧")),
    scale-colour-brewer(palette: "Dark2"),
  ),
  labs: labs(
    title: "Character Symbols as Markers",
    subtitle: "A plain character, a Typst sym., and an emoji as shape values",
    x: "Flipper length",
    y: "Body mass",
    shape: "Species",
    colour: "Species",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
