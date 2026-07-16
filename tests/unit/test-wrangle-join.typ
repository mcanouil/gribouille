// Wrangle slice: join and bind verbs.
//
// Typst cannot catch panics in-process, so the error paths (unknown keys, no
// common columns, non-key column collision, bind-cols length mismatch or
// duplicate columns) are not asserted here.

#import "../../src/wrangle/join.typ": (
  anti-join, bind-cols, bind-rows, full-join, inner-join, left-join, semi-join,
)
#import "../../src/data.typ": as-factor

#let orders = ((id: 1, cust: "a"), (id: 2, cust: "b"), (id: 3, cust: "c"))
#let customers = ((cust: "a", city: "NY"), (cust: "b", city: "LA"))

// --- left-join -------------------------------------------------------------

// x columns first, then y's non-key columns; an unmatched x row none-fills.
#assert.eq(left-join(orders, customers, by: "cust"), (
  (id: 1, cust: "a", city: "NY"),
  (id: 2, cust: "b", city: "LA"),
  (id: 3, cust: "c", city: none),
))

// by: none joins on the common columns.
#assert.eq(left-join(orders, customers), left-join(
  orders,
  customers,
  by: "cust",
))

// Multiple y matches expand to one output row each, in y order.
#assert.eq(
  left-join(
    ((id: 1, cust: "a"),),
    ((cust: "a", city: "NY"), (cust: "a", city: "NJ")),
    by: "cust",
  ),
  ((id: 1, cust: "a", city: "NY"), (id: 1, cust: "a", city: "NJ")),
)

// A compound key matches on every listed column.
#assert.eq(
  left-join(
    ((k1: 1, k2: "x", v: 10), (k1: 1, k2: "y", v: 20)),
    ((k1: 1, k2: "x", w: 99),),
    by: ("k1", "k2"),
  ),
  ((k1: 1, k2: "x", v: 10, w: 99), (k1: 1, k2: "y", v: 20, w: none)),
)

// Column-store input is normalised on entry.
#assert.eq(
  left-join((id: (1,), cust: ("a",)), customers, by: "cust"),
  ((id: 1, cust: "a", city: "NY"),),
)

// --- inner-join ------------------------------------------------------------

#assert.eq(inner-join(orders, customers, by: "cust"), (
  (id: 1, cust: "a", city: "NY"),
  (id: 2, cust: "b", city: "LA"),
))

// --- full-join -------------------------------------------------------------

// Unmatched y rows append with x's non-key columns none-filled.
#assert.eq(
  full-join(
    orders,
    ((cust: "a", city: "NY"), (cust: "d", city: "SF")),
    by: "cust",
  ),
  (
    (id: 1, cust: "a", city: "NY"),
    (id: 2, cust: "b", city: none),
    (id: 3, cust: "c", city: none),
    (id: none, cust: "d", city: "SF"),
  ),
)

// --- semi-join / anti-join -------------------------------------------------

#assert.eq(
  semi-join(orders, customers, by: "cust"),
  ((id: 1, cust: "a"), (id: 2, cust: "b")),
)
#assert.eq(anti-join(orders, customers, by: "cust"), ((id: 3, cust: "c"),))

// --- empty inputs ----------------------------------------------------------

#assert.eq(left-join((), customers, by: "cust"), ())
// An empty y contributes no columns, so x passes through unchanged.
#assert.eq(
  left-join(orders, (), by: "cust"),
  ((id: 1, cust: "a"), (id: 2, cust: "b"), (id: 3, cust: "c")),
)
// full-join with an empty x still emits the y rows with their key columns.
#assert.eq(
  full-join((), customers, by: "cust"),
  ((cust: "a", city: "NY"), (cust: "b", city: "LA")),
)

// --- bind-rows -------------------------------------------------------------

// Column union in first-appearance order; missing cells none-fill.
#assert.eq(bind-rows(((a: 1),), ((a: 2, b: 3),)), (
  (a: 1, b: none),
  (a: 2, b: 3),
))
#assert.eq(bind-rows(), ())
#assert.eq(bind-rows(((a: 1), (a: 2))), ((a: 1), (a: 2)))

// --- bind-cols -------------------------------------------------------------

#assert.eq(
  bind-cols(((a: 1), (a: 2)), ((b: 3), (b: 4))),
  ((a: 1, b: 3), (a: 2, b: 4)),
)
#assert.eq(bind-cols(), ())

// --- factor tags carry through --------------------------------------------

// A factored key column keeps its tag through a join.
#let xf = as-factor(((id: 1, cust: "a"),), "cust")
#assert.eq(
  left-join(xf, customers, by: "cust").at(0).at("_gribouille-factors"),
  ("cust",),
)
// A factored non-key column from y keeps its tag too.
#let yf = as-factor(((cust: "a", city: "NY"),), "city")
#assert.eq(
  left-join(((id: 1, cust: "a"),), yf, by: "cust")
    .at(0)
    .at("_gribouille-factors"),
  ("city",),
)
