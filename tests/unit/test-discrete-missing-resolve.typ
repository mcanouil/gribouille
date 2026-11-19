// The missing level of a trained discrete scale resolves to the scale's `missing-value`,
// else to the default of the aesthetic. It never takes a palette entry, so the
// palette index of a real level is the same with and without the missing level.

#import "../../src/utils/level-resolve.typ": (
  discrete-numeric, missing-value-of, resolve-level,
)
#import "../../src/utils/types.typ": MISSING-KEY

#let plain = (type: "discrete", domain: ("f", "m"), missing-level: false)
#let with-na = (
  type: "discrete",
  domain: ("f", "m", MISSING-KEY),
  missing-level: true,
)
#let user-na(value) = (..with-na, spec: (missing-value: value))
#let pal = (red, green, blue)

// Real levels keep their palette entry.
#for level in ("f", "m") {
  assert.eq(
    resolve-level("colour", with-na, level, palette: pal),
    resolve-level("colour", plain, level, palette: pal),
  )
  assert.eq(
    resolve-level("shape", with-na, level),
    resolve-level("shape", plain, level),
  )
  assert.eq(
    resolve-level("linetype", with-na, level),
    resolve-level("linetype", plain, level),
  )
}

// Defaults.
#assert.eq(resolve-level("colour", with-na, none, palette: pal), luma(50%))
#assert.eq(resolve-level("fill", with-na, "", palette: pal), luma(50%))
#assert.eq(resolve-level("shape", with-na, none), "circle-cross")
#assert.eq(resolve-level("linetype", with-na, none), "loosely-dotted")
#assert.eq(resolve-level("size", with-na, none), none)

// A user `missing-value` wins.
#assert.eq(resolve-level("colour", user-na(blue), none, palette: pal), blue)
#assert.eq(resolve-level("shape", user-na("x"), none), "x")
#assert.eq(resolve-level("linetype", user-na("dashed"), none), "dashed")
#assert.eq(resolve-level("size", user-na(3pt), none), 3pt)

// Without a missing level, a missing cell keeps today's answer.
#assert.eq(
  resolve-level("colour", plain, none, palette: pal, ink: black),
  black,
)
#assert.eq(resolve-level("shape", plain, none), none)

// The missing level takes no slot in the spacing.
#for level in ("f", "m") {
  assert.eq(
    discrete-numeric(with-na, level, (1pt, 5pt)),
    discrete-numeric(plain, level, (1pt, 5pt)),
  )
}
#assert.eq(discrete-numeric(plain, "f", (1pt, 5pt)), 1pt)
#assert.eq(discrete-numeric(plain, "m", (1pt, 5pt)), 5pt)

#assert.eq(missing-value-of(with-na, "size", 2pt), 2pt)

// A palette-backed length scale draws the missing level at the geom default, or at
// its own `missing-value`.
#import "../../src/utils/colour-resolve.typ": _resolve-length-natural
#let size-scale(spec) = (
  type: "discrete",
  domain: ("f", "m", MISSING-KEY),
  missing-level: true,
  spec: (palette: (2pt, 5pt), ..spec),
)
#let size-of(spec, cell) = _resolve-length-natural(
  "size",
  (1pt, 6pt),
  "g",
  (trained: (size: size-scale(spec))),
  (g: cell),
  3pt,
)
#assert.eq(size-of((missing-value: none), none), 3pt)
#assert.eq(size-of((missing-value: none), ""), 3pt)
#assert.eq(size-of((missing-value: 8pt), none), 8pt)
#assert.eq(size-of((missing-value: none), "m"), 5pt)
