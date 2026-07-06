// ColorBrewer + gradient scale unit tests.

#import "../../src/utils/palette.typ": brewer-palette, brewer-palettes
#import "../../src/utils/colour.typ": (
  interpolate-stops, resolve-continuous-colour,
)
#import "../../src/scale/colour.typ": (
  _scale-brewer, _scale-gradient, _scale-gradient2, _scale-gradientn,
)

// brewer-palette returns the canonical first colour for each palette.
#assert.eq(brewer-palette("Set1").first(), rgb("#e41a1c"))
#assert.eq(brewer-palette("Set2").first(), rgb("#66c2a5"))
#assert.eq(brewer-palette("Dark2").first(), rgb("#1b9e77"))
#assert.eq(brewer-palette("Spectral").first(), rgb("#d53e4f"))
#assert.eq(brewer-palette("Blues").first(), rgb("#f7fbff"))
#assert.eq(brewer-palette("RdBu").first(), rgb("#b2182b"))

// All advertised palettes are present.
#let expected-palettes = (
  "Set1",
  "Set2",
  "Set3",
  "Pastel1",
  "Pastel2",
  "Dark2",
  "Accent",
  "Paired",
  "Blues",
  "Greens",
  "Oranges",
  "Reds",
  "Purples",
  "Greys",
  "YlOrRd",
  "YlGnBu",
  "RdBu",
  "RdYlBu",
  "RdYlGn",
  "Spectral",
  "BrBG",
  "PiYG",
  "PuOr",
  "PRGn",
)
#for name in expected-palettes {
  assert(name in brewer-palettes, message: "Missing brewer palette: " + name)
  assert(brewer-palette(name).len() >= 7)
}

// brewer scales carry the colour array as their palette.
#let s = _scale-brewer("colour", palette: "Set1")
#assert.eq(s.kind, "scale")
#assert.eq(s.aesthetic, "colour")
#assert.eq(s.type, "discrete")
#assert.eq(s.palette, brewer-palette("Set1"))

#let sf = _scale-brewer("fill", palette: "Spectral")
#assert.eq(sf.aesthetic, "fill")
#assert.eq(sf.type, "discrete")
#assert.eq(sf.palette, brewer-palette("Spectral"))

// gradient scales carry the right palette shape.
#let g1 = _scale-gradient("colour")
#assert.eq(g1.type, "continuous")
#assert.eq(g1.palette.len(), 2)

#let g2 = _scale-gradient2("colour", midpoint: 0)
#assert.eq(g2.type, "continuous")
#assert.eq(g2.palette.len(), 3)
#assert.eq(g2.midpoint, 0)

#let gn = _scale-gradientn("colour", colours: (
  rgb("#000000"),
  rgb("#888888"),
  rgb("#ffffff"),
))
#assert.eq(gn.type, "continuous")
#assert.eq(gn.palette.len(), 3)

// Fill counterparts mirror colour.
#assert.eq(_scale-gradient("fill").aesthetic, "fill")
#assert.eq(_scale-gradient2("colour", midpoint: 0).midpoint, 0)
#assert.eq(
  _scale-gradientn("colour", colours: (rgb("#000"), rgb("#fff"))).palette.len(),
  2,
)

// interpolate-stops walks adjacent stops linearly.
#let stops = (rgb("#000000"), rgb("#ffffff"))
#assert.eq(interpolate-stops(stops, 0.0), rgb("#000000"))
#assert.eq(interpolate-stops(stops, 1.0), rgb("#ffffff"))

// resolve-continuous-colour with a midpoint splits the interpolation.
#let trained-mid = (
  type: "continuous",
  domain: (-5.0, 5.0),
  spec: (
    aesthetic: "colour",
    type: "continuous",
    palette: (rgb("#0000ff"), rgb("#ffffff"), rgb("#ff0000")),
    midpoint: 0,
  ),
)
#let pal-mid = (rgb("#0000ff"), rgb("#ffffff"), rgb("#ff0000"))
#assert.eq(
  resolve-continuous-colour(trained-mid, -5.0, pal-mid, black),
  rgb("#0000ff"),
)
#assert.eq(
  resolve-continuous-colour(trained-mid, 0.0, pal-mid, black),
  rgb("#ffffff"),
)
#assert.eq(
  resolve-continuous-colour(trained-mid, 5.0, pal-mid, black),
  rgb("#ff0000"),
)

Brewer + gradient scale tests passed.
