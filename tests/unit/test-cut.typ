// Unit tests for cut-interval, cut-number, cut-width helpers.

#import "../../src/utils/cut.typ": cut-interval, cut-number, cut-width

// --- cut-interval: equal-width bins on 1..4 -------------------------------
// Range (1, 4), n = 2 -> breaks (1, 2.5, 4); values 1, 2 in lower bin,
// 3, 4 in upper bin.

#let r-int = cut-interval((1, 2, 3, 4), n: 2)
#assert.eq(r-int.len(), 4)
#assert.eq(r-int.at(0), "(1,2.5]")
#assert.eq(r-int.at(1), "(1,2.5]")
#assert.eq(r-int.at(2), "(2.5,4]")
#assert.eq(r-int.at(3), "(2.5,4]")

// Custom labels of matching length.
#let r-int-lab = cut-interval((1, 2, 3, 4), n: 2, labels: ("lo", "hi"))
#assert.eq(r-int-lab, ("lo", "lo", "hi", "hi"))

// none / non-numeric entries pass through as none.
#let r-int-na = cut-interval((1, none, "x", 4), n: 2)
#assert.eq(r-int-na.at(0), "(1,2.5]")
#assert.eq(r-int-na.at(1), none)
#assert.eq(r-int-na.at(2), none)
#assert.eq(r-int-na.at(3), "(2.5,4]")

// --- cut-number: quantile-based bins --------------------------------------
// On [1, 2, 3, 100], type-7 median is 2.5. Lower bin holds 1 and 2;
// upper bin holds 3 and 100. Crucially 100 is in the upper bin.

#let r-num = cut-number((1, 2, 3, 100), n: 2)
#assert.eq(r-num.len(), 4)
#assert.eq(r-num.at(0), r-num.at(1))
#assert.eq(r-num.at(2), r-num.at(3))
#assert(r-num.at(0) != r-num.at(3))
#assert.eq(r-num.at(3), "(2.5,100]")
#assert.eq(r-num.at(0), "(1,2.5]")

// Equal counts on 1..8, n = 4: each bin gets two values.
#let r-num4 = cut-number(range(1, 9), n: 4)
#assert.eq(r-num4.len(), 8)

// --- cut-width: fixed-width bins ------------------------------------------
// Width 2 over [1, 2, 3, 4, 5] anchored at zero: breaks 0, 2, 4, 6.
// 1, 2 fall in (0, 2]; 3, 4 fall in (2, 4]; 5 falls in (4, 6].

#let r-w = cut-width((1, 2, 3, 4, 5), width: 2)
#assert.eq(r-w.len(), 5)
#assert.eq(r-w.at(0), r-w.at(1))
#assert.eq(r-w.at(2), r-w.at(3))
#assert(r-w.at(0) != r-w.at(2))
#assert(r-w.at(2) != r-w.at(4))

// Centred bins: center = 2.5 with width 1 -> breaks 1, 2, 3, 4.
// Values 1 and 2 share the leftmost bin; 3 and 4 occupy bins of their own.
#let r-wc = cut-width((1, 2, 3, 4), width: 1, center: 2.5)
#assert.eq(r-wc.at(0), r-wc.at(1))
#assert(r-wc.at(1) != r-wc.at(2))
#assert(r-wc.at(2) != r-wc.at(3))

// Labels round the bounds as the axis ticks do.
#assert.eq(cut-interval((0, 1), n: 3).at(0), "(0,0.333]")
#assert.eq(cut-width((0.1, 0.35), width: 0.25).at(0), "(0,0.25]")

// Constant data takes a one-element `labels` array for its single bin.
#assert.eq(cut-interval((5, 5), n: 2, labels: ("x",)), ("x", "x"))

Cut helpers tests passed.
