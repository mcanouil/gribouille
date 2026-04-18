// scale-colour-manual: user-supplied palette.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#let obs = ()
#for i in range(0, 10) {
  obs.push((x: i, y: i, g: "apple"))
  obs.push((x: i, y: i + 1, g: "berry"))
  obs.push((x: i, y: i + 2, g: "cherry"))
}

#plot(
  data: obs,
  mapping: aes(x: "x", y: "y", colour: "g"),
  layers: (geom-point(size: 4pt), geom-line()),
  scales: (
    scale-colour-manual(values: (
      rgb("#e63946"),
      rgb("#f4a261"),
      rgb("#2a9d8f"),
    )),
  ),
  labs: labs(title: "Manual palette"),
  width: 10cm,
  height: 7cm,
)
