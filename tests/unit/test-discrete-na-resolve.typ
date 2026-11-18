// The NA level of a trained discrete scale resolves to the scale's `na-value`,
// else to the default of the aesthetic. It never takes a palette entry, so the
// palette index of a real level is the same with and without the NA level.

#import "../../src/utils/level-resolve.typ": (
  discrete-numeric, na-value-of, resolve-level,
)
#import "../../src/utils/types.typ": NA-KEY

#let plain = (type: "discrete", domain: ("f", "m"), na-level: false)
#let with-na = (
  type: "discrete",
  domain: ("f", "m", NA-KEY),
  na-level: true,
)
#let user-na(value) = (..with-na, spec: (na-value: value))
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
#assert.eq(resolve-level("shape", with-na, none), "circle-open")
#assert.eq(resolve-level("linetype", with-na, none), "loosely-dotted")
#assert.eq(resolve-level("size", with-na, none), none)

// A user `na-value` wins.
#assert.eq(resolve-level("colour", user-na(blue), none, palette: pal), blue)
#assert.eq(resolve-level("shape", user-na("x"), none), "x")
#assert.eq(resolve-level("linetype", user-na("dashed"), none), "dashed")
#assert.eq(resolve-level("size", user-na(3pt), none), 3pt)

// Without an NA level, a missing cell keeps today's answer.
#assert.eq(
  resolve-level("colour", plain, none, palette: pal, ink: black),
  black,
)
#assert.eq(resolve-level("shape", plain, none), none)

// The NA level takes no slot in the spacing.
#for level in ("f", "m") {
  assert.eq(
    discrete-numeric(with-na, level, (1pt, 5pt)),
    discrete-numeric(plain, level, (1pt, 5pt)),
  )
}
#assert.eq(discrete-numeric(plain, "f", (1pt, 5pt)), 1pt)
#assert.eq(discrete-numeric(plain, "m", (1pt, 5pt)), 5pt)

#assert.eq(na-value-of(with-na, "size", 2pt), 2pt)

// A palette-backed length scale draws the NA level at the geom default, or at
// its own `na-value`.
#import "../../src/utils/colour-resolve.typ": _resolve-length-natural
#let size-scale(spec) = (
  type: "discrete",
  domain: ("f", "m", NA-KEY),
  na-level: true,
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
#assert.eq(size-of((na-value: none), none), 3pt)
#assert.eq(size-of((na-value: none), ""), 3pt)
#assert.eq(size-of((na-value: 8pt), none), 8pt)
#assert.eq(size-of((na-value: none), "m"), 5pt)
