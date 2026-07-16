// Unit tests for utility modules.

#import "../../src/utils/types.typ": infer-column-type, parse-number
#import "../../src/utils/pretty.typ": pretty
#import "../../src/data.typ": as-factor, as-numeric, column

// parse-number.
#assert.eq(parse-number("42"), 42.0)
#assert.eq(parse-number("  -3.14  "), -3.14)
#assert.eq(parse-number("1e3"), 1000.0)
#assert.eq(parse-number(""), none)
#assert.eq(parse-number("abc"), none)
#assert.eq(parse-number(none), none)
#assert.eq(parse-number(7), 7.0)
#assert.eq(parse-number(1.5), 1.5)

// infer-column-type.
#assert.eq(infer-column-type((1, 2, 3)), "numeric")
#assert.eq(infer-column-type((1.0, 2.5, 3.14)), "numeric")
#assert.eq(infer-column-type(("1", "2", "3")), "string")
#assert.eq(infer-column-type(("a", "b", "c")), "string")
#assert.eq(infer-column-type(("1", "a", "2")), "string")
#assert.eq(infer-column-type(("", none, "3")), "string")
#assert.eq(infer-column-type(()), "unknown")

// pretty.
#assert.eq(pretty(0, 10, n: 5), (0.0, 2.0, 4.0, 6.0, 8.0, 10.0))
#assert.eq(pretty(1.2, 3.7, n: 5).len() > 0, true)

// column.
#let df = ((a: 1, b: "x"), (a: 2, b: "y"), (a: 3, b: "z"))
#assert.eq(column(df, "a"), (1, 2, 3))
#assert.eq(column(df, "b"), ("x", "y", "z"))
#assert.eq(column(df, "missing"), (none, none, none))

// as-numeric.
#let df2 = ((a: "1", b: "x"), (a: "2.5", b: "y"))
#assert.eq(column(as-numeric(df2, "a"), "a"), (1.0, 2.5))

// as-numeric na: sentinels map to none before parsing; genuine numbers parse,
// including a sentinel that would otherwise parse as a valid number ("-99").
#let df3 = ((a: "1"), (a: "NA"), (a: "-99"), (a: "3"))
#assert.eq(column(as-numeric(df3, "a", na: ("NA", "-99")), "a"), (
  1.0,
  none,
  none,
  3.0,
))

// A bare sentinel is wrapped to a single-entry list (no substring matching).
#assert.eq(column(as-numeric(df3, "a", na: "NA"), "a"), (1.0, none, -99.0, 3.0))

// The default keeps the current behaviour (no sentinels).
#assert.eq(column(as-numeric(df3, "a"), "a"), (1.0, none, -99.0, 3.0))

// The one-arg tag form ignores na: and still returns a mapping-ref.
#assert.eq(as-numeric("a", na: ("NA",)).kind, "mapping-ref")

// String cells are compared trimmed (matching parse-number), so a padded
// numeric sentinel still matches instead of leaking through as a number.
#let df4 = ((a: " -99 "), (a: " NA "), (a: "5"))
#assert.eq(column(as-numeric(df4, "a", na: ("-99", "NA")), "a"), (
  none,
  none,
  5.0,
))

// Equality is type-sensitive: a native -99 cell needs a native sentinel.
#let df5 = ((a: -99), (a: 7))
#assert.eq(column(as-numeric(df5, "a", na: ("-99",)), "a"), (-99.0, 7.0))
#assert.eq(column(as-numeric(df5, "a", na: (-99,)), "a"), (none, 7.0))

// Sentinels match whole trimmed cells, never substrings ("9" does not hit "-99").
#assert.eq(column(as-numeric(df3, "a", na: ("9",)), "a"), (
  1.0,
  none,
  -99.0,
  3.0,
))

// as-factor.
#assert.eq(column(as-factor(((a: 1),), "a"), "a"), ("1",))

Unit tests passed.
