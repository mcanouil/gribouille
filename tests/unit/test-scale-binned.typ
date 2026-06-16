// Binned scale family unit tests.
//
// Asserts the spec dict shape for each binned scale wrapper: kind, aesthetic,
// type, and the binned/n-breaks fields that the renderer reads to quantise
// continuous lookups.

#import "../../src/scale/colour.typ": (
  scale-colour-fermenter, scale-colour-steps, scale-colour-steps2,
  scale-colour-stepsn, scale-fill-fermenter, scale-fill-steps,
  scale-fill-steps2, scale-fill-stepsn,
)
#import "../../src/scale/continuous.typ": scale-x-binned, scale-y-binned
#import "../../src/scale/size.typ": (
  scale-size-area, scale-size-binned, scale-size-binned-area,
)
#import "../../src/scale/train.typ": train
#import "../../src/render/axis-format.typ": _axis-breaks
#import "../../src/aes.typ": aes
#import "../../src/geom/point.typ": geom-point
#import "../../src/utils/colour.typ": resolve-continuous-colour
#import "../../src/utils/palette.typ": brewer-palette

// scale-colour-steps: two-stop binned gradient.
#let s1 = scale-colour-steps(n-breaks: 5)
#assert.eq(s1.kind, "scale")
#assert.eq(s1.aesthetic, "colour")
#assert.eq(s1.type, "continuous")
#assert.eq(s1.binned, true)
#assert.eq(s1.n-breaks, 5)
#assert.eq(s1.palette.len(), 2)

// scale-colour-steps2: diverging binned gradient with midpoint.
#let s2 = scale-colour-steps2(midpoint: 0, n-breaks: 6)
#assert.eq(s2.aesthetic, "colour")
#assert.eq(s2.type, "continuous")
#assert.eq(s2.binned, true)
#assert.eq(s2.n-breaks, 6)
#assert.eq(s2.midpoint, 0)
#assert.eq(s2.palette.len(), 3)

// scale-colour-stepsn: n-stop binned gradient.
#let s3 = scale-colour-stepsn(
  colours: (rgb("#000"), rgb("#888"), rgb("#fff")),
  n-breaks: 4,
)
#assert.eq(s3.binned, true)
#assert.eq(s3.n-breaks, 4)
#assert.eq(s3.palette.len(), 3)

// scale-colour-fermenter: binned ColorBrewer gradient.
#let s4 = scale-colour-fermenter(palette: "Spectral", n-breaks: 7)
#assert.eq(s4.binned, true)
#assert.eq(s4.n-breaks, 7)
#assert.eq(s4.palette, brewer-palette("Spectral"))

// Direction reversal flips the palette.
#let s4r = scale-colour-fermenter(
  palette: "Spectral",
  direction: -1,
  n-breaks: 7,
)
#assert.eq(s4r.palette, brewer-palette("Spectral").rev())

// Fill counterparts mirror colour ones.
#assert.eq(scale-fill-steps(n-breaks: 5).aesthetic, "fill")
#assert.eq(scale-fill-steps2(midpoint: 1, n-breaks: 5).aesthetic, "fill")
#assert.eq(
  scale-fill-stepsn(colours: (rgb("#000"), rgb("#fff"))).aesthetic,
  "fill",
)
#assert.eq(scale-fill-fermenter(palette: "Blues").aesthetic, "fill")

// Binned position scales: still continuous, with binned + n-breaks fields.
#let xb = scale-x-binned(n-breaks: 8)
#assert.eq(xb.kind, "scale")
#assert.eq(xb.aesthetic, "x")
#assert.eq(xb.type, "continuous")
#assert.eq(xb.binned, true)
#assert.eq(xb.n-breaks, 8)

#let yb = scale-y-binned(n-breaks: 4)
#assert.eq(yb.aesthetic, "y")
#assert.eq(yb.type, "continuous")
#assert.eq(yb.binned, true)
#assert.eq(yb.n-breaks, 4)

// Size scales: binned, area, binned-area.
#let sb = scale-size-binned(n-breaks: 4, range: (1pt, 6pt))
#assert.eq(sb.kind, "scale")
#assert.eq(sb.aesthetic, "size")
#assert.eq(sb.type, "continuous")
#assert.eq(sb.binned, true)
#assert.eq(sb.n-breaks, 4)
#assert.eq(sb.range, (1pt, 6pt))

#let sa = scale-size-area(range: (1pt, 12pt))
#assert.eq(sa.aesthetic, "size")
#assert.eq(sa.size-trans, "area")
#assert.eq(sa.range, (1pt, 12pt))

#let sba = scale-size-binned-area(n-breaks: 5)
#assert.eq(sba.binned, true)
#assert.eq(sba.size-trans, "area")
#assert.eq(sba.n-breaks, 5)

// resolve-continuous-colour with binned spec snaps lookups to bin midpoints.
// With 4 bins on (0, 4), values 0.0, 0.5, 1.5, 2.5, 3.5 land in distinct bins
// and cluster at the midpoint of each bin; values within the same bin
// resolve to the same colour.
#let trained-binned = (
  type: "continuous",
  domain: (0.0, 4.0),
  spec: (
    aesthetic: "colour",
    type: "continuous",
    palette: (rgb("#000000"), rgb("#ffffff")),
    binned: true,
    n-breaks: 4,
  ),
)
#let pal-bin = (rgb("#000000"), rgb("#ffffff"))
#let c-low = resolve-continuous-colour(trained-binned, 0.1, pal-bin, black)
#let c-mid-low = resolve-continuous-colour(trained-binned, 0.9, pal-bin, black)
// Both 0.1 and 0.9 sit in the first bin and must resolve to the same colour.
#assert.eq(c-low, c-mid-low)
#let c-high = resolve-continuous-colour(trained-binned, 3.9, pal-bin, black)
// The top bin must differ from the bottom bin.
#assert(c-low != c-high)

// Explicit `breaks` on a binned position scale are bin edges: the wrapper
// stores them and ticks land at the midpoint of each interval.
#let xbe = scale-x-binned(breaks: (2, 4, 6))
#assert.eq(xbe.breaks, (2, 4, 6))

#let trained-edges = (
  type: "continuous",
  domain: (2.0, 6.0),
  spec: (binned: true, breaks: (2, 4, 6), n-breaks: 10),
)
#assert.eq(_axis-breaks(trained-edges), (3.0, 5.0))

// End-to-end: the edge array folds into the domain (Feature 5) so the full
// partition is visible, and ticks sit at the interval midpoints.
#let df-bin = ((x: 1, y: 1), (x: 2, y: 2), (x: 3, y: 3))
#let trained-bin = train(
  scales: (scale-x-binned(breaks: (2, 4, 6)),),
  layers: (geom-point(),),
  mapping: aes(x: "x", y: "y"),
  data: df-bin,
)
#assert.eq(trained-bin.x.domain, (1.0, 6.0))
#assert.eq(_axis-breaks(trained-bin.x), (3.0, 5.0))

Binned scale family tests passed.
