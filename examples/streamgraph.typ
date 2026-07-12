// streamgraph: stacked geom-area on a silhouette baseline (ThemeRiver).

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let genres = ("Drama", "Comedy", "Action", "Sci-Fi")

#let releases = ()
#for (gi, genre) in genres.enumerate() {
  for month in range(0, 24) {
    let wave = calc.sin(month * 0.4 + gi * 1.3) * (1.2 + gi * 0.4)
    let base = 4 + gi * 0.6 + month * 0.05
    releases.push((month: month, titles: base + wave, genre: genre))
  }
}

#plot(
  data: releases,
  mapping: aes(x: "month", y: "titles", fill: "genre"),
  layers: (
    geom-area(position: position-stack(offset: "silhouette"), alpha: 0.85),
  ),
  scales: scales(fill: scale-okabe-ito(name: "Genre")),
  labels: labels(
    title: "Streaming Releases by Genre",
    subtitle: "Silhouette baseline centres each stack on zero",
    x: "Month",
    caption: "Band thickness encodes titles released per month",
  ),
  guides: guides(y: none),
  theme: theme-minimal(),
  width: 13cm,
  height: 7cm,
)
