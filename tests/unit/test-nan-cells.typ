// NaN is an unusable cell: every reader drops it, as it drops a cell that does
// not parse, and none raises `cannot compare float.nan`.

#import "../../src/utils/types.typ": parse-number, to-numeric
#import "../../src/scale/breaks.typ": (
  breaks-extended, breaks-log, breaks-pretty, breaks-quantile, breaks-width,
)
#import "../../src/utils/cut.typ": cut-interval, cut-number, cut-width
#import "../../src/utils/format.typ": (
  format-log, format-number, format-percent, format-scientific,
)

#let nan = float.nan

// parse-number reads NaN as no value.
#assert.eq(parse-number(nan), none)
#assert.eq(to-numeric((1, nan, 3)), (1.0, 3.0))

// The break helpers skip NaN and answer from the usable values.
#assert.eq((breaks-width(1))((1, nan, 3)), (breaks-width(1))((1, 3)))
#assert.eq((breaks-pretty())((1, nan, 3)), (breaks-pretty())((1, 3)))
#assert.eq((breaks-extended())((1, nan, 3)), (breaks-extended())((1, 3)))
#assert.eq((breaks-quantile())((1, nan, 3)), (breaks-quantile())((1, 3)))
#assert.eq((breaks-log())((1, nan, 1000)), (breaks-log())((1, 1000)))
#assert.eq((breaks-width(1))((nan,)), ())

// The cut helpers give no bin to a NaN cell.
#assert.eq(cut-interval((1, nan, 3), n: 2).at(1), none)
#assert.eq(cut-number((1, nan, 3), n: 2).at(1), none)
#assert.eq(cut-width((1, nan, 3), width: 1).at(1), none)

// The formatters print a NaN break as text instead of comparing it.
#assert.eq((format-number())(nan), "NaN")
#assert.eq((format-percent())(nan), "NaN")
#assert.eq((format-scientific())(nan), "NaN")
#assert.eq((format-log())(nan), "NaN")
