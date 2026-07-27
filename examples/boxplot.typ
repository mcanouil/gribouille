// stat-boxplot reduces each group to a five-number summary; geom-boxplot draws the Tukey box.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#plot(
  data: mpg,
  mapping: aes(x: "class", y: "hwy", fill: "class"),
  layers: (geom-boxplot(),),
  guides: guides(fill: none),
  labels: labels(
    title: "Highway Fuel Economy by Vehicle Class",
    subtitle: "Boxes show the inter-quartile range; whiskers and dots flag outliers",
    x: "Class",
    y: "Highway mpg",
  ),
  theme: theme(
    axis-ticks: element-tick(length: 0.5cm),
  ),
  width: 12cm,
  height: 9cm,
)
