// Guide hoisting: the per-panel probes decide which aesthetics hoist, and the
// shared guide is built under the composition's theme, since that is the theme
// it is drawn under. A panel theme styles its own panel alone.

#import "../../src/compose.typ": _hoist-guides, compose, defer
#import "../../src/render/legend.typ": can-merge-cross-panel
#import "../../src/plot.typ": plot
#import "../../src/aes.typ": aes
#import "../../src/geom/point.typ": geom-point
#import "../../lib.typ": guide-legend, guides, theme

#set page(width: auto, height: auto, margin: 0cm)

#let data = (x: (1, 2, 3), y: (2, 3, 1), g: ("a", "b", "c"))
#let small = theme(legend-key: 0.2cm)
#let big = theme(legend-key: 0.6cm)

#let panel(panel-theme, panel-guides: (:)) = defer(
  plot,
  data: data,
  mapping: aes(x: "x", y: "y", colour: "g"),
  layers: (geom-point(),),
  theme: panel-theme,
  guides: panel-guides,
)(as-spec: true)

#let nested = compose(
  defer(plot, data: data, layers: (geom-point(),), mapping: aes(
    x: "x",
    y: "y",
  )),
  as-spec: true,
)

// The key glyph follows the composition, not the panels. `_resolve-compose-theme`
// leaves a themed panel alone, so both panels here keep `small` while the
// composition draws under `big`.
#context {
  let h = _hoist-guides((panel(small), panel(small)), (:), auto, big)
  assert.eq(h.hoisted, ("colour",))
  assert.eq(h.hoisted-guides.len(), 1)
  assert.eq(h.hoisted-guides.first().key-diam-cm, 0.6)
  assert(h.trained != none)
}

// A `key-size` override comes from the spec, not the theme, so building the
// guide again under the composition keeps it.
#context {
  let over = guides(colour: guide-legend(key-size: 0.5cm))
  let p = panel(small, panel-guides: over)
  let h = _hoist-guides((p, p), (:), auto, big)
  assert.eq(h.hoisted-guides.first().key-diam-cm, 0.5)
}

// Compose-level `guides` shape the hoisted legend the same way a panel's own do.
#context {
  let h = _hoist-guides(
    (panel(small), panel(small)),
    guides(colour: guide-legend(key-size: 0.5cm)),
    auto,
    big,
  )
  assert.eq(h.hoisted-guides.first().key-diam-cm, 0.5)
}

// Panels that already draw under the composition's theme take the probe they
// were given, and land on the same guide as the build-again path.
#context {
  let reused = _hoist-guides((panel(small), panel(small)), (:), auto, small)
  let derived = _hoist-guides((panel(big), panel(big)), (:), auto, small)
  assert.eq(reused.hoisted-guides.first().key-diam-cm, 0.2)
  assert.eq(reused.hoisted-guides, derived.hoisted-guides)
}

// The side follows the composition theme, not a panel's.
#context {
  let side = theme(legend-position: "bottom")
  let h = _hoist-guides((panel(none), panel(none)), (:), auto, side)
  assert.eq(h.legend-side, "bottom")
  assert.eq(
    _hoist-guides((panel(side), panel(side)), (:), auto, none).legend-side,
    "right",
  )
}

// A composition theme that hides the legend keeps the aesthetic hoisted, so the
// panels go on suppressing it, and draws nothing for it.
#context {
  let h = _hoist-guides(
    (panel(none), panel(none)),
    (:),
    auto,
    theme(legend-position: "none"),
  )
  assert.eq(h.hoisted, ("colour",))
  assert.eq(h.hoisted-guides, ())
}

// A nested compose panel carries no guides of its own, so nothing hoists and no
// guide is built. `trained` is `none`, which is what `compose()` reads to decide
// there is no legend to attach.
#context {
  let h = _hoist-guides((panel(none), nested), (:), auto, none)
  assert.eq(h.hoisted, ())
  assert.eq(h.hoisted-guides, ())
  assert.eq(h.trained, none)
}

// `collect` selects the aesthetics: `none` hoists nothing, an explicit list
// hoists what it names, and a name no panel carries is inert.
#context {
  let panels = (panel(none), panel(none))
  assert.eq(_hoist-guides(panels, (:), none, none).hoisted, ())
  assert.eq(_hoist-guides(panels, (:), ("colour",), none).hoisted, ("colour",))
  assert.eq(_hoist-guides(panels, (:), ("size",), none).hoisted, ())
}

// `can-merge-cross-panel` compares what a legend says, not how it is styled.
// Panels that disagree on the styling still merge, and the composition's theme
// settles it. Widening this to the styling fields would refuse to hoist instead.
#let swatch = (
  kind: "swatch",
  title: "grp",
  align: none,
  aesthetics: ("colour",),
  levels: ("a", "b"),
  labels: ("a", "b"),
  key-diam-cm: 0.24,
  nrow: none,
  ncolumn: none,
  placement: (side: "right"),
)
#assert(can-merge-cross-panel(swatch, swatch))
#assert(can-merge-cross-panel(swatch, swatch + (key-diam-cm: 0.9)))
#assert(can-merge-cross-panel(swatch, swatch + (nrow: 2, ncolumn: 3)))
#assert(can-merge-cross-panel(swatch, swatch + (placement: (side: "left"))))
#assert(not can-merge-cross-panel(swatch, swatch + (title: "other")))
#assert(not can-merge-cross-panel(swatch, swatch + (align: left)))
#assert(not can-merge-cross-panel(swatch, swatch + (aesthetics: ("fill",))))
#assert(not can-merge-cross-panel(swatch, swatch + (levels: ("a",))))
#assert(not can-merge-cross-panel(swatch, swatch + (labels: ("a", "c"))))
#assert(
  not can-merge-cross-panel(
    swatch + (kind: "custom"),
    swatch + (kind: "custom"),
  ),
)

Compose guide hoisting tests passed.
