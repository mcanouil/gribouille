// stat-difference: sign-split ribbon runs with exact crossing insertion.

#import "../../src/stat/apply.typ": apply-stat, stat-default-params
#import "../../src/stat/difference.typ": stat-difference

#let close(a, b, tol: 1e-9) = calc.abs(a - b) < tol
#let params(..over) = stat-default-params("difference") + over.named()
#let mapping = (x: "x", ymin: "a", ymax: "b")

// --- single crossing ---------------------------------------------------------
// a = (0, 2), b = (2, 0) over x = (0, 1): d = b - a goes +2 -> -2, so the
// series cross at t = 2 / (2 - (-2)) = 0.5: xc = 0.5, yc = 0 + 0.5 * 2 = 1.

#let d1 = ((x: 0, a: 0, b: 2), (x: 1, a: 2, b: 0))
#let r1 = apply-stat("difference", d1, mapping, params())

#assert.eq(r1.mapping.x, "x")
#assert.eq(r1.mapping.ymin, "ymin")
#assert.eq(r1.mapping.ymax, "ymax")
#assert.eq(r1.mapping.group, "group")

// Two runs of two vertices, sharing the crossing point.
#assert.eq(r1.data.len(), 4)
#assert.eq(r1.data.map(r => r.group), ("0", "0", "1", "1"))
#assert.eq(r1.data.map(r => r._sign), ("+", "+", "-", "-"))
#let c1 = r1.data.at(1)
#assert(close(c1.x, 0.5))
#assert(close(c1.ymin, 1))
#assert(close(c1.ymax, 1))
#let c2 = r1.data.at(2)
#assert.eq((c2.x, c2.ymin, c2.ymax), (c1.x, c1.ymin, c1.ymax))

// Source columns survive on every row.
#assert(r1.data.all(r => "a" in r and "b" in r))

// --- crossing on non-unit spacing ---------------------------------------------
// a = x, b = 4 - x on x = (0, 1, 3, 4): d = 4 - 2x = (+4, +2, -2, -4).
// Crossing between x = 1 and x = 3 at t = 2 / 4 = 0.5: xc = 2, yc = 2.

#let d2 = (0, 1, 3, 4).map(v => (x: v, a: v, b: 4 - v))
#let r2 = apply-stat("difference", d2, mapping, params())

#assert.eq(r2.data.len(), 6)
#assert.eq(r2.data.map(r => r.group), ("0", "0", "0", "1", "1", "1"))
#let cx = r2.data.at(2)
#assert(close(cx.x, 2))
#assert(close(cx.ymin, 2))
#assert(close(cx.ymax, 2))

// --- exact tie between opposite signs ----------------------------------------
// d = (+1, 0, -1): the tie row is itself the crossing, so the flip inserts
// a zero-length vertex at x = 1 and the second run starts there.

#let d3 = ((x: 0, a: 0, b: 1), (x: 1, a: 1, b: 1), (x: 2, a: 2, b: 1))
#let r3 = apply-stat("difference", d3, mapping, params())

#assert.eq(r3.data.map(r => r._sign).dedup(), ("+", "-"))
#let first-neg = r3.data.find(r => r._sign == "-")
#assert(close(first-neg.x, 1))
#assert(close(first-neg.ymin, first-neg.ymax))
#assert.eq(r3.data.last().group, "1")

// --- no crossing: one run, one level -----------------------------------------

#let d4 = (0, 1, 2).map(v => (x: v, a: v, b: v + 1))
#let r4 = apply-stat("difference", d4, mapping, params())
#assert.eq(r4.data.len(), 3)
#assert(r4.data.all(r => r._sign == "+" and r.group == "0"))

#let d5 = (0, 1, 2).map(v => (x: v, a: v + 1, b: v))
#let r5 = apply-stat("difference", d5, mapping, params())
#assert(r5.data.all(r => r._sign == "-" and r.group == "0"))

// --- all-tie group takes the first level ---------------------------------------

#let d6 = ((x: 0, a: 1, b: 1), (x: 1, a: 2, b: 2))
#let r6 = apply-stat("difference", d6, mapping, params())
#assert(r6.data.all(r => r._sign == "+" and r.group == "0"))

// --- custom levels through the constructor ------------------------------------

#let spec = stat-difference(levels: ("up", "down"))
#assert.eq(spec.name, "difference")
#let r7 = apply-stat("difference", d1, mapping, spec.params)
#assert.eq(r7.data.map(r => r._sign).dedup(), ("up", "down"))

// --- rows with a missing value on any channel are dropped ----------------------

#let d8 = (
  (x: 0, a: 0, b: 2),
  (x: 0.5, a: none, b: 1),
  (x: 1, a: 2, b: 0),
)
#let r8 = apply-stat("difference", d8, mapping, params())
#assert.eq(r8.data.len(), 4)
#assert(close(r8.data.at(1).x, 0.5))

// --- unsorted input is sorted by x before the walk ------------------------------

#let d9 = ((x: 1, a: 2, b: 0), (x: 0, a: 0, b: 2))
#let r9 = apply-stat("difference", d9, mapping, params())
#assert.eq(r9.data.map(r => r._sign), ("+", "+", "-", "-"))

stat-difference tests passed.
