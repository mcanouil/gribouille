// Unit tests for colour-mix.

#import "../../src/utils/colour.typ": colour-mix

// Tolerance is in 0..255 sRGB units; ±5 accommodates Typst's mix rounding.
#let near(a, b, tol: 5) = {
  let ac = a.rgb().components(alpha: false)
  let bc = b.rgb().components(alpha: false)
  for (x, y) in ac.zip(bc) {
    let dx = (x / 1% - y / 1%) * 255 / 100
    if calc.abs(dx) > tol { return false }
  }
  true
}

#let blk = rgb("#000000")
#let wht = rgb("#ffffff")

#assert(near(colour-mix(blk, wht, 0), blk))
#assert(near(colour-mix(blk, wht, 1), wht))
#assert(near(colour-mix(blk, wht, 0.5), rgb("#808080")))

#let m92 = colour-mix(blk, wht, 0.92)
#assert(near(m92, rgb("#ebebeb")))
#assert(not near(m92, blk, tol: 100))

colour-mix tests passed.
