// Wrangle slice: summarise and count grouped aggregation verbs.
//
// Typst cannot catch panics in-process, so the error paths (unknown `by`
// column, non-function aggregation, name collision) are not asserted here.

#import "../../src/wrangle/summarise.typ": count, summarise

#let df = ((g: "a", x: 1), (g: "a", x: 2), (g: "b", x: 3))

// --- summarise over the whole dataset (by: none) --------------------------

#let r-all = summarise(
  df,
  n: rows => rows.len(),
  total: rows => rows.map(row => row.x).sum(),
)
#assert.eq(r-all.len(), 1)
#assert.eq(r-all.at(0), (n: 3, total: 6))

// A conditional tally is a plain closure over the group's rows.
#let r-cond = summarise(df, big: rows => rows.filter(row => row.x >= 2).len())
#assert.eq(r-cond.at(0).big, 2)

// --- summarise with a single by column ------------------------------------

#let r-g = summarise(df, n: rows => rows.len(), by: "g")
#assert.eq(r-g.len(), 2)
#assert.eq(r-g.at(0), (g: "a", n: 2))
#assert.eq(r-g.at(1), (g: "b", n: 1))
// Grouping columns come first, in `by:` order.
#assert.eq(r-g.at(0).keys(), ("g", "n"))

// A bare string and a one-element array group identically.
#assert.eq(
  summarise(df, n: rows => rows.len(), by: "g"),
  summarise(df, n: rows => rows.len(), by: ("g",)),
)

// --- summarise with multiple by columns -----------------------------------

#let df-2 = (
  (g: "a", h: "x", v: 1),
  (g: "a", h: "x", v: 2),
  (g: "a", h: "y", v: 5),
  (g: "b", h: "x", v: 4),
)
#let r-2 = summarise(
  df-2,
  s: rows => rows.map(row => row.v).sum(),
  by: ("g", "h"),
)
#assert.eq(r-2.len(), 3)
#assert.eq(r-2.at(0), (g: "a", h: "x", s: 3))
#assert.eq(r-2.at(1), (g: "a", h: "y", s: 5))
#assert.eq(r-2.at(2), (g: "b", h: "x", s: 4))

// --- column-store input is normalised on entry ----------------------------

#let cs = (g: ("a", "a", "b"), x: (1, 2, 3))
#let r-cs = summarise(cs, n: rows => rows.len(), by: "g")
#assert.eq(r-cs.at(0), (g: "a", n: 2))
#assert.eq(r-cs.at(1), (g: "b", n: 1))

// --- empty data ------------------------------------------------------------

// by: none still yields one row (the whole-dataset group).
#assert.eq(summarise((), n: rows => rows.len()), ((n: 0),))
// A grouped summary over no rows has no groups.
#assert.eq(summarise((), n: rows => rows.len(), by: "g"), ())

// --- first-appearance group order -----------------------------------------

#let df-order = ((g: "b", x: 1), (g: "a", x: 2), (g: "b", x: 3))
#let r-order = summarise(df-order, n: rows => rows.len(), by: "g")
#assert.eq(r-order.map(row => row.g), ("b", "a"))
#assert.eq(r-order.at(0).n, 2)

// --- count -----------------------------------------------------------------

#assert.eq(count(df, "g"), ((g: "a", n: 2), (g: "b", n: 1)))

// No columns tallies the grand total into `n`.
#assert.eq(count(df), ((n: 3),))
#assert.eq(count(()), ((n: 0),))

// sort: true orders by descending n.
#let df-sort = (
  (g: "a", x: 1),
  (g: "b", x: 2),
  (g: "b", x: 3),
  (g: "b", x: 4),
  (g: "a", x: 5),
)
#assert.eq(count(df-sort, "g", sort: true), ((g: "b", n: 3), (g: "a", n: 2)))

// Ties keep first-appearance order under a descending sort.
#let df-tie = (
  (g: "a"),
  (g: "b"),
  (g: "a"),
  (g: "b"),
  (g: "c"),
  (g: "c"),
)
#assert.eq(count(df-tie, "g", sort: true).map(row => row.g), ("a", "b", "c"))
