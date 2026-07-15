// Wrangle slice: column/row selection verbs.
//
// Typst cannot catch panics in-process, so the error paths (unknown columns,
// non-string names, duplicate rename targets, mutually exclusive anchors) are
// not asserted here.

#import "../../src/wrangle/select.typ": (
  distinct, drop-na, relocate, rename, select, slice-max, slice-min,
)
#import "../../src/data.typ": as-factor

#let df = (
  (id: 1, class: "a", hwy: 30, cty: 20),
  (id: 2, class: "a", hwy: 20, cty: 15),
  (id: 3, class: "b", hwy: 40, cty: 25),
  (id: 4, class: "b", hwy: 10, cty: 8),
)

// --- select ----------------------------------------------------------------

#assert.eq(select(df, "id", "hwy").at(0), (id: 1, hwy: 30))
// Column order follows the given names, not the input.
#assert.eq(select(df, "hwy", "id").at(0).keys(), ("hwy", "id"))

// Column-store input is normalised on entry.
#assert.eq(select((a: (1, 2), b: ("x", "y")), "a"), ((a: 1), (a: 2)))

// A selected as-factor column keeps its discrete tag; dropping it drops the tag.
#let facted = as-factor(df, "class")
#assert.eq(select(facted, "class", "hwy").at(0).at("_gribouille-factors"), (
  "class",
))
#assert.eq("_gribouille-factors" in select(facted, "hwy").at(0), false)

// --- rename ----------------------------------------------------------------

#assert.eq(rename(df, highway: "hwy").at(0), (
  id: 1,
  class: "a",
  highway: 30,
  cty: 20,
))
// The new name sits where the old column was.
#assert.eq(rename(df, highway: "hwy").at(0).keys(), (
  "id",
  "class",
  "highway",
  "cty",
))

// A renamed as-factor column keeps its tag under the new name.
#let rf = rename(facted, kind: "class")
#assert.eq(rf.at(0).kind, "a")
#assert.eq(rf.at(0).at("_gribouille-factors"), ("kind",))

// --- relocate --------------------------------------------------------------

#assert.eq(relocate(df, "hwy").at(0).keys(), ("hwy", "id", "class", "cty"))
#assert.eq(relocate(df, "hwy", before: "class").at(0).keys(), (
  "id",
  "hwy",
  "class",
  "cty",
))
#assert.eq(relocate(df, "id", after: "hwy").at(0).keys(), (
  "class",
  "hwy",
  "id",
  "cty",
))

// --- drop-na ---------------------------------------------------------------

#let dfn = ((a: 1, b: 2), (a: none, b: 3), (a: 4, b: none))
#assert.eq(drop-na(dfn, "a"), ((a: 1, b: 2), (a: 4, b: none)))
#assert.eq(drop-na(dfn, "a", "b"), ((a: 1, b: 2),))
// No columns inspects every column.
#assert.eq(drop-na(dfn), ((a: 1, b: 2),))

// --- distinct --------------------------------------------------------------

#let dfd = ((k: "x", v: 1), (k: "x", v: 2), (k: "y", v: 3))
// Keyed dedup keeps the first full row per key, in first-appearance order.
#assert.eq(distinct(dfd, "k"), ((k: "x", v: 1), (k: "y", v: 3)))
// No columns falls back to whole-row dedup.
#assert.eq(distinct(((a: 1), (a: 1), (a: 2))), ((a: 1), (a: 2)))

// --- edge cases: empty data, single row, missing keys ----------------------

#assert.eq(select((), "a"), ())
#assert.eq(rename((), x: "a"), ())
#assert.eq(drop-na((), "a"), ())
#assert.eq(distinct((), "a"), ())

#assert.eq(select(((a: 1, b: 2),), "b"), ((b: 2),))
#assert.eq(distinct(((a: 1),), "a"), ((a: 1),))

// A row missing the inspected key is treated as missing and dropped.
#assert.eq(drop-na(((a: 1), (b: 2)), "a"), ((a: 1),))

// --- slice-max / slice-min -------------------------------------------------

#assert.eq(slice-max(df, "hwy", n: 2).map(row => row.id), (3, 1))
#assert.eq(slice-min(df, "hwy").map(row => row.id), (4,))
// n beyond the row count returns every ranked row.
#assert.eq(slice-max(df, "hwy", n: 10).len(), 4)
#assert.eq(slice-max(df, "hwy", n: 0), ())

// by: ranks within each group, groups in first-appearance order; n defaults
// to 1, so one row per group.
#assert.eq(slice-max(df, "hwy", by: "class").map(row => row.id), (1, 3))
#assert.eq(slice-min(df, "hwy", by: "class").map(row => row.id), (2, 4))

// Ties keep input order and there is no tie expansion.
#let dft = ((id: 1, v: 5), (id: 2, v: 5), (id: 3, v: 3))
#assert.eq(slice-max(dft, "v", n: 1).map(row => row.id), (1,))

// String cells are parsed; non-numeric cells sort last, kept only if n reaches
// them ("NA" appears only once n covers the two numeric rows).
#let dfp = ((id: 1, v: "5"), (id: 2, v: "NA"), (id: 3, v: "9"))
#assert.eq(slice-max(dfp, "v", n: 2).map(row => row.id), (3, 1))
#assert.eq(slice-max(dfp, "v", n: 3).map(row => row.id), (3, 1, 2))

// Empty data and a single row are handled.
#assert.eq(slice-max((), "v"), ())
#assert.eq(slice-max(((id: 9, v: 1),), "v", n: 5).map(row => row.id), (9,))

// A missing key reads as missing, so it sorts last like a non-numeric cell.
#let dfk = ((id: 1, v: 2), (id: 2), (id: 3, v: 8))
#assert.eq(slice-max(dfk, "v", n: 3).map(row => row.id), (3, 1, 2))
