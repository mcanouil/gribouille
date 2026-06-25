// Benchmark case: geom-point. One marker per row, so cost scales linearly with
// the element count `n` (`--input n=<count>`). The `variant` input
// (`--input variant=<name>`) switches render settings so the harness can
// measure how marker size, shape, and alpha affect compile cost and output
// size at a fixed count:
//   base   filled circle, small      (reference)
//   large  larger filled circle      (more raster/vector coverage)
//   star   star glyph                (heavier per-marker path)
//   alpha  translucent small circle  (blending pressure)

#import "../../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let n = int(sys.inputs.at("n", default: "100"))
#let variant = sys.inputs.at("variant", default: "base")

#let settings = (
  base: (size: 1.5pt, alpha: 0.6),
  large: (size: 4pt, alpha: 0.6),
  star: (size: 2.5pt, shape: "star", alpha: 0.8),
  alpha: (size: 1.5pt, alpha: 0.25),
)
#let opts = settings.at(variant, default: settings.base)

#let d = range(0, n).map(i => {
  let t = i / n
  let theta = t * 6 * calc.pi
  (x: t * 12, y: calc.sin(theta) + t * 3)
})

#plot(
  data: d,
  mapping: aes(x: "x", y: "y"),
  layers: (geom-point(..opts),),
  width: 12cm,
  height: 7cm,
)
