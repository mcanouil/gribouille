// Showcase: dodged bars comparing city and highway economy per class; two
// dodge groups keep the within-class comparison easy, Okabe-Ito keeps it safe.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let long = pivot-longer(
  mpg,
  ("cty", "hwy"),
  names-to: "metric",
  values-to: "mpg",
)

#let by-class = summarise(
  long,
  mean-mpg: rows => rows.map(row => row.mpg).sum() / rows.len(),
  by: ("class", "metric"),
)

#let class-order = (
  summarise(
    mpg,
    mean-hwy: rows => rows.map(row => row.hwy).sum() / rows.len(),
    by: "class",
  )
    .sorted(key: row => row.mean-hwy)
    .map(row => row.class)
)

#let metric-names = (cty: "City", hwy: "Highway")

#plot(
  data: by-class.map(row => (..row, metric: metric-names.at(row.metric))),
  mapping: aes(x: "class", y: "mean-mpg", fill: "metric"),
  layers: (geom-col(position: "dodge"),),
  scales: scales(
    x: scale-discrete(limits: class-order),
    fill: scale-okabe-ito(),
  ),
  labels: labels(
    title: "Highway economy beats city economy in every class",
    subtitle: "Mean miles per gallon by vehicle class and driving condition",
    x: "",
    y: "Mean mpg",
    fill: "Condition",
    caption: "Source: bundled mpg dataset.",
  ),
  theme: theme-minimal(),
  width: 13cm,
  height: 7.5cm,
)
