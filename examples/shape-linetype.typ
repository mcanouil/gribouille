// shape and linetype aesthetics: one mark and dash style per group.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#let obs = ()
#for i in range(0, 10) {
  obs.push((t: i, value: i, group: "A"))
  obs.push((t: i, value: i * 0.8 + 1, group: "B"))
  obs.push((t: i, value: i * 0.5 + 2, group: "C"))
}

#plot(
  data: obs,
  mapping: aes(x: "t", y: "value", shape: "group", linetype: "group", colour: "group"),
  layers: (
    geom-line(),
    geom-point(size: 5pt),
  ),
  labs: labs(title: "Shapes and linetypes per group"),
  width: 10cm,
  height: 7cm,
)
