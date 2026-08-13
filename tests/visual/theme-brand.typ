// Smoke render: a brand's chrome, fonts, and derived palette in both modes.

#import "../../lib.typ": *

#let brand = (
  color: (
    palette: (
      "paper-light": "#FFFAF0",
      "paper-dark": "#161B1E",
      "ink-light": "#1A1A1A",
      "ink-dark": "#F4EDDF",
    ),
    foreground: (light: "ink-light", dark: "ink-dark"),
    background: (light: "paper-light", dark: "paper-dark"),
    primary: (light: "#E94C3D", dark: "#FF6F60"),
    secondary: (light: "#1F7A8C", dark: "#5BB5C7"),
    tertiary: (light: "#F4B740", dark: "#FFD166"),
    success: (light: "#7FC8A9", dark: "#9CDCC0"),
    // Aliases secondary, so the derived palette de-duplicates it away.
    info: (light: "#1F7A8C", dark: "#5BB5C7"),
    danger: "#B23A2B",
  ),
)

#let d = range(0, 25).map(i => (
  x: i,
  y: calc.rem(i * 7, 11),
  g: ("a", "b", "c", "d", "e").at(calc.rem(i, 5)),
))

#let panel(mode) = plot(
  data: d,
  mapping: aes(x: "x", y: "y", colour: "g"),
  layers: (geom-point(size: 3pt),),
  labels: labels(title: "Brand theme, " + mode + " mode"),
  theme: theme-brand(brand, mode: mode),
  width: 10cm,
  height: 6cm,
)

#panel("light")

#panel("dark")

// The brand's chrome with the library's default data ink.
#plot(
  data: d,
  mapping: aes(x: "x", y: "y", colour: "g"),
  layers: (geom-point(size: 3pt),),
  labels: labels(title: "Brand chrome, default palette"),
  theme: theme-brand(brand, palette: none),
  width: 10cm,
  height: 6cm,
)
