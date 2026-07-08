// bind-scale validates stub arguments eagerly: valid keys bind and produce
// the concrete scale dict; an unknown key or a positional argument panics
// with a scales-scoped message before reaching the builder.

#import "../../src/scale/bind.typ": bind-scale
#import "../../src/scale/constructors.typ": (
  scale-continuous, scale-date, scale-grey, scale-identity, scale-log10,
  scale-manual, scale-viridis-b,
)

// Positional scales accept their full key set.
#let x-cont = bind-scale(
  "x",
  scale-continuous(name: "X", limits: (0, 10), breaks: (0, 5, 10)),
)
#assert.eq(x-cont.aesthetic, "x")
#assert.eq(x-cont.name, "X")
#assert.eq(x-cont.limits, (0, 10))

// The same family binds a different key set per aesthetic.
#let size-cont = bind-scale("size", scale-continuous(range: (1pt, 8pt)))
#assert.eq(size-cont.range, (1pt, 8pt))

// Transform families take the trimmed positional key set.
#let x-log = bind-scale("x", scale-log10(limits: (1, 1000)))
#assert.eq(x-log.limits, (1, 1000))

// Colour families and their sole-option knobs.
#let fill-grey = bind-scale("fill", scale-grey(start: 0.1, end: 0.9))
#assert.eq(fill-grey.aesthetic, "fill")
#let colour-vb = bind-scale("colour", scale-viridis-b(n-breaks: 4))
#assert.eq(colour-vb.aesthetic, "colour")

// Manual and identity key sets.
#let shape-manual = bind-scale(
  "shape",
  scale-manual(values: ("circle", "square")),
)
#assert.eq(shape-manual.aesthetic, "shape")
#let colour-id = bind-scale("colour", scale-identity())
#assert.eq(colour-id.type, "identity")

// Temporal scales keep their injected date-format default plus user keys.
#let x-date = bind-scale("x", scale-date(name: "Day"))
#assert.eq(x-date.name, "Day")

// Typst cannot catch panics in-process; uncomment to verify locally:
// #let _ = bind-scale("x", scale-continuous(limitz: (0, 10)))
//   panics with: scales: scale-continuous argument for x must be one of
//   "name", "limits", "oob", "breaks", "minor-breaks", "n-minor", "labels",
//   "transform", "expand", "secondary"; got "limitz".
// #let _ = bind-scale("size", scale-continuous(secondary: none))
//   panics with: scales: scale-continuous argument for size must be one of
//   "name", "range", "limits", "oob", "breaks", "labels"; got "secondary".
// #let _ = bind-scale("x", scale-log10((0, 10)))
//   panics with: scales: scale-log10 takes no positional arguments. Pass
//   options as named arguments.

Scale bind key tests passed.
