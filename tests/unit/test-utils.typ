// Unit tests for utility modules.

#import "../../src/utils/types.typ": parse-number, infer-column-type, is-numeric-value
#import "../../src/utils/pretty.typ": pretty
#import "../../src/data.typ": column, as-numeric, as-factor

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
#assert.eq(infer-column-type(("1", "2", "3")), "numeric")
#assert.eq(infer-column-type(("a", "b", "c")), "string")
#assert.eq(infer-column-type(("1", "a", "2")), "string")
#assert.eq(infer-column-type(("", none, "3")), "numeric")
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

// as-factor.
#assert.eq(column(as-factor(((a: 1),), "a"), "a"), ("1",))

Unit tests passed.
