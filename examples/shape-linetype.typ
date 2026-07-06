// shape and linetype aesthetics: one mark and one dash style per group.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let obs = ()
#for i in range(0, 10) {
  obs.push((t: i, value: i, group: "A"))
  obs.push((t: i, value: i * 0.8 + 1, group: "B"))
  obs.push((t: i, value: i * 0.5 + 2, group: "C"))
}

#plot(
  data: obs,
  mapping: aes(
    x: "t",
    y: "value",
    shape: "group",
    linetype: "group",
    colour: "group",
  ),
  layers: (
    geom-line(stroke: 1pt),
    geom-point(size: 4pt),
  ),
  scales: scales(colour: scale-brewer(palette: "Dark2")),
  labels: labels(
    title: "One Shape and One Linetype per Group",
    subtitle: "Using shape + linetype + colour together makes groups legible without colour alone",
    x: "T",
    y: "Value",
    colour: "Group",
    shape: "Group",
    linetype: "Group",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
