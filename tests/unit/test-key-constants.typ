// A legend key draws with the constants of the layer behind it: the values the
// mark itself uses when no scale supplies them.

#import "../../src/geom/point.typ": geom-point
#import "../../src/geom/line.typ": geom-line
#import "../../src/geom/pointrange.typ": geom-pointrange
#import "../../src/guide/key-constants.typ": key-constants
#import "../../src/theme/defaults.typ": default-theme, merge-theme
#import "../../src/theme/grey.typ": theme-grey
#import "../../src/theme/theme.typ": resolve-geom-defaults

#let defaults = resolve-geom-defaults(merge-theme(theme-grey()))

// A pinned shape stays, a mapped colour leaves no fill, and size and stroke
// fall back to the point mark's own defaults.
#let c1 = key-constants(
  geom-point(shape: "triangle"),
  (colour: "g"),
  defaults,
  "point",
)
#assert.eq(c1.shape, "triangle")
#assert.eq(c1.size, 1.5pt)
#assert.eq(c1.colour, defaults.ink)
#assert("fill" not in c1)

// Nothing mapped for colour or fill: paper fill with an ink outline.
#let c2 = key-constants(
  geom-point(size: 3pt),
  (shape: "g"),
  defaults,
  "point",
)
#assert.eq(c2.size, 3pt)
#assert.eq(c2.colour, defaults.ink)
#assert.eq(c2.fill, defaults.paper)

// Alpha counts only when pinned.
#assert.eq(
  key-constants(geom-point(alpha: 0.4), (shape: "g"), defaults, "point").alpha,
  0.4,
)
#assert(
  "alpha"
    not in key-constants(
      geom-point(),
      (shape: "g"),
      defaults,
      "point",
    ),
)

// A pinned colour replaces the default and drops the paper fill.
#let c3 = key-constants(
  geom-point(colour: red),
  (shape: "g"),
  defaults,
  "point",
)
#assert.eq(c3.colour, red)
#assert("fill" not in c3)

// Line: pinned linetype and stroke thickness, geom default otherwise.
#let c4 = key-constants(
  geom-line(linetype: "dashed"),
  (colour: "g"),
  defaults,
  "line",
)
#assert.eq(c4.linetype, "dashed")
#assert.eq(c4.linewidth, 0.8pt)
#assert.eq(
  key-constants(geom-line(stroke: 2pt), none, defaults, "line").linewidth,
  2pt,
)

// Other key kinds carry no constants.
#assert.eq(key-constants(geom-point(), none, defaults, "rect"), (:))

// A fill that another guide maps is not painted paper: the key for this guide
// takes a neutral ink fill and no outline, as the mark with a mapped fill has.
#let c5 = key-constants(
  geom-point(),
  (fill: "g", size: "w"),
  defaults,
  "point",
)
#assert.eq(c5.neutral-fill, defaults.ink)
#assert("fill" not in c5)
#assert("colour" not in c5)

// With both mapped, the neutral key is solid ink.
#let c6 = key-constants(
  geom-point(),
  (fill: "g", colour: "g", size: "w"),
  defaults,
  "point",
)
#assert.eq(c6.neutral-fill, defaults.ink)

// Pointrange paints its point solid in the colour, with no outline.
#let c7 = key-constants(
  geom-pointrange(),
  (colour: "g"),
  defaults,
  "point",
)
#assert.eq(c7.size, 2.5pt)
#assert(c7.solid)
#assert("stroke" not in c7)
