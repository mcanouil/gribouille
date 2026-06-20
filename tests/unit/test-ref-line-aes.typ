// Reference-line geoms wire their intercept channels through `aes()`. A mapped
// `xintercept`/`yintercept` feeds the x/y domain (so data-driven lines stay in
// view) and a mapped `colour` trains the colour scale, while the scalar/array
// parameter path leaves the domains untouched.

#import "../../src/scale/train.typ": train
#import "../../src/render/layer-prep.typ": _prepare-layer
#import "../../src/geom/point.typ": geom-point
#import "../../src/geom/vline.typ": geom-vline
#import "../../src/geom/hline.typ": geom-hline
#import "../../src/aes.typ": aes

#let raw = range(0, 6).map(i => (x: i, y: i))

// --- Mapped xintercept extends the x domain past the plot data ---
#let events = ((at: 10, grp: "a"), (at: 20, grp: "b"))
#let layers = (
  geom-point(),
  geom-vline(mapping: aes(xintercept: "at", colour: "grp"), data: events),
)
#let prepared = layers.map(l => _prepare-layer(l, aes(x: "x", y: "y"), raw))
#let trained = train(
  layers: prepared,
  mapping: aes(x: "x", y: "y"),
  data: raw,
)
#assert.eq(trained.x.type, "continuous")
#assert(trained.x.domain.at(1) >= 20.0 - 1e-9)

// The mapped colour column trains a discrete colour scale over its levels.
#assert(trained.at("colour", default: none) != none)
#assert(trained.colour.domain.contains("a"))
#assert(trained.colour.domain.contains("b"))

// --- Mapped yintercept extends the y domain past the plot data ---
#let bands = ((lo: 15), (lo: 30))
#let layers-h = (
  geom-point(),
  geom-hline(mapping: aes(yintercept: "lo"), data: bands),
)
#let prepared-h = layers-h.map(l => _prepare-layer(l, aes(x: "x", y: "y"), raw))
#let trained-h = train(
  layers: prepared-h,
  mapping: aes(x: "x", y: "y"),
  data: raw,
)
#assert(trained-h.y.domain.at(1) >= 30.0 - 1e-9)

// --- Parameter-only intercept leaves the domain at the plot data ---
#let layers-p = (geom-point(), geom-vline(xintercept: 100))
#let prepared-p = layers-p.map(l => _prepare-layer(l, aes(x: "x", y: "y"), raw))
#let trained-p = train(
  layers: prepared-p,
  mapping: aes(x: "x", y: "y"),
  data: raw,
)
#assert(trained-p.x.domain.at(1) <= 5.0 + 1e-9)

// --- Draw path: ISO date-string intercepts under a temporal scale render
// without panicking. Covers the mapped channel, the scalar parameter, an
// annotate("vline") param, and an unparseable value (silently dropped). ---
#import "../../lib.typ": annotate, plot, scale-x-date

#let date-data = (
  (d: "2024-01-01", v: 1),
  (d: "2024-02-01", v: 3),
  (d: "2024-03-01", v: 2),
)
#plot(
  data: date-data,
  mapping: aes(x: "d", y: "v"),
  layers: (
    geom-point(),
    geom-vline(data: (("at": "2024-02-15"),), mapping: aes(xintercept: "at")),
    geom-vline(xintercept: "2024-01-20"),
    geom-vline(xintercept: "not-a-date"),
    annotate("vline", xintercept: "2024-03-01"),
  ),
  scales: (scale-x-date(),),
  width: 8cm,
  height: 5cm,
)

Reference-line aes tests passed.
