// Showcase: a smoother whose confidence band is explained where it is read;
// the caption states exactly what the shading means.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let accent = okabe-ito.at(5)

#plot(
  data: mpg,
  mapping: aes(x: "displ", y: "hwy"),
  layers: (
    geom-point(size: 2.2pt, alpha: 0.45, fill: accent),
    geom-smooth(
      method: "lm",
      se: true,
      level: 0.95,
      colour: accent,
      fill: accent,
      alpha: 0.2,
    ),
  ),
  labels: labels(
    title: "Each added litre of displacement costs about 3.5 highway mpg",
    subtitle: "Linear fit with its 95% confidence band",
    x: "Engine displacement (litres)",
    y: "Highway mpg",
    caption: "The band covers the mean response with 95% confidence; single vehicles vary more widely. Source: bundled mpg dataset.",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 8cm,
)
