// labs() builds a labs record and injects axis titles into trained scale specs.

#import "../../src/labs.typ": labs
#import "../../src/render.typ": _apply-labs, _axis-title

#let l = labs(
  title: "T",
  subtitle: "S",
  caption: "C",
  x: "X-axis",
  y: "Y-axis",
  colour: "Colour",
)
#assert.eq(l.kind, "labs")
#assert.eq(l.title, "T")
#assert.eq(l.subtitle, "S")
#assert.eq(l.caption, "C")
#assert.eq(l.axes.x, "X-axis")
#assert.eq(l.axes.y, "Y-axis")
#assert.eq(l.axes.colour, "Colour")

// Every field defaults to `auto`, which derives or omits the label.
#assert.eq(labs().axes.x, auto)
#assert.eq(labs().title, auto)

#let trained = (
  x: (spec: (aesthetic: "x", name: "col-x")),
  y: (spec: (aesthetic: "y", name: "col-y")),
)

// `auto` keeps the scale-derived name and reserves the title.
#let t-auto = _apply-labs(trained, labs())
#assert.eq(_axis-title(t-auto.x, "fallback"), "col-x")

// A string overrides the scale name.
#let t-str = _apply-labs(trained, labs(x: "Custom"))
#assert.eq(_axis-title(t-str.x, "fallback"), "Custom")

// `none` sets the blank flag and suppresses the title even when a name exists.
#let t-none = _apply-labs(trained, labs(x: none))
#assert.eq(t-none.x.spec.blank, true)
#assert.eq(_axis-title(t-none.x, "fallback"), none)
#assert.eq(_axis-title(t-none.y, "fallback"), "col-y")

Labs tests passed.
