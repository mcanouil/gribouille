// Smoke render: grouped histogram with shared bin grid across positions.
//
// Three panels exercise the per-group fill split with the panel-level bin
// setup that aligns midpoints across groups: stack (default), dodge, and
// identity (overlapping).

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let palette = (
  rgb("#ff8c00"),
  rgb("#008B8B"),
  rgb("#800080"),
)
#let species = ("Adelie", "Chinstrap", "Gentoo")

#let render(label, position) = plot(
  data: penguins,
  mapping: aes(x: "flipper-len", fill: "species"),
  layers: (geom-histogram(bins: 10, position: position),),
  scales: (
    scale-fill-discrete(limits: species, palette: palette),
  ),
  labels: labels(title: label, x: "Flipper length (mm)"),
  theme: theme-minimal(),
  width: 8cm,
  height: 5cm,
)

#stack(
  dir: ttb,
  spacing: 0.5cm,
  render("position: stack (default)", "stack"),
  render("position: dodge", "dodge"),
  render("position: identity", "identity"),
)
