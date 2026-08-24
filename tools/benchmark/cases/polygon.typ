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

// The vertex total is exactly `n`, as in every other case. A ring needs three
// vertices to be a polygon at all, so a small `n` is drawn as fewer rings
// rather than as more vertices than asked for. Twelve is the ceiling, which
// every size from thirty-six upward reaches.
#let rings = calc.max(1, calc.min(12, int(n / 3)))
#let base-per-ring = calc.max(3, int(n / rings))
// The remainder of the split is spread one vertex at a time over the first
// rings.
#let remainder = calc.max(0, n - base-per-ring * rings)

#let ring-rows(r) = {
  // The grid pitch keeps the rings disjoint: the largest reaches
  // `1.5 * 1.18 = 1.77`, inside the half-pitch of 2.0. Overlapping translucent
  // fills would add compositing work, which is not the cost this case isolates.
  let cx = calc.rem(r, 4) * 4.0 + 2.0
  let cy = int(r / 4) * 4.0 + 2.0
  let radius = 1.0 + calc.rem(r, 3) * 0.25
  let per-ring = base-per-ring + if r < remainder { 1 } else { 0 }
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
