// plot sizing: `auto` width/height under an unbounded page no longer panics; it
// falls back to the default 10cm x 7cm so the plot still renders.

#import "../../src/plot.typ": plot
#import "../../src/aes.typ": aes
#import "../../src/geom/point.typ": geom-point

#set page(width: auto, height: auto, margin: 0cm)

#let data = ((x: 1, y: 2), (x: 2, y: 3), (x: 3, y: 1))

#context {
  let m = measure(plot(
    data: data,
    mapping: aes(x: "x", y: "y"),
    layers: (geom-point(),),
    width: auto,
    height: auto,
  ))
  assert(
    m.width > 9cm and m.width < 11cm,
    message: "plot auto width should fall back to 10cm, got " + repr(m.width),
  )
}

Plot auto-size fallback test passed.
