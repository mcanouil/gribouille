// A merged legend carries the key constants of the layers behind its glyph,
// and a mapped aesthetic wins over a constant of the same name.

#import "../../src/geom/point.typ": geom-point
#import "../../src/geom/line.typ": geom-line
#import "../../src/guide/draw-key.typ": draw-key-line
#import "../../src/render/legend.typ": _bundle-for, guides-for

#let discrete(..levels) = (type: "discrete", domain: levels.pos())

// A pinned shape reaches the guide of a mapped colour.
#context {
  let g = guides-for(
    (
      mapping: (colour: "g"),
      layers: (geom-point(shape: "triangle"),),
      guides: (:),
    ),
    (colour: discrete("a", "b")),
  )
  assert.eq(g.at(0).key, "point")
  assert.eq(g.at(0).key-consts.shape, "triangle")
}

// The key kind picks the contributing layers: a point and a dashed line
// merge into a line key that holds the line constants and no shape.
#context {
  let g = guides-for(
    (
      mapping: (colour: "g", linetype: "g"),
      layers: (geom-point(shape: "triangle"), geom-line(linetype: "dashed")),
      guides: (:),
    ),
    (colour: discrete("a", "b"), linetype: discrete("a", "b")),
  )
  assert.eq(g.at(0).key, "line")
  assert.eq(g.at(0).key-consts.linetype, "dashed")
  assert("shape" not in g.at(0).key-consts)
}

// A key override moves the layer to another kind, so no point constants apply.
#context {
  let g = guides-for(
    (
      mapping: (colour: "g"),
      layers: (geom-point(shape: "triangle", key: draw-key-line()),),
      guides: (:),
    ),
    (colour: discrete("a", "b")),
  )
  assert.eq(g.at(0).key, "line")
  assert("shape" not in g.at(0).key-consts)
  assert("size" not in g.at(0).key-consts)
}

// A scale value overwrites the constant of the same aesthetic.
#let ctx = (
  trained: (shape: (type: "discrete", domain: ("a", "b"))),
  palette: none,
)
#let bundle = _bundle-for(
  "b",
  ("shape",),
  ctx,
  black,
  (shape: "triangle", size: 4pt),
)
#assert.eq(bundle.size, 4pt)
#assert.ne(bundle.shape, "triangle")
