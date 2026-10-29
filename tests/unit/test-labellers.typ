// Labeller string formatting.
//
// Verifies that each labeller produces the expected strip text for a
// representative (var, level, count) input. Compound labellers route by
// variable name and fall back to a default for missing keys.

#import "../../src/facet/labellers.typ" as lab
#import "../../src/utils/format.typ": format-wrap

// label-value: returns the level as-is, ignoring var and count.
#assert.eq(lab.format(lab.label-value(), "cyl", "6"), "6")
#assert.eq(lab.format(lab.label-value(), "cyl", "8", count: 11), "8")

// label-both: shows "var: level" with the configured separator.
#assert.eq(lab.format(lab.label-both(), "cyl", "6"), "cyl: 6")
#assert.eq(lab.format(lab.label-both(separator: " = "), "cyl", "6"), "cyl = 6")

// label-context: appends the row count when the renderer supplies one,
// otherwise falls back to the bare level.
#assert.eq(
  lab.format(lab.label-context(), "cyl", "6", count: 7),
  "6 (n = 7)",
)
#assert.eq(lab.format(lab.label-context(), "cyl", "6"), "6")

// label-wrap: hard-splits on whitespace at or before the limit.
#let wrapped = lab.format(lab.label-wrap(width: 5), "x", "hello world")
#assert.eq(wrapped, "hello\nworld")

// label-wrap with no usable space: hard split at the width.
#let hard = lab.format(lab.label-wrap(width: 4), "x", "abcdefgh")
#assert.eq(hard, "abcd\nefgh")

// label-wrap with an inner labeller composes the two transformations.
#let composed = lab.format(
  lab.label-wrap(width: 4, inner: lab.label-both()),
  "cyl",
  "8",
)
#assert.eq(composed, "cyl:\n8")

// labeller: routes by variable, falling back to its default.
#let comp = lab.labeller(
  rules: (cyl: lab.label-both(), gear: lab.label-value()),
)
#assert.eq(lab.format(comp, "cyl", "6"), "cyl: 6")
#assert.eq(lab.format(comp, "gear", "4"), "4")
// Variable not in rules: default labeller (label-value) wins.
#assert.eq(lab.format(comp, "vs", "1"), "1")

// labeller with explicit default still routes known variables.
#let comp2 = lab.labeller(
  rules: (cyl: lab.label-value()),
  default: lab.label-both(),
)
#assert.eq(lab.format(comp2, "cyl", "6"), "6")
#assert.eq(lab.format(comp2, "vs", "1"), "vs: 1")

// A non-string level converts with str() before it is joined.
#assert.eq(lab.format(lab.label-both(), "cyl", 6), "cyl: 6")

// Wrapping counts characters, so accented text is not cut mid-character.
#assert.eq(lab.format(lab.label-wrap(width: 3), "x", "ééé ééé"), "ééé\nééé")

// Greedy wrap fills each line, and a long word splits at the width.
#assert.eq(lab.format(lab.label-wrap(width: 5), "x", "ab cd ef"), "ab cd\nef")
#assert.eq(
  lab.format(lab.label-wrap(width: 4), "x", "abcdefgh ij"),
  "abcd\nefgh\nij",
)

// Both wrap helpers agree.
#assert.eq(
  lab.format(lab.label-wrap(width: 8), "x", "abcdefghij kl"),
  format-wrap(width: 8)("abcdefghij kl"),
)

Labeller tests passed.
