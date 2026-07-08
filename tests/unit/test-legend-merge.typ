// Verify legend merging when the same column drives multiple aesthetics.
// Two trained scales merge into a single guide iff column, type, domain,
// labels, title, and grid options all match. Key glyph precedence is
// aesthetic-driven (shape > linetype/linewidth > size > geom fallback).

#import "../../src/render/legend.typ": guides-for

#let layer-point(colour: auto, fill: auto, shape: auto) = (
  name: "point",
  mapping: none,
  inherit-aes: true,
  params: (colour: colour, fill: fill, shape: shape),
)

#let layer-line(colour: auto, linetype: auto, linewidth: auto) = (
  name: "line",
  mapping: none,
  inherit-aes: true,
  params: (colour: colour, linetype: linetype, linewidth: linewidth),
)

// 1. colour + shape on the same column collapse into one swatch with a
// `point` glyph (Pass-A: shape forces base = "point").
#let g1 = guides-for(
  (
    mapping: (colour: "g", shape: "g"),
    layers: (layer-point(),),
    guides: (:),
  ),
  (
    colour: (type: "discrete", domain: ("a", "b")),
    shape: (type: "discrete", domain: ("a", "b")),
  ),
)
#assert.eq(g1.len(), 1)
#assert.eq(g1.at(0).aesthetics, ("colour", "shape"))
#assert.eq(g1.at(0).key, "point")
#assert.eq(g1.at(0).levels, ("a", "b"))

// 2. colour + linetype on the same column on a line geom: Pass-A picks
// "line" because linetype is in the group and no path override is set.
#let g2 = guides-for(
  (
    mapping: (colour: "g", linetype: "g"),
    layers: (layer-line(),),
    guides: (:),
  ),
  (
    colour: (type: "discrete", domain: ("a", "b")),
    linetype: (type: "discrete", domain: ("a", "b")),
  ),
)
#assert.eq(g2.len(), 1)
#assert.eq(g2.at(0).aesthetics, ("colour", "linetype"))
#assert.eq(g2.at(0).key, "line")

// 3. Divergent titles split: colour gets a user title that differs from the
// one fill would inherit, so the two stay as separate guides.
#let g3 = guides-for(
  (
    mapping: (colour: "g", fill: "g"),
    layers: (layer-point(),),
    guides: (
      colour: (
        kind: "guide",
        suppress: false,
        title: "Group A",
        nrow: none,
        ncol: none,
        reverse: false,
      ),
    ),
  ),
  (
    colour: (type: "discrete", domain: ("a", "b")),
    fill: (type: "discrete", domain: ("a", "b")),
  ),
)
#assert.eq(g3.len(), 2)
#assert.eq(g3.at(0).aesthetics, ("colour",))
#assert.eq(g3.at(0).title, "Group A")
#assert.eq(g3.at(1).aesthetics, ("fill",))
#assert.eq(g3.at(1).title, "g")

// 4. Different columns don't merge even when domains coincide.
#let g4 = guides-for(
  (
    mapping: (colour: "g", shape: "h"),
    layers: (layer-point(),),
    guides: (:),
  ),
  (
    colour: (type: "discrete", domain: ("a", "b")),
    shape: (type: "discrete", domain: ("a", "b")),
  ),
)
#assert.eq(g4.len(), 2)
#assert.eq(g4.at(0).aesthetics, ("colour",))
#assert.eq(g4.at(1).aesthetics, ("shape",))

// 5. Continuous size-only aesthetic produces a size-ladder, not a colourbar.
#let g5 = guides-for(
  (
    mapping: (size: "w"),
    layers: (layer-point(),),
    guides: (:),
  ),
  (
    size: (
      type: "continuous",
      domain: (1.0, 5.0),
      spec: (range: (2pt, 8pt)),
    ),
  ),
)
#assert.eq(g5.len(), 1)
#assert.eq(g5.at(0).kind, "size-ladder")
#assert.eq(g5.at(0).aesthetics, ("size",))
#assert.eq(g5.at(0).key, "point")

// 6. shape mapped on a non-point geom does not contribute (geom doesn't
// consume shape), so no shape guide is emitted.
#let g6 = guides-for(
  (
    mapping: (colour: "g", shape: "g"),
    layers: (layer-line(),),
    guides: (:),
  ),
  (
    colour: (type: "discrete", domain: ("a", "b")),
    shape: (type: "discrete", domain: ("a", "b")),
  ),
)
#assert.eq(g6.len(), 1)
#assert.eq(g6.at(0).aesthetics, ("colour",))
#assert.eq(g6.at(0).key, "line")

// 7. shape + size on the same point geom: Pass-A still resolves to "point".
#let g7 = guides-for(
  (
    mapping: (shape: "g", size: "g"),
    layers: (layer-point(),),
    guides: (:),
  ),
  (
    shape: (type: "discrete", domain: ("a", "b")),
    size: (type: "discrete", domain: ("a", "b")),
  ),
)
#assert.eq(g7.len(), 1)
#assert.eq(g7.at(0).aesthetics, ("size", "shape"))
#assert.eq(g7.at(0).key, "point")

// 8. linetype on a line geom alone produces a single-aesthetic swatch with
// "line" key.
#let g8 = guides-for(
  (
    mapping: (linetype: "g"),
    layers: (layer-line(),),
    guides: (:),
  ),
  (linetype: (type: "discrete", domain: ("a", "b"))),
)
#assert.eq(g8.len(), 1)
#assert.eq(g8.at(0).aesthetics, ("linetype",))
#assert.eq(g8.at(0).key, "line")

#let _placement(side, direction, order: none) = (
  side: side,
  align: none,
  dx: 0pt,
  dy: 0pt,
  direction: direction,
  order: order,
  byrow: false,
)
#let _top-placement = _placement("top", "horizontal")

// 9. Divergent placement splits: colour wants "top", fill defaults to "right",
// so the two stay as separate guides even when the column matches.
#let g9 = guides-for(
  (
    mapping: (colour: "g", fill: "g"),
    layers: (layer-point(),),
    guides: (
      colour: (
        kind: "guide",
        suppress: false,
        title: none,
        nrow: none,
        ncol: none,
        reverse: false,
        placement: _top-placement,
      ),
    ),
  ),
  (
    colour: (type: "discrete", domain: ("a", "b")),
    fill: (type: "discrete", domain: ("a", "b")),
  ),
)
#assert.eq(g9.len(), 2)
#assert.eq(g9.at(0).aesthetics, ("colour",))
#assert.eq(g9.at(0).placement.side, "top")
#assert.eq(g9.at(1).aesthetics, ("fill",))
#assert.eq(g9.at(1).placement.side, "right")

// 10. Matching placement on both overrides lets the merge proceed.
#let g10 = guides-for(
  (
    mapping: (colour: "g", fill: "g"),
    layers: (layer-point(),),
    guides: (
      colour: (
        kind: "guide",
        suppress: false,
        title: none,
        nrow: none,
        ncol: none,
        reverse: false,
        placement: _top-placement,
      ),
      fill: (
        kind: "guide",
        suppress: false,
        title: none,
        nrow: none,
        ncol: none,
        reverse: false,
        placement: _top-placement,
      ),
    ),
  ),
  (
    colour: (type: "discrete", domain: ("a", "b")),
    fill: (type: "discrete", domain: ("a", "b")),
  ),
)
#assert.eq(g10.len(), 1)
#assert.eq(g10.at(0).aesthetics, ("colour", "fill"))
#assert.eq(g10.at(0).placement.side, "top")

// 11. `position: "none"` suppresses the guide entirely.
#let _none-placement = _placement("none", "vertical")
#let g11 = guides-for(
  (
    mapping: (colour: "g", fill: "h"),
    layers: (layer-point(),),
    guides: (
      colour: (
        kind: "guide",
        suppress: false,
        title: none,
        nrow: none,
        ncol: none,
        reverse: false,
        placement: _none-placement,
      ),
    ),
  ),
  (
    colour: (type: "discrete", domain: ("a", "b")),
    fill: (type: "discrete", domain: ("a", "b")),
  ),
)
#assert.eq(g11.len(), 1)
#assert.eq(g11.at(0).aesthetics, ("fill",))

// 12. Explicit `order` swaps the default aesthetic order: size's order: 1
// beats colour's order: 5, so size emits first even though colour would
// naturally lead.
#let g12 = guides-for(
  (
    mapping: (colour: "g", size: "w"),
    layers: (layer-point(),),
    guides: (
      colour: (
        kind: "guide",
        suppress: false,
        title: none,
        nrow: none,
        ncol: none,
        reverse: false,
        placement: _placement("right", "vertical", order: 5),
      ),
      size: (
        kind: "guide",
        suppress: false,
        title: none,
        nrow: none,
        ncol: none,
        reverse: false,
        placement: _placement("right", "vertical", order: 1),
      ),
    ),
  ),
  (
    colour: (type: "discrete", domain: ("a", "b")),
    size: (type: "continuous", domain: (1.0, 5.0), spec: (range: (2pt, 8pt))),
  ),
)
#assert.eq(g12.len(), 2)
#assert.eq(g12.at(0).aesthetics, ("size",))
#assert.eq(g12.at(1).aesthetics, ("colour",))

Legend-merge tests passed.
