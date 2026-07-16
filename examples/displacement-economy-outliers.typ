// Showcase: scatter with a trend line and named outliers; the two-seaters
// that defy the trend get labels instead of leaving readers guessing.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let accent = okabe-ito.at(5)
#let alert = okabe-ito.at(6)

#let two-seaters = mpg.filter(row => row.class == "2seater")

#plot(
  data: mpg,
  mapping: aes(x: "displ", y: "hwy"),
  layers: (
    geom-smooth(
      method: "lm",
      se: true,
      alpha: 0.15,
      colour: accent,
      fill: accent,
    ),
    geom-point(size: 2.4pt, alpha: 0.55, fill: accent),
    geom-point(
      inherit-aes: false,
      data: two-seaters,
      mapping: aes(x: "displ", y: "hwy"),
      size: 3pt,
      fill: alert,
    ),
    geom-text(
      inherit-aes: false,
      data: two-seaters,
      mapping: aes(x: "displ", y: "hwy", label: "model"),
      nudge-y: 0.35cm,
      size: 8pt,
      colour: alert,
    ),
  ),
  labels: labels(
    title: "Big engines cost fuel economy, sports cars excepted",
    subtitle: "Highway mpg against engine displacement with a linear trend",
    x: "Engine displacement (litres)",
    y: "Highway mpg",
    caption: "Source: bundled mpg dataset; the labelled point is a two-seater.",
  ),
  theme: theme-minimal(),
  width: 13cm,
  height: 8cm,
)
