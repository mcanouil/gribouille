// `width`/`height` set to `auto` fill the available container space.

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

#let base-plot(width: auto, height: auto, alt: none) = plot(
  data: iris,
  mapping: aes(x: "sepal-length", y: "sepal-width", fill: "species"),
  layers: (geom-point(size: 3pt),),
  labs: labs(
    title: "Iris",
    x: "Sepal Length",
    y: "Sepal Width",
    fill: "Species",
  ),
  theme: theme-minimal(),
  width: width,
  height: height,
  alt: alt,
)

// `width: auto` fills the fixed-width container; height stays concrete.
#box(width: 11cm, base-plot(width: auto, height: 7cm))

// Both `auto` fill a fixed-size container.
#box(width: 11cm, height: 8cm, base-plot(width: auto, height: auto))

// Faceted plot with `auto` width exercises per-panel sizing.
#box(width: 14cm, plot(
  data: iris,
  mapping: aes(x: "sepal-length", y: "sepal-width", fill: "species"),
  layers: (geom-point(size: 3pt),),
  facet: facet-wrap("species"),
  theme: theme-minimal(),
  width: auto,
  height: 7cm,
))

// `auto` width together with alt text routes through the figure wrapper.
#box(width: 11cm, base-plot(
  width: auto,
  height: 7cm,
  alt: "Scatter of iris sepal width against sepal length, coloured by species.",
))
