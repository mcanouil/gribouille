// `from-theme(path)` is a late-binding marker that resolves to a literal
// scalar at layer-prepare time. The marker survives `aes()` round-trip,
// dotted and array paths read the same theme entry, and `_prepare-layer`
// removes the marker from the mapping while writing the resolved scalar
// onto `layer.params.<channel>`.

#import "../../src/utils/late-binding.typ": (
  from-theme, is-late-binding, late-binding-kind, late-binding-name,
  resolve-from-theme,
)
#import "../../src/aes.typ": aes
#import "../../src/render/layer-prep.typ": _apply-from-theme, _prepare-layer
#import "../../src/theme/defaults.typ": merge-theme
#import "../../src/theme/grey.typ": theme-grey
#import "../../src/geom/point.typ": geom-point

// --- constructor + predicates -------------------------------------------

#let m = from-theme("ink")
#assert.eq(m.kind, "from-theme")
#assert.eq(m.path, "ink")
#assert(is-late-binding(m))
#assert.eq(late-binding-kind(m), "from-theme")
#assert(not is-late-binding("ink"))
#assert.eq(late-binding-kind("ink"), none)
#assert.eq(late-binding-name(from-theme("ink")), none)

// --- aes() round-trip ---------------------------------------------------

#let a = aes(x: "x", y: "y", colour: from-theme("ink"))
#assert.eq(a.colour.kind, "from-theme")
#assert.eq(a.colour.path, "ink")

// --- resolve-from-theme: dotted and array paths ------------------------

#let theme = merge-theme(theme-grey())
#assert.eq(resolve-from-theme(theme, "ink"), theme.ink)
#assert.eq(resolve-from-theme(theme, ("ink",)), theme.ink)
#assert.eq(
  resolve-from-theme(theme, "panel-grid.colour"),
  theme.panel-grid.colour,
)
#assert.eq(
  resolve-from-theme(theme, ("panel-grid", "colour")),
  theme.panel-grid.colour,
)

// --- _apply-from-theme: marker collapses to layer.params override ------

#let layer = geom-point(mapping: aes(colour: from-theme("ink")), size: 2pt)
#let merged-mapping = (x: "x", y: "y", colour: from-theme("ink"))
#let applied = _apply-from-theme(layer, merged-mapping, theme)
#assert.eq(applied.layer.params.colour, theme.ink)
#assert.eq(applied.mapping.colour, none)
#assert.eq(applied.mapping.x, "x")
#assert.eq(applied.mapping.y, "y")

// --- _prepare-layer: end-to-end with a theme-aware layer ---------------

#let data = ((x: 1, y: 2), (x: 2, y: 3))
#let prepared = _prepare-layer(
  layer,
  aes(x: "x", y: "y"),
  data,
  theme: theme,
)
#assert.eq(prepared.params.colour, theme.ink)
#assert.eq(prepared.mapping.colour, none)
#assert.eq(prepared.mapping.x, "x")

late-binding from-theme tests passed.
