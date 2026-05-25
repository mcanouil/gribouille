// stat-boxplot quantile and summary tests.

#import "../../src/stat/apply.typ": apply-stat

// --- known quantiles on 1..9 ---
// For sorted (1..9, n=9), the type-7 quantiles are:
//   Q1 at position 0.25 * 8 = 2     -> 3
//   Q2 at position 0.5  * 8 = 4     -> 5
//   Q3 at position 0.75 * 8 = 6     -> 7
// IQR = 4, fence = [-3, 13], so no outliers and whiskers reach 1 and 9.

#let df1 = range(1, 10).map(v => (g: "a", y: v))
#let r1 = apply-stat("boxplot", df1, (x: "g", y: "y"), (:))
#assert.eq(r1.data.len(), 1)
#let row1 = r1.data.at(0)
#assert.eq(row1.lower, 3.0)
#assert.eq(row1.middle, 5.0)
#assert.eq(row1.upper, 7.0)
#assert.eq(row1.ymin, 1.0)
#assert.eq(row1.ymax, 9.0)
#assert.eq(row1.at("whisker-lo"), 1.0)
#assert.eq(row1.at("whisker-hi"), 9.0)
#assert.eq(row1.outliers, ())
// x is reported under its source column name, not a generic "x" key.
#assert.eq(row1.at("g"), "a")
#assert.eq(row1.keys().contains("x"), false)

// --- linear interpolation between neighbours ---
// Sorted (1..8, n=8) -> Q1 at position 0.25 * 7 = 1.75 -> 2 + 0.75 * 1 = 2.75.

#let df2 = range(1, 9).map(v => (g: "a", y: v))
#let r2 = apply-stat("boxplot", df2, (x: "g", y: "y"), (:))
#let row2 = r2.data.at(0)
#assert.eq(row2.lower, 2.75)
#assert.eq(row2.middle, 4.5)
#assert.eq(row2.upper, 6.25)

// --- outliers detected past 1.5 * IQR fence ---
// Append 100 to (1..9): with the extra point quartiles shift but 100 still
// lands well above the upper fence and ends up in `outliers`. The whisker
// stops at the largest non-outlier; ymin/ymax span the absolute extremes.

#let df3 = range(1, 10).map(v => (g: "a", y: v)) + ((g: "a", y: 100),)
#let r3 = apply-stat("boxplot", df3, (x: "g", y: "y"), (:))
#let row3 = r3.data.at(0)
#assert.eq(row3.outliers.contains(100.0), true)
#assert.eq(
  row3.at("whisker-hi") <= row3.upper + 1.5 * (row3.upper - row3.lower),
  true,
)
#assert.eq(row3.ymax >= 100.0, true)

// --- output mapping shape ---

#assert.eq(r1.mapping.x, "g")
#assert.eq(r1.mapping.lower, "lower")
#assert.eq(r1.mapping.middle, "middle")
#assert.eq(r1.mapping.upper, "upper")
#assert.eq(r1.mapping.ymin, "ymin")
#assert.eq(r1.mapping.ymax, "ymax")

// --- numeric x is parsed; non-numeric x is preserved ---

#let df4 = range(0, 5).map(v => (x: 2, y: v))
#let r4 = apply-stat("boxplot", df4, (x: "x", y: "y"), (:))
#assert.eq(r4.data.at(0).x, 2.0)

// --- multiple x levels yield one row each, in first-seen order ---

#let df5 = (
  (g: "b", y: 1),
  (g: "a", y: 1),
  (g: "b", y: 2),
  (g: "a", y: 2),
  (g: "a", y: 3),
)
#let r5 = apply-stat("boxplot", df5, (x: "g", y: "y"), (:))
#assert.eq(r5.data.len(), 2)
#assert.eq(r5.data.at(0).at("g"), "b")
#assert.eq(r5.data.at(1).at("g"), "a")

// --- same-column grouping aesthetic (fill == x) resolves ---
// The summary must expose the x column so a fill/colour aesthetic mapped to
// that same column trains its scale and resolves per group rather than
// collapsing to the default ink.
#let r6 = apply-stat("boxplot", df1, (x: "g", y: "y", fill: "g"), (:))
#assert.eq(r6.data.at(0).keys().contains("g"), true)
#assert.eq(r6.data.at(0).at("g"), "a")

Stat boxplot tests passed.
