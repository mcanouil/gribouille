// A merged legend carries the key constants of the layers behind its glyph,
// and a mapped aesthetic wins over a constant of the same name.

#import "../../src/geom/point.typ": geom-point
#import "../../src/geom/line.typ": geom-line
#import "../../src/guide/draw-key.typ": draw-key-line
#import "../../src/render/legend.typ": _bundle-for, _key-bundle, guides-for
#import "../../src/render/colour.typ": _make-resolve-colour
#import "../../src/utils/late-binding.typ": after-scale, stage
#import "../../src/theme/defaults.typ": default-theme
#import "../../src/theme/theme.typ": resolve-theme-palette

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

// A layer that pins `size` does not set the size of the missing key of a merged
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

// A `solid` constant paints the key with the colour, as a pointrange does.
#{
  let ctx = (
    trained: (colour: (type: "discrete", domain: ("a", "b"))),
    palette: resolve-theme-palette(default-theme),
  )
  let guide = (
    aesthetics: ("colour",),
    columns: (colour: "g"),
    key-consts: (size: 2.5pt, solid: true),
    key-late: (:),
  )
  let bundle = _key-bundle("a", guide, ctx, black)
  assert.eq(bundle.size, 2.5pt)
  assert.eq(type(bundle.fill), color)
  assert("colour" not in bundle)
}

// An `after-scale` or `stage` colour on the layer reaches the key: the closure
// runs on the level of the guide, as it does on a row of the mark.
#let late-ctx = {
  let palette = resolve-theme-palette(default-theme)
  (
    trained: (fill: (type: "discrete", domain: ("a", "b"))),
    palette: palette,
    resolve-colour: _make-resolve-colour(black),
    theme: default-theme,
  )
}
#let darken-fill = (_, ctx) => {
  let trained = ctx.trained.at("fill")
  ((ctx.resolve-colour)(trained, ctx.palette))(ctx.row.g).darken(40%)
}
#for marker in (
  after-scale(darken-fill),
  stage(start: "g", after-scale: darken-fill),
) {
  context {
    let guide = guides-for(
      (
        mapping: (fill: "g", colour: marker),
        layers: (geom-point(),),
        guides: (:),
      ),
      (fill: discrete("a", "b")),
    ).at(0)
    let bundle = _key-bundle("a", guide, late-ctx, black)
    let fill = (
      (late-ctx.resolve-colour)(
        late-ctx.trained.fill,
        late-ctx.palette,
      )
    )("a")
    assert.eq(bundle.fill, fill)
    assert.eq(bundle.colour, fill.darken(40%))
  }
}

// A guide for the outline colour draws a ring: no neutral fill. A guide for
// another aesthetic, such as a size ladder, draws the neutral ink fill.
#{
  let ctx = (
    trained: (colour: (type: "discrete", domain: ("a", "b"))),
    palette: resolve-theme-palette(default-theme),
  )
  let consts = (colour: black, neutral-fill: black, size: 3pt)
  let colour-guide = (
    aesthetics: ("colour",),
    columns: (colour: "g"),
    key-consts: consts,
  )
  let ladder = (aesthetics: ("size",), columns: (:), key-consts: consts)
  assert("fill" not in _key-bundle("a", colour-guide, ctx, black))
  assert.eq(_key-bundle("a", ladder, ctx, black).fill, black)
}

// A stage closure of a colour scale trained on the column of the guide takes
// the colour of the level as input, though the guide maps only the fill.
#{
  let palette = resolve-theme-palette(default-theme)
  let ctx = (
    trained: (
      fill: (type: "discrete", domain: ("a", "b")),
      colour: (type: "discrete", domain: ("a", "b")),
    ),
    palette: palette,
    resolve-colour: _make-resolve-colour(black),
    theme: default-theme,
  )
  let guide = (
    aesthetics: ("fill",),
    columns: (fill: "g"),
    key-consts: (colour: black, size: 3pt),
    key-late: (colour: (expr: (c, _) => c.darken(40%), column: "g")),
  )
  let swatch = ((ctx.resolve-colour)(ctx.trained.colour, palette))("a")
  assert.eq(_key-bundle("a", guide, ctx, black).colour, swatch.darken(40%))
}
