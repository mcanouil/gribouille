// Minimal scatter plot with inline data.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let iris = (
  (sepal-length: 5.1, sepal-width: 3.5, species: "setosa"),
  (sepal-length: 4.9, sepal-width: 3.0, species: "setosa"),
  (sepal-length: 4.7, sepal-width: 3.2, species: "setosa"),
  (sepal-length: 7.0, sepal-width: 3.2, species: "versicolor"),
  (sepal-length: 6.4, sepal-width: 3.2, species: "versicolor"),
  (sepal-length: 6.9, sepal-width: 3.1, species: "versicolor"),
  (sepal-length: 6.3, sepal-width: 3.3, species: "virginica"),
  (sepal-length: 5.8, sepal-width: 2.7, species: "virginica"),
  (sepal-length: 7.1, sepal-width: 3.0, species: "virginica"),
)

#plot(
  data: iris,
  mapping: aes(x: "sepal-length", y: "sepal-width", fill: "species"),
  layers: (geom-point(size: 3pt),),
  labels: labels(
    title: "Iris Sepal Dimensions",
    x: "Sepal Length (cm)",
    y: "Sepal Width (cm)",
    fill: "Species",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
