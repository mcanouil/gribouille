// Position adjustments: stack, dodge, fill.

#import "../../src/position/apply.typ": apply-position

#let df = (
  (q: "Q1", g: "A", y: 10),
  (q: "Q1", g: "B", y: 20),
  (q: "Q2", g: "A", y: 30),
  (q: "Q2", g: "B", y: 10),
)
#let mapping = (x: "q", y: "y", fill: "g")

// stack: running cumulative per x.
#let stacked = apply-position("stack", df, mapping)
#assert.eq(stacked.data.at(0).ymin, 0)
#assert.eq(stacked.data.at(0).ymax, 10)
#assert.eq(stacked.data.at(1).ymin, 10)
#assert.eq(stacked.data.at(1).ymax, 30)
#assert.eq(stacked.mapping.ymin, "ymin")
#assert.eq(stacked.mapping.ymax, "ymax")

// fill: normalised per x.
#let filled = apply-position("fill", df, mapping)
#assert.eq(filled.data.at(0).ymin, 0.0)
#assert.eq(filled.data.at(0).ymax, 10.0 / 30.0)
#assert.eq(filled.data.at(1).ymax, 1.0)
#assert.eq(filled.data.at(2).ymax, 30.0 / 40.0)

// dodge: offsets + n per row.
#let dodged = apply-position("dodge", df, mapping)
#assert.eq(dodged.data.at(0)._dodge-n, 2)
#assert.eq(dodged.data.at(0)._dodge-offset, -0.25)
#assert.eq(dodged.data.at(1)._dodge-offset, 0.25)

// identity: pass-through.
#let id = apply-position("identity", df, mapping)
#assert.eq(id.data, df)
#assert.eq(id.mapping, mapping)

Position tests passed.
