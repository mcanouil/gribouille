// geom-spoke: vector field of unit-length arrows on a small grid.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let field = ()
#for i in range(0, 7) {
  for j in range(0, 7) {
    let dx = i - 3
    let dy = j - 3
    let mag = calc.sqrt(dx * dx + dy * dy)
    if mag == 0 { continue }
    field.push((
      x: i,
      y: j,
      angle: calc.atan2(dy, dx),
      r: 0.35 + 0.05 * mag,
      mag: mag,
    ))
  }
}

#plot(
  data: field,
  mapping: aes(x: "x", y: "y", angle: "angle", radius: "r", colour: "mag"),
  layers: (
    geom-spoke(stroke: 0.8pt),
    geom-point(size: 1.5pt),
  ),
  scales: scales(colour: scale-viridis-c()),
  coord: coord-fixed(),
  labels: labels(
    title: "Radial Vector Field",
    subtitle: "Spoke direction = atan2(Δy, Δx); colour = distance from origin",
    x: "X",
    y: "Y",
    colour: "Magnitude",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
