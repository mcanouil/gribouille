// Wrangle slice: wide/long reshaping verbs.
//
// Typst cannot catch panics in-process, so the error paths (unknown columns,
// non-string names, name collisions, and an ambiguous duplicate spread in
// pivot-wider) are not asserted here.

#import "../../src/wrangle/reshape.typ": pivot-longer, pivot-wider
#import "../../src/data.typ": as-factor

#let wide = (
  (id: 1, a: 10, b: 20),
  (id: 2, a: 30, b: 40),
)

// --- pivot-longer ----------------------------------------------------------

#let long = pivot-longer(wide, ("a", "b"))
#assert.eq(long, (
  (id: 1, name: "a", value: 10),
  (id: 1, name: "b", value: 20),
  (id: 2, name: "a", value: 30),
  (id: 2, name: "b", value: 40),
))

// A single column melts too, and the output names are configurable.
#assert.eq(
  pivot-longer(wide, "a", names-to: "key", values-to: "val"),
  ((id: 1, b: 20, key: "a", val: 10), (id: 2, b: 40, key: "a", val: 30)),
)

// Column-store input is normalised on entry.
#assert.eq(
  pivot-longer((id: (1,), a: (10,), b: (20,)), ("a", "b")),
  ((id: 1, name: "a", value: 10), (id: 1, name: "b", value: 20)),
)

// --- pivot-wider -----------------------------------------------------------

// Missing name/identifier combinations fill with none.
#let stacked = (
  (g: "x", k: "p", v: 1),
  (g: "x", k: "q", v: 2),
  (g: "y", k: "p", v: 3),
)
#assert.eq(
  pivot-wider(stacked, names-from: "k", values-from: "v"),
  ((g: "x", p: 1, q: 2), (g: "y", p: 3, q: none)),
)

// New columns follow the first-appearance order of names-from, not sorted.
#let ordered = ((id: 1, k: "z", v: 1), (id: 1, k: "a", v: 2))
#assert.eq(
  pivot-wider(ordered, names-from: "k", values-from: "v").at(0).keys(),
  ("id", "z", "a"),
)

// Non-string names-from values are stringified into column keys.
#let numeric-names = ((id: 1, k: 1, v: "a"), (id: 1, k: 2, v: "b"))
#let widened = pivot-wider(numeric-names, names-from: "k", values-from: "v")
#assert.eq(widened.len(), 1)
#assert.eq(widened.at(0).at("1"), "a")
#assert.eq(widened.at(0).at("2"), "b")

// A duplicate names-from value within one identifier group fails as an
// ambiguous spread; Typst cannot catch the panic, so it is not asserted here.

// --- round-trip: pivot-longer then pivot-wider recovers the original -------

#assert.eq(
  pivot-wider(long, names-from: "name", values-from: "value"),
  wide,
)

// --- empty data ------------------------------------------------------------

#assert.eq(pivot-longer((), ("a", "b")), ())
#assert.eq(pivot-wider((), names-from: "k", values-from: "v"), ())

// --- factor tags carry through to the kept columns -------------------------

// A factored identifier column keeps its tag after pivot-longer.
#let flong = as-factor(((id: 1, a: 10, b: 20),), "id")
#assert.eq(
  pivot-longer(flong, ("a", "b")).at(0).at("_gribouille-factors"),
  ("id",),
)
// A factored identifier column keeps its tag after pivot-wider.
#let fwide = as-factor(((g: "x", k: "p", v: 1),), "g")
#assert.eq(
  pivot-wider(fwide, names-from: "k", values-from: "v")
    .at(0)
    .at("_gribouille-factors"),
  ("g",),
)
