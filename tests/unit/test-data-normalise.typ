// `_normalise-data` accepts row-store (array of dicts) or column-store
// (dict of equal-length arrays) and returns the canonical row-store form.

#import "../../src/data.typ": _normalise-data, column-names

// `none` passes through unchanged so per-layer "inherit plot data" stays
// unaffected.
#assert.eq(_normalise-data(none), none)

// Empty array stays empty.
#assert.eq(_normalise-data(()), ())

// Empty dict normalises to an empty row-store.
#assert.eq(_normalise-data((:)), ())

// Row-store passes through identically.
#let rows = ((a: 1, b: 3), (a: 2, b: 4))
#assert.eq(_normalise-data(rows), rows)

// Column-store converts to row-store, preserving key insertion order.
#let cols = (a: (1, 2), b: (3, 4))
#assert.eq(_normalise-data(cols), ((a: 1, b: 3), (a: 2, b: 4)))

// Single-row column-store.
#assert.eq(_normalise-data((a: (1,), b: (2,))), ((a: 1, b: 2),))

// Three-column, three-row column-store with mixed value types (mirrors the
// penguin label snippet that motivated this feature).
#let mixed = (
  "flipper-len": (190, 210, 230),
  "body-mass": (3500, 4500, 5500),
  "species": ("Adelie", "Chinstrap", "Gentoo"),
)
#let mixed-rows = _normalise-data(mixed)
#assert.eq(mixed-rows.len(), 3)
#assert.eq(mixed-rows.at(0).at("flipper-len"), 190)
#assert.eq(mixed-rows.at(1).at("species"), "Chinstrap")
#assert.eq(mixed-rows.at(2).at("body-mass"), 5500)

// Idempotent: feeding row-store back in returns it unchanged.
#assert.eq(_normalise-data(mixed-rows), mixed-rows)

// `column-names` lists a row-store's columns for mapping validation.
#assert.eq(column-names(((a: 1, b: 2), (a: 3, b: 4))), ("a", "b"))
// `none`, empty, and non-row-store input yield an empty list (nothing to check).
#assert.eq(column-names(none), ())
#assert.eq(column-names(()), ())
#assert.eq(column-names((a: (1, 2))), ())
// The `_gribouille-factors` sentinel from two-arg `as-factor` is excluded.
#assert.eq(
  column-names(((a: 1, _gribouille-factors: ("a",)),)),
  ("a",),
)

// The following inputs panic with a clear message; uncomment one at a time
// to verify the error path locally:
//
//   #let _ = _normalise-data(42)
//     panics with: data: must be an array of dicts or a dict of arrays; got integer
//
//   #let _ = _normalise-data(((a: 1), 2))
//     panics with: data: row-store array must contain dictionaries; got integer at index 1
//
//   #let _ = _normalise-data((a: 1, b: (2,)))
//     panics with: data: column-store value for "a" must be an array; got integer
//
//   #let _ = _normalise-data((a: (1, 2, 3), b: (4, 5)))
//     panics with: data: column-store columns must share the same length; got "a"=3, "b"=2

normalise-data tests passed.
