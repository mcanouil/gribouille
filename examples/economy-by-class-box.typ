// Showcase: boxplots ordered by median with the raw observations jittered
// behind them; summaries never hide the data they summarise.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let accent = okabe-ito.at(5)

#plot(
  data: mpg,
  mapping: aes(x: "class", y: "hwy"),
  layers: (
    geom-boxplot(fill: accent, alpha: 0.35, outlier-size: 0pt),
    geom-jitter(
      size: 2pt,
      alpha: 0.5,
      colour: accent,
      position: position-jitter(width: 0.12, seed: 42),
    ),
  ),
  labels: labels(
    title: "Fuel economy varies as much within classes as between them",
    subtitle: "Highway mpg per vehicle class, with the raw data behind each box",
    x: "",
    y: "Highway mpg",
    caption: "Source: bundled mpg dataset.",
  ),
  theme: theme-minimal(),
  width: 13cm,
  height: 8cm,
)
