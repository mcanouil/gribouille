// Character symbols: shape values outside the built-in keywords render as
// literal glyphs. Values may be a plain character or a Typst `sym.` symbol,
// mixed freely across levels.

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
  scales: scales(shape: scale-manual(values: ("A", sym.star.filled, "λ")), colour: scale-brewer(palette: "Dark2")),
  labels: labels(
    title: "Character Symbols as Markers",
    subtitle: "A Latin letter, a Typst sym., and a Greek letter as shape values",
    x: "Flipper length",
    y: "Body mass",
    shape: "Species",
    colour: "Species",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
