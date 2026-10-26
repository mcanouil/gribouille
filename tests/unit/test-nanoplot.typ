// nanoplot() builds a keisen renderer: the tag and the three drawers keisen
// checks, the readings of a cell, the x scale the cells and the axis share, and
// the axis switch.

#import "../../lib.typ": *
#import "../../src/integration/nanoplot.typ": _axis-theme, _x-scale
#import "../../src/theme/theme.typ": resolve-element

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

// The shared domain becomes the x limits, the expansion stays at Gribouille's
// default unless the user scale sets one, and the other arguments stay.
#let bare = _x-scale((:), (0, 10))
#assert.eq(bare.limits, (0, 10))
#assert.eq(bare.expand, auto)
#let user = _x-scale(
  scales(x: scale-continuous(
    breaks: (2, 4),
    labels: format-comma(),
    expand: 5%,
  )),
  (1, 9),
)
#assert.eq(user.limits, (1, 9))
#assert.eq(user.breaks, (2, 4))
#assert.eq(user.expand, 5%)
#assert.eq(type(user.labels), function)
#assert.eq(_x-scale(scales(x: scale-continuous(limits: (0, 3))), none).limits, (
  0,
  3,
))

// The axis canvas reaches far past the column on each side, so the axis draws
// no spine and no plot background, which would reach past the column too.
#for side in ("top", "bottom") {
  assert.eq(
    resolve-element(_axis-theme(theme-bw(), side), "axis-line-x-" + side).kind,
    "element-blank",
  )
  let background = resolve-element(
    _axis-theme(theme-minimal(paper: luma(90%)), side),
    "plot-background",
  )
  assert.eq(background.kind, "element-rect")
  assert.eq(background.at("fill", default: none), none)
  assert.eq(background.at("stroke", default: none), none)
}

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
