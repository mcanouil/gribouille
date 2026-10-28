// labels() builds a labels record and injects axis titles into trained scale specs.

#import "../../src/labels.typ": labels
#import "../../src/render/domain.typ": _apply-labels
#import "../../src/render/axis-format.typ": _axis-title

#let l = labels(
  title: "T",
  subtitle: "S",
  caption: "C",
  x: "X-axis",
  y: "Y-axis",
  colour: "Colour",
)
#assert.eq(l.kind, "labels")
#assert.eq(l.title, "T")
#assert.eq(l.subtitle, "S")
#assert.eq(l.caption, "C")
#assert.eq(l.axes.x, "X-axis")
#assert.eq(l.axes.y, "Y-axis")
#assert.eq(l.axes.colour, "Colour")

// Every field defaults to `auto`, which derives or omits the label.
#assert.eq(labels().axes.x, auto)
#assert.eq(labels().title, auto)

#let trained = (
  x: (spec: (aesthetic: "x", name: "col-x")),
  y: (spec: (aesthetic: "y", name: "col-y")),
)

// `auto` keeps the scale-derived name and reserves the title.
#let t-auto = _apply-labels(trained, labels(), ())
#assert.eq(_axis-title(t-auto.x, "fallback"), "col-x")

// A string overrides the scale name.
#let t-str = _apply-labels(trained, labels(x: "Custom"), ())
#assert.eq(_axis-title(t-str.x, "fallback"), "Custom")

// `none` sets the blank flag and suppresses the title even when a name exists.
#let t-none = _apply-labels(trained, labels(x: none), ())
#assert.eq(t-none.x.spec.blank, true)
#assert.eq(_axis-title(t-none.x, "fallback"), none)
#assert.eq(_axis-title(t-none.y, "fallback"), "col-y")

// A Q-Q layer names its own axes, and an explicit scale name or label wins.
#let qq-layers = ((stat-source: "qq"), (stat-source: "qq-line"))
#let unnamed = (
  x: (spec: (aesthetic: "x")),
  y: (spec: (aesthetic: "y")),
)
#let t-qq = _apply-labels(unnamed, labels(), qq-layers)
#assert.eq(_axis-title(t-qq.x, none), "theoretical")
#assert.eq(_axis-title(t-qq.y, none), "sample")
#assert.eq(_apply-labels(trained, labels(), qq-layers).x.spec.name, "col-x")
#assert.eq(
  _axis-title(_apply-labels(unnamed, labels(y: "Mine"), qq-layers).y, none),
  "Mine",
)
#assert.eq(
  _axis-title(
    _apply-labels(unnamed, labels(), (
      (stat-source: "qq"),
      (stat-source: "bin"),
    )).x,
    none,
  ),
  none,
)

Labels tests passed.
