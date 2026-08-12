// Verify `theme(legend-position:)` acts as a global legend-placement default
// that any explicit `guides()` placement overrides. Resolution order, weakest
// to strongest: natural default ("right") < theme(legend-position:) <
// guides(default:) < per-aesthetic guides().

#import "../../src/render/legend.typ": guides-for
#import "../../src/theme/theme.typ": theme
#import "../../src/theme/defaults.typ": merge-theme
#import "../../src/guide/legend.typ": guide-legend

#let layer-point() = (
  name: "point",
  mapping: none,
  inherit-aes: true,
  params: (colour: auto, fill: auto, shape: auto),
)

#let spec(guides) = (
  mapping: (colour: "g", fill: "h"),
  layers: (layer-point(),),
  guides: guides,
)
#let trained = (
  colour: (type: "discrete", domain: ("a", "b")),
  fill: (type: "discrete", domain: ("c", "d")),
)

// 1. theme(legend-position: "bottom") moves an otherwise-default legend below
// the panel, with the direction inferred as horizontal.
#let g1 = guides-for(
  spec((:)),
  trained,
  theme: merge-theme(theme(legend-position: "bottom")),
)
#assert.eq(g1.len(), 2)
#assert.eq(g1.at(0).placement.side, "bottom")
#assert.eq(g1.at(0).placement.direction, "horizontal")
#assert.eq(g1.at(1).placement.side, "bottom")

// 2. No theme leaves the natural default in place.
#let g2 = guides-for(spec((:)), trained)
#assert.eq(g2.at(0).placement.side, "right")
#assert.eq(g2.at(0).placement.direction, "vertical")

// 3. An empty theme (legend-position unset / `auto`) is a no-op.
#let g3 = guides-for(spec((:)), trained, theme: merge-theme(theme()))
#assert.eq(g3.at(0).placement.side, "right")

// 4. guides(default:) overrides the theme value.
#let g4 = guides-for(
  spec((default: guide-legend(position: "top"))),
  trained,
  theme: merge-theme(theme(legend-position: "bottom")),
)
#assert.eq(g4.at(0).placement.side, "top")
#assert.eq(g4.at(1).placement.side, "top")

// 5. A per-aesthetic override beats both theme and default; a sibling aesthetic
// still follows the theme value.
#let g5 = guides-for(
  spec((colour: guide-legend(position: "left"))),
  trained,
  theme: merge-theme(theme(legend-position: "bottom")),
)
#let _by-aes = (:)
#for g in g5 { _by-aes.insert(g.aesthetics.first(), g.placement.side) }
#assert.eq(_by-aes.at("colour"), "left")
#assert.eq(_by-aes.at("fill"), "bottom")

// An invalid theme legend-position (e.g. "middle") panics via
// `_normalise-position`. Typst has no try/catch, so that path is verified
// manually rather than asserted here.

Theme legend-position tests passed.
