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

// Constants come whole from one layer. A highlight layer that pins a shape
// does not turn the keys of the main layer into triangles.
#context {
  let g = guides-for(
    (
      mapping: (colour: "g"),
      layers: (
        geom-point(size: 3pt),
        geom-point(size: 3pt, shape: "triangle"),
      ),
      guides: (:),
    ),
    (colour: discrete("a", "b")),
  )
  assert.eq(g.at(0).key-consts.size, 3pt)
  assert("shape" not in g.at(0).key-consts)
}

// A layer that pins `size` does not set the size of the NA key of a merged
// colour and size group. The layer that maps size supplies the constants.
#context {
  let g = guides-for(
    (
      mapping: (colour: "g", size: "g"),
      layers: (
        geom-point(size: 5pt, shape: "square", alpha: 0.3),
        geom-point(),
      ),
      guides: (:),
    ),
    (
      colour: discrete("a", "b"),
      size: discrete("a", "b"),
    ),
  )
  assert.eq(g.at(0).aesthetics, ("colour", "size"))
  assert.eq(g.at(0).key-consts.size, 1.5pt)
  assert("shape" not in g.at(0).key-consts)
  assert("alpha" not in g.at(0).key-consts)
}

// The key box grows with a pinned marker size, so large keys do not overlap.
#context {
  let g = guides-for(
    (
      mapping: (colour: "g"),
      layers: (geom-point(size: 8pt),),
      guides: (:),
    ),
    (colour: discrete("a", "b")),
  )
  assert(g.at(0).key-diam-cm >= 0.56)
}
