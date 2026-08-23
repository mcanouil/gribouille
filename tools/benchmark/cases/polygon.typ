// Benchmark case: geom-polygon. Many vertices carried by few marks, which is
// the shape a boundary or outline layer has. The vertex count `n` is injected
// via `--input n=<count>` and split across a fixed number of rings, so the
// number of drawn marks stays constant while the vertex count grows.
//
// Every other case is either one mark per row or an aggregation down to a
// fixed grid. Neither covers this shape, and it is the one that decides
// whether cartography is tractable.

#import "../../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let n = int(sys.inputs.at("n", default: "100"))

#let rings = 12
#let per-ring = calc.max(3, int(n / rings))

#let ring-rows(r) = {
  let cx = calc.rem(r, 4) * 3.0 + 1.5
  let cy = int(r / 4) * 3.0 + 1.5
  let radius = 1.0 + calc.rem(r, 3) * 0.25
  range(0, per-ring).map(i => {
    let theta = i / per-ring * 2 * calc.pi
    // A wobble on the radius keeps the outline from collapsing onto a shape
    // the renderer could simplify, so the vertex count is really paid.
    let wobble = 1 + 0.18 * calc.sin(theta * 7)
    (
      x: cx + radius * wobble * calc.cos(theta),
      y: cy + radius * wobble * calc.sin(theta),
      ring: "r" + str(r),
    )
  })
}

#let d = range(0, rings).map(ring-rows).flatten()

#plot(
  data: d,
  mapping: aes(x: "x", y: "y", group: "ring", fill: "ring"),
  layers: (geom-polygon(alpha: 0.55, stroke: 0.4pt),),
  guides: guides(fill: none),
  width: 12cm,
  height: 7cm,
)
