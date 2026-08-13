// Constructor surface + end-to-end render smoke for `repel: true` on
// text/label/typst geoms. Compile is the assertion: the renderer must
// pre-measure label sizes, run repel before opening cetz canvas, and
// the geom must read the offsets at draw time.

#import "../../src/aes.typ": aes
#import "../../src/geom/text.typ": geom-text
#import "../../src/geom/label.typ": geom-label
#import "../../src/geom/typst.typ": geom-typst
#import "../../src/plot.typ": plot
#import "../../src/utils/arrow.typ": arrow

// Constructor wiring on each of the three geoms.
#let t = geom-text(repel: true)
#assert.eq(t.params.repel, true)
#assert.eq(t.params.point-padding, 0.05)
#assert.eq(t.params.max-iter, 100)
#assert.eq(t.params.force-pull, 0.1)
#assert.eq(t.params.force-push, 0.2)
#assert.eq(t.params.force-segment, 0.3)
#assert.eq(t.params.seed, 0)

#let l = geom-label(repel: true, seed: 42)
#assert.eq(l.params.repel, true)
#assert.eq(l.params.seed, 42)

#let g = geom-typst(repel: true, max-iter: 50)
#assert.eq(g.params.repel, true)
#assert.eq(g.params.max-iter, 50)

// End-to-end render with clustered points so repel actually moves labels.
#let d = (
  (x: 1.0, y: 1.0, lab: "a"),
  (x: 1.05, y: 1.05, lab: "b"),
  (x: 1.1, y: 1.0, lab: "c"),
  (x: 1.0, y: 1.1, lab: "d"),
)

#plot(
  data: d,
  mapping: aes(x: "x", y: "y", label: "lab"),
  layers: (geom-text(repel: true, segment: true),),
  width: 10cm,
  height: 6cm,
)

#plot(
  data: d,
  mapping: aes(x: "x", y: "y", label: "lab"),
  layers: (geom-label(repel: true, segment: true, arrow: arrow()),),
  width: 10cm,
  height: 6cm,
)

geom-text/label/typst repel smoke test passed.
