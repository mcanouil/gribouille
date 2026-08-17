// Position adjustments: stack, dodge, fill.

#import "../../src/position/apply.typ": apply-position
#import "../../src/coord/radial.typ": coord-radial

#let assert-close(a, b, tol: 1e-9) = {
  assert(
    calc.abs(a - b) < tol,
    message: "expected " + repr(a) + " ~= " + repr(b),
  )
}

#let df = (
  (q: "Q1", g: "A", y: 10),
  (q: "Q1", g: "B", y: 20),
  (q: "Q2", g: "A", y: 30),
  (q: "Q2", g: "B", y: 10),
)
#let mapping = (x: "q", y: "y", fill: "g")

// stack (cartesian): first alphabetic group sits at the top of each x
// bucket so the legend top entry matches the top band. Output preserves
// the input row order; only ymin/ymax are reassigned per row.
#let stacked = apply-position("stack", df, mapping)
#assert.eq(stacked.data.at(0).ymin, 20)
#assert.eq(stacked.data.at(0).ymax, 30)
#assert.eq(stacked.data.at(1).ymin, 0)
#assert.eq(stacked.data.at(1).ymax, 20)
#assert.eq(stacked.data.at(2).ymin, 10)
#assert.eq(stacked.data.at(2).ymax, 40)
#assert.eq(stacked.data.at(3).ymin, 0)
#assert.eq(stacked.data.at(3).ymax, 10)
#assert.eq(stacked.mapping.ymin, "ymin")
#assert.eq(stacked.mapping.ymax, "ymax")

// stack (radial): cumulation flips to bottom-up so the first alphabetic
// level is the first slice clockwise from 12 o'clock.
#let stacked-radial = apply-position(
  "stack",
  df,
  mapping,
  coord: coord-radial(theta: "y"),
)
#assert.eq(stacked-radial.data.at(0).ymin, 0)
#assert.eq(stacked-radial.data.at(0).ymax, 10)
#assert.eq(stacked-radial.data.at(1).ymin, 10)
#assert.eq(stacked-radial.data.at(1).ymax, 30)
#assert.eq(stacked-radial.data.at(2).ymin, 0)
#assert.eq(stacked-radial.data.at(2).ymax, 30)
#assert.eq(stacked-radial.data.at(3).ymin, 30)
#assert.eq(stacked-radial.data.at(3).ymax, 40)

// fill (cartesian): same top-down order, normalised per x.
#let filled = apply-position("fill", df, mapping)
#assert.eq(filled.data.at(0).ymin, 20.0 / 30.0)
#assert.eq(filled.data.at(0).ymax, 1.0)
#assert.eq(filled.data.at(1).ymin, 0.0)
#assert.eq(filled.data.at(1).ymax, 20.0 / 30.0)
#assert.eq(filled.data.at(2).ymax, 1.0)
#assert.eq(filled.data.at(3).ymax, 10.0 / 40.0)

// fill (radial): flipped to bottom-up.
#let filled-radial = apply-position(
  "fill",
  df,
  mapping,
  coord: coord-radial(theta: "y"),
)
#assert.eq(filled-radial.data.at(0).ymin, 0.0)
#assert.eq(filled-radial.data.at(0).ymax, 10.0 / 30.0)
#assert.eq(filled-radial.data.at(1).ymax, 1.0)
#assert.eq(filled-radial.data.at(2).ymax, 30.0 / 40.0)
#assert.eq(filled-radial.data.at(3).ymax, 1.0)

// dodge: uniform widths share the bucket evenly, with the default padding
// shrinking each mark so neighbouring slots no longer touch.
#let dodged = apply-position("dodge", df, mapping)
#assert-close(dodged.data.at(0)._dodge-n, 2 / 0.9)
#assert.eq(dodged.data.at(0)._dodge-offset, -0.25)
#assert.eq(dodged.data.at(1)._dodge-offset, 0.25)

// dodge: padding shrinks the mark and leaves the slot centres alone, so marks
// placed through dodge-delta stay centred over their bar.
#let padded = apply-position(
  "dodge",
  df,
  mapping,
  params: (width: 0.9, padding: 0.5),
)
#assert.eq(padded.data.at(0)._dodge-offset, dodged.data.at(0)._dodge-offset)
#assert.eq(padded.data.at(1)._dodge-offset, dodged.data.at(1)._dodge-offset)
#assert(padded.data.at(0)._dodge-n > dodged.data.at(0)._dodge-n)

// dodge: padding 0 keeps the slots abutting, as position-jitterdodge expects.
#let unpadded = apply-position(
  "dodge",
  df,
  mapping,
  params: (width: 0.9, padding: 0),
)
#assert.eq(unpadded.data.at(0)._dodge-n, 2)
#assert.eq(unpadded.data.at(0)._dodge-offset, -0.25)

// dodge: mixed per-row widths pack side-by-side without exceeding the bucket.
#let mixed-df = (
  (q: "Q1", g: "A", y: 10, width: 0.6),
  (q: "Q1", g: "B", y: 20, width: 0.4),
)
#let mixed = apply-position(
  "dodge",
  mixed-df,
  mapping,
  params: (width: 0.9, padding: 0.1),
)
// Bucket layout: widths (0.6, 0.4) with 0.1 padding sums to 1.1 so all
// values shrink by 1/1.1 = ~0.909. Slot 1 centre = -0.5 + 0.6/2.2 = -0.2727...
#let mixed-bar = 0.9
#let mixed-scale = 1.0 / 1.1
#let centre-a = -0.5 + 0.6 * mixed-scale / 2
#let centre-b = -0.5 + (0.6 + 0.1) * mixed-scale + 0.4 * mixed-scale / 2
#assert-close(mixed.data.at(0)._dodge-offset, centre-a / mixed-bar)
#assert-close(mixed.data.at(1)._dodge-offset, centre-b / mixed-bar)
// Corresponding bar half-widths fit inside [-0.5, 0.5] of the bucket.
#let half-a = (0.6 * mixed-scale) / 2
#let half-b = (0.4 * mixed-scale) / 2
#assert(centre-a + half-a <= centre-b - half-b)
#assert(centre-a - half-a >= -0.5)
#assert(centre-b + half-b <= 0.5)

// jitterdodge: groups dodge then jitter within their slot on a numeric x.
#let jd-df = ()
#for x in (1, 2) {
  for grp in ("A", "B") {
    for _ in range(0, 4) {
      jd-df.push((x: x, y: 1, grp: grp))
    }
  }
}
#let jd-mapping = (x: "x", y: "y", colour: "grp")
#let jd = apply-position(
  "jitterdodge",
  jd-df,
  jd-mapping,
  params: (
    width: 0.0,
    height: 0,
    "dodge-width": 0.75,
    seed: 0,
  ),
)
// With width: 0 the jitter step is zero, so points sit on their dodge centre.
// Groups A/B at category-step 1 with dodge-width 0.75 land at x +/- 0.1875.
#assert.eq(jd.data.at(0).x, 1 - 0.1875)
#assert.eq(jd.data.at(4).x, 1 + 0.1875)
#assert.eq(jd.data.at(8).x, 2 - 0.1875)

// identity: pass-through.
#let id = apply-position("identity", df, mapping)
#assert.eq(id.data, df)
#assert.eq(id.mapping, mapping)

// --- streamgraph offsets on stack -------------------------------------------
// Two x buckets so per-bucket baselines are visibly independent.
// Bucket x = 0: a = 3, b = 5, c = 2 (tot 10); bucket x = 1: all 1 (tot 3).

#let sg = (
  (x: 0, g: "a", y: 3),
  (x: 0, g: "b", y: 5),
  (x: 0, g: "c", y: 2),
  (x: 1, g: "a", y: 1),
  (x: 1, g: "b", y: 1),
  (x: 1, g: "c", y: 1),
)
#let sg-mapping = (x: "x", y: "y", fill: "g")

// silhouette: every stack centred on zero (base = -tot / 2).
#let sil = apply-position(
  "stack",
  sg,
  sg-mapping,
  params: (offset: "silhouette"),
)
#assert-close(sil.data.at(0).ymin, 2)
#assert-close(sil.data.at(0).ymax, 5)
#assert-close(sil.data.at(1).ymin, -3)
#assert-close(sil.data.at(1).ymax, 2)
#assert-close(sil.data.at(2).ymin, -5)
#assert-close(sil.data.at(2).ymax, -3)
#assert-close(sil.data.at(3).ymin, 0.5)
#assert-close(sil.data.at(3).ymax, 1.5)
#assert-close(sil.data.at(5).ymin, -1.5)
#assert-close(sil.data.at(5).ymax, -0.5)

// wiggle: Byron-Wattenberg baseline. Bucket x = 0, top-down (a, b, c) with
// weights (1, 2, 3): g0 = -(1*3 + 2*5 + 3*2) / 4 = -4.75. Bucket x = 1:
// g0 = -(1 + 2 + 3) / 4 = -1.5.
#let wig = apply-position(
  "stack",
  sg,
  sg-mapping,
  params: (offset: "wiggle"),
)
#assert-close(wig.data.at(0).ymin, 2.25)
#assert-close(wig.data.at(0).ymax, 5.25)
#assert-close(wig.data.at(1).ymin, -2.75)
#assert-close(wig.data.at(1).ymax, 2.25)
#assert-close(wig.data.at(2).ymin, -4.75)
#assert-close(wig.data.at(2).ymax, -2.75)
#assert-close(wig.data.at(3).ymin, 0.5)
#assert-close(wig.data.at(3).ymax, 1.5)
#assert-close(wig.data.at(4).ymin, -0.5)
#assert-close(wig.data.at(4).ymax, 0.5)
#assert-close(wig.data.at(5).ymin, -1.5)
#assert-close(wig.data.at(5).ymax, -0.5)

// The default and the explicit "none" offset agree with plain stacking.
#let none-offset = apply-position(
  "stack",
  sg,
  sg-mapping,
  params: (offset: "none"),
)
#let plain = apply-position("stack", sg, sg-mapping)
#assert.eq(none-offset.data, plain.data)

// Zero-total buckets (stat-align's edge pads) are dropped under a shifted
// offset instead of pinching the stream to y = 0, and kept under "none".
#let padded = (
  ((x: -0.01, g: "a", y: 0), (x: -0.01, g: "b", y: 0))
    + sg.slice(0, 2)
    + ((x: 2, g: "a", y: 0), (x: 2, g: "b", y: 4))
)
#let sil-pad = apply-position(
  "stack",
  padded,
  sg-mapping,
  params: (offset: "silhouette"),
)
#assert.eq(sil-pad.data.len(), 4)
#assert(sil-pad.data.all(r => r.x != -0.01))
// A zero row in a non-empty bucket stays: zero-height band at its stacked
// position (base -2, below the b = 4 band).
#let zero-row = sil-pad.data.find(r => r.x == 2 and r.g == "a")
#assert-close(zero-row.ymin, 2)
#assert-close(zero-row.ymax, 2)
#let none-pad = apply-position(
  "stack",
  padded,
  sg-mapping,
  params: (offset: "none"),
)
#assert.eq(none-pad.data.len(), 6)

Position tests passed.
