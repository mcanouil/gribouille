// element-geom() carries layer-default aesthetics consumed by supporting
// geoms via theme.geom. Default-theme should expose an empty record.

#import "../../src/theme/elements.typ": element-geom
#import "../../src/theme/defaults.typ": default-theme, merge-theme
#import "../../src/theme/theme.typ": (
  fill-tint-amount, resolve-geom-colour, resolve-geom-defaults,
  resolve-geom-fill, theme,
)
#import "../../src/utils/colour.typ": colour-mix

#let g = element-geom()
#assert.eq(g.kind, "element-geom")
#assert.eq(g.fill, none)
#assert.eq(g.colour, none)
#assert.eq(g.linewidth, none)
#assert.eq(g.font, none)

#let g2 = element-geom(fill: red, colour: blue, linewidth: 1pt, font: "Font A")
#assert.eq(g2.fill, red)
#assert.eq(g2.colour, blue)
#assert.eq(g2.linewidth, 1pt)
#assert.eq(g2.font, "Font A")

// default-theme carries an empty element-geom under `geom`.
#assert.eq(default-theme.geom.kind, "element-geom")
#assert.eq(default-theme.geom.fill, none)

// theme(geom: ...) merges through merge-theme cleanly.
#let t = merge-theme(theme(geom: element-geom(fill: rgb("#cc3333"))))
#assert.eq(t.geom.fill, rgb("#cc3333"))

// resolve-geom-defaults picks the resolved record off the merged theme.
#let d = resolve-geom-defaults(t)
#assert.eq(d.kind, "element-geom")
#assert.eq(d.fill, rgb("#cc3333"))

// resolve-geom-defaults on a theme without a `geom` slot returns an all-none record.
#let stripped = (kind: "theme", name: "x")
#let dd = resolve-geom-defaults(stripped)
#assert.eq(dd.kind, "element-geom")
#assert.eq(dd.fill, none)

// Role helpers + default resolvers.

// Empty element-geom + bare default-theme: roles inherit theme scalars.
#let d0 = resolve-geom-defaults(default-theme)
#assert.eq(d0.ink, default-theme.ink)
#assert.eq(d0.paper, default-theme.paper)
#assert.eq(d0.accent, default-theme.accent)
#assert.eq(resolve-geom-colour(d0), default-theme.ink)
#assert.eq(resolve-geom-colour(d0, role: "accent"), default-theme.accent)
#assert.eq(
  resolve-geom-fill(d0, role: "tint"),
  colour-mix(default-theme.ink, default-theme.paper, fill-tint-amount),
)
#assert.eq(resolve-geom-fill(d0, role: "paper"), default-theme.paper)
#assert.eq(resolve-geom-fill(d0, role: "ink"), default-theme.ink)

// Theme with no geom slot and no scalars: hard fallbacks black/white/#3366FF.
#let de = resolve-geom-defaults(stripped)
#assert.eq(de.ink, black)
#assert.eq(de.paper, white)
#assert.eq(de.accent, rgb("#3366FF"))
#assert.eq(resolve-geom-colour(de), black)
#assert.eq(
  resolve-geom-fill(de, role: "tint"),
  colour-mix(black, white, fill-tint-amount),
)

// element-geom(ink: X): colour-default == X; the tint uses X as its dark stop.
#let di = resolve-geom-defaults(
  merge-theme(theme(geom: element-geom(ink: rgb("#112233")))),
)
#assert.eq(resolve-geom-colour(di), rgb("#112233"))
#assert.eq(
  resolve-geom-fill(di, role: "tint"),
  colour-mix(rgb("#112233"), default-theme.paper, fill-tint-amount),
)

// element-geom(paper: X): paper-role fill == X; tint uses X as its light stop.
#let dp = resolve-geom-defaults(
  merge-theme(theme(geom: element-geom(paper: rgb("#445566")))),
)
#assert.eq(resolve-geom-fill(dp, role: "paper"), rgb("#445566"))
#assert.eq(
  resolve-geom-fill(dp, role: "tint"),
  colour-mix(default-theme.ink, rgb("#445566"), fill-tint-amount),
)

// element-geom(colour: X): global override; wins over every colour role.
#let dc = resolve-geom-defaults(
  merge-theme(theme(geom: element-geom(colour: rgb("#778899")))),
)
#assert.eq(resolve-geom-colour(dc), rgb("#778899"))
#assert.eq(resolve-geom-colour(dc, role: "accent"), rgb("#778899"))

// element-geom(fill: X): global override; wins over every fill role.
#let df = resolve-geom-defaults(
  merge-theme(theme(geom: element-geom(fill: rgb("#aabbcc")))),
)
#assert.eq(resolve-geom-fill(df, role: "tint"), rgb("#aabbcc"))
#assert.eq(resolve-geom-fill(df, role: "paper"), rgb("#aabbcc"))
#assert.eq(resolve-geom-fill(df, role: "ink"), rgb("#aabbcc"))

// element-geom(accent: X): accent-role colour == X; ink role unaffected.
#let da = resolve-geom-defaults(
  merge-theme(theme(geom: element-geom(accent: rgb("#abcdef")))),
)
#assert.eq(resolve-geom-colour(da, role: "accent"), rgb("#abcdef"))
#assert.eq(resolve-geom-colour(da), default-theme.ink)

// role: none skips the role fallback (fill-only geoms): empty element-geom
// returns none; element-geom(colour: X) still wins.
#assert.eq(resolve-geom-colour(d0, role: none), none)
#assert.eq(resolve-geom-colour(dc, role: none), rgb("#778899"))

Element-geom tests passed.
