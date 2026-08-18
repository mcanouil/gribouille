// Showcase: mean highway economy with 95% confidence intervals as
// point-ranges; intervals over "dynamite" bars, and the caption says what
// the range is.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let accent = okabe-ito.at(5)

#plot(
  data: mpg,
  mapping: aes(x: "class", y: "hwy"),
  layers: (
    geom-jitter(
      size: 2pt,
      alpha: 0.25,
      colour: accent,
      position: position-jitter(width: 0.1, seed: 42),
    ),
    geom-pointrange(
      stat: stat-summary(fun: "mean-cl-normal"),
      size: 3.5pt,
      stroke: 1.2pt,
      colour: accent,
      fill: accent,
    ),
  ),
  labels: labels(
    title: "Compact, midsize, and subcompact cannot be told apart",
    subtitle: "Mean highway mpg per vehicle class with 95% confidence intervals",
    x: none,
    y: "Highway mpg",
    caption: "Interval: normal-theory 95% CI of the mean; classes with a single observation carry no interval. Source: bundled mpg dataset.",
  ),
  theme: theme-minimal(axis-ticks-x: element-tick(length: 0.12cm)),
  width: 12cm,
  height: 8cm,
)
