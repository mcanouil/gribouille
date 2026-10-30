// nanoplot() builds a keisen renderer: the tag and the three drawers keisen
// checks, the readings of a cell, the x scale the cells and the axis share, and
// the axis switch.

#import "../../lib.typ": *
#import "../../src/integration/nanoplot.typ": (
  _auto-axis-height, _axis-theme, _coord, _x-scale,
)
#import "../../src/theme/theme.typ": _rect-style, resolve-element

#let renderer = nanoplot(
  mapping: aes(x: "salary", y: "y"),
  layers: (geom-point(),),
  domain-field: "salary",
)
#assert.eq(renderer.kind, "nanoplot-renderer")
#assert.eq(type(renderer.draw), function)
#assert.eq(type(renderer.readings), function)
#assert.eq(type(renderer.axis), function)
#assert.eq(nanoplot(domain-field: "salary", axis: false).axis, none)

// Every value keisen holds is read, so a value with no number gives nothing.
#assert.eq((renderer.readings)(((salary: 1, y: 0), (salary: 5, y: 0))), (
  1.0,
  5.0,
))
#assert.eq((renderer.readings)(((salary: decimal("2.5")),)), (2.5,))
#assert.eq((renderer.readings)(((salary: "n/a"), (y: 3), (salary: 4))), (4.0,))
#assert.eq((renderer.readings)(none), ())
#assert.eq((renderer.readings)(3), ())
#assert.eq((renderer.readings)(()), ())
// A value that is not a finite number would make the column domain unusable.
#assert.eq(
  (renderer.readings)((
    (salary: float.nan),
    (salary: float.inf),
    (salary: -float.inf),
    (salary: 2),
  )),
  (2.0,),
)

// The cells and the axis share the user's x scale, expansion included, and the
// domain is no scale limit, so a geom that draws whole marks cannot widen it.
#let bare = _x-scale((:))
#assert.eq(bare.at("limits", default: none), none)
#assert.eq(bare.expand, auto)
#let user = _x-scale(scales(x: scale-continuous(
  breaks: (2, 4),
  labels: format-comma(),
  expand: 5%,
)))
#assert.eq(user.at("limits", default: none), none)
#assert.eq(user.breaks, (2, 4))
#assert.eq(user.expand, 5%)
#assert.eq(type(user.labels), function)
#assert.eq(_x-scale(scales(x: scale-continuous(limits: (0, 3)))).limits, (0, 3))

// The domain is the x limits of the coordinate system.
#assert.eq(_coord(none), none)
#assert.eq(_coord((0, 10)).x-limits, (0, 10))

// The default axis height follows the axis text of the theme and its tick.
#let height(theme) = _auto-axis-height(
  _axis-theme(theme, "bottom", 3cm),
  "bottom",
)
#assert(
  height(theme-bw(axis-text: element-text(size: 20pt))) > height(theme-bw()),
)
#assert(height(theme-void()) > 0pt)

// The axis canvas reaches far past the column on each side, so the axis draws
// no spine and no plot background, which would reach past the column too.
#for side in ("top", "bottom") {
  for edge in ("x-top", "x-bottom", "y-left", "y-right") {
    assert.eq(
      resolve-element(
        _axis-theme(theme-bw(axis-line-y-left: element-line()), side, 4cm),
        "axis-line-" + edge,
      ).kind,
      "element-blank",
    )
  }
  // A colour with no thickness strokes at the default thickness, and a fill
  // or colour on `rect` reaches `plot-background` through the cascade.
  for theme in (
    theme-minimal(paper: luma(90%)),
    theme-minimal(plot-background: element-rect(colour: black)),
    theme-bw(rect: element-rect(fill: red, colour: black)),
  ) {
    let background = _rect-style(
      _axis-theme(theme, side, 4cm),
      "plot-background",
    )
    assert.eq((background.fill, background.stroke), (none, none))
  }
}

// A ratio side of the plot padding resolves against the canvas, and the axis
// canvas is wider than a cell, so the axis takes the cell's padding in length.
#let padded = resolve-element(
  _axis-theme(
    theme-minimal(plot-background: element-rect(
      inset: margin(left: 25%, right: 1cm + 25%),
      outset: margin(left: 50%),
    )),
    "bottom",
    4cm,
  ),
  "plot-background",
)
#assert.eq((padded.inset.left, padded.inset.right), (1cm, 2cm))
#assert.eq(padded.outset.left, 2cm)

// The drawers return content at the size keisen asks for.
#let cell = ((salary: 1, y: 0), (salary: 5, y: 0))
#assert.eq(
  type((renderer.draw)(cell, domain: (0, 10), width: 3cm, height: 0.5cm)),
  content,
)
#assert.eq(
  type((renderer.axis)(domain: (0, 10), width: 3cm, side: "top")),
  content,
)
#assert.eq(
  type((renderer.axis)(domain: (0, 10), width: 3cm, side: "bottom")),
  content,
)
#assert.eq((renderer.axis)(domain: none, width: 3cm, side: "bottom"), none)

// Typeset at an em width, the cell and both axes draw.
#set page(width: 12cm, height: auto)
#(renderer.draw)(cell, domain: (0, 10), width: 8em, height: 0.8em)
#(renderer.axis)(domain: (0, 10), width: 8em, side: "top")
#(renderer.axis)(domain: (0, 10), width: 8em, side: "bottom")
