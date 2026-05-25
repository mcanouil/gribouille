// compose sizing: an unbounded container falls back to the 16cm x 12cm default
// and panels fill their cells, so the composition is far wider than the two
// 6cm panels would be at their own declared size.

#import "../../src/plot.typ": plot
#import "../../src/compose.typ": compose
#import "../../src/aes.typ": aes
#import "../../src/geom/point.typ": geom-point

#set page(width: auto, height: auto, margin: 0cm)

#let data = (
  (x: 1, y: 2),
  (x: 2, y: 3),
  (x: 3, y: 1),
)
#let panel = plot(
  data: data,
  mapping: aes(x: "x", y: "y"),
  layers: (geom-point(),),
  width: 6cm,
  height: 4cm,
  defer: true,
)

// Rendered under an unbounded page, the composition takes the 16cm fallback and
// stretches the panels to fill it; two intrinsic 6cm panels would total ~12cm.
#context {
  let m = measure(compose(panel, panel, columns: 2))
  assert(
    m.width > 14cm,
    message: "compose should fill the 16cm default, got " + repr(m.width),
  )
}

Compose sizing test passed.
