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
  assert(h.hoisted-guides.first().trained != none)
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
// guide is built, which is what `compose()` reads to decide there is no legend
// to attach.
#context {
  let h = _hoist-guides((panel(none), nested), (:), auto, none)
  assert.eq(h.hoisted, ())
  assert.eq(h.hoisted-guides, ())
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

// `collect: "all"` hoists a key that only one panel owns, as it is, with the
// trained scales of the panel that owns it. A fill ramp on one panel and a
// colour and shape key on the other land in one block, in panel order.
#let ramp = defer(
  plot,
  data: data,
  mapping: aes(x: "x", y: "y", fill: "y"),
  layers: (geom-point(),),
)(as-spec: true)
#let profile = defer(
  plot,
  data: data,
  mapping: aes(x: "x", y: "y", colour: "g", shape: "g"),
  layers: (geom-point(),),
)(as-spec: true)
#context {
  assert.eq(_hoist-guides((ramp, profile), (:), auto, none).hoisted, ())
  let h = _hoist-guides((ramp, profile), (:), "all", none)
  assert.eq(h.hoisted.sorted(), ("colour", "fill", "shape"))
  assert.eq(h.hoisted-guides.map(g => g.aesthetics), (
    ("fill",),
    ("colour", "shape"),
  ))
  assert("fill" in h.hoisted-guides.at(0).trained)
  assert("colour" in h.hoisted-guides.at(1).trained)
  assert("fill" not in h.hoisted-guides.at(1).trained)
  assert.eq(h.legend-side, "right")
}

// Under `"all"`, a colour key and a colour and shape key do not merge, because
// their aesthetics differ, so both stack. Keys that several panels own and that
// merge are drawn once, and a key the other panels lack still joins the block.
#context {
  let h = _hoist-guides((panel(none), profile), (:), "all", none)
  assert.eq(h.hoisted-guides.map(g => g.aesthetics), (
    ("colour",),
    ("colour", "shape"),
  ))
  let same = _hoist-guides((panel(none), panel(none), ramp), (:), "all", none)
  assert.eq(same.hoisted-guides.map(g => g.aesthetics), (
    ("colour",),
    ("fill",),
  ))
}

// Under `"all"`, keys that several panels own but that cannot merge are stacked
// in panel order, and each keeps the trained scale of its own panel.
#context {
  let other = defer(
    plot,
    data: (x: (1, 2), y: (1, 2), g: ("p", "q")),
    mapping: aes(x: "x", y: "y", colour: "g"),
    layers: (geom-point(),),
  )(as-spec: true)
  let h = _hoist-guides((panel(none), other), (:), "all", none)
  assert.eq(h.hoisted, ("colour",))
  assert.eq(h.hoisted-guides.map(g => g.levels), (("a", "b", "c"), ("p", "q")))
  assert.ne(
    h.hoisted-guides.at(0).trained.colour,
    h.hoisted-guides.at(1).trained.colour,
  )
}

// Under `"all"`, a nested compose panel owns no key, so the plot panels beside
// it still hoist theirs.
#context {
  let h = _hoist-guides((panel(none), nested), (:), "all", none)
  assert.eq(h.hoisted, ("colour",))
  assert.eq(h.hoisted-guides.len(), 1)
}

// The shared block follows the guide order of the panel, not the order of the
// names in a `collect` array.
#context {
  let sized = defer(
    plot,
    data: data,
    mapping: aes(x: "x", y: "y", colour: "g", size: "y"),
    layers: (geom-point(),),
  )(as-spec: true)
  let h = _hoist-guides((sized, sized), (:), ("size", "colour"), none)
  assert.eq(h.hoisted-guides.map(g => g.aesthetics), (("colour",), ("size",)))
}

Compose guide hoisting tests passed.
