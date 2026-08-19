// The entry table: constructors, tier handling, training, and validation.

#import "../../src/guide/entry.typ": (
  TIERS, check-entries, entries-bins, entries-manual, entries-of-tier,
  entries-sequence, entries-tiered, entry, entry-tiers, range-entry,
  resolve-entries, train-entries, train-range-entries,
)
#import "../../src/utils/errors.typ": enum-text, error-text, type-text

#assert.eq(TIERS, ("major", "mid", "minor"))

// A fresh entry is untrained: `frac` stays `none` until `train-entries` runs.
#let e = entry(3)
#assert.eq(e.value, 3)
#assert.eq(e.frac, none)
#assert.eq(e.label, none)
#assert.eq(e.tier, "major")

#assert.eq(entry(3, label: "three", tier: "minor").tier, "minor")

// Labels: unset, one per value, or a closure over the value.
#let plain = entries-manual((1, 2, 3))
#assert.eq(plain.len(), 3)
#assert.eq(plain.map(r => r.value), (1, 2, 3))
#assert.eq(plain.map(r => r.label), (none, none, none))

#let listed = entries-manual((1, 2), labels: ("one", "two"))
#assert.eq(listed.map(r => r.label), ("one", "two"))

#let mapped = entries-manual((1, 2), labels: v => str(v * 10))
#assert.eq(mapped.map(r => r.label), ("10", "20"))

// A tiered table merges the weights and sorts by value, so one walk covers it.
#let tiered = entries-tiered((1, 10, 100), mid: (5, 50), minor: (2, 20))
#assert.eq(tiered.map(r => r.value), (1, 2, 5, 10, 20, 50, 100))
#assert.eq(
  tiered.map(r => r.tier),
  ("major", "minor", "mid", "major", "minor", "mid", "major"),
)
#assert.eq(entry-tiers(tiered), ("major", "mid", "minor"))
#assert.eq(entries-of-tier(tiered, "mid").map(r => r.value), (5, 50))
#assert.eq(entry-tiers(plain), ("major",))

// A colour-bar sequence carries `frac` directly and no scale break behind it.
#let seq = entries-sequence(n: 5)
#assert.eq(seq.len(), 5)
#assert.eq(seq.map(r => r.frac), (0.0, 0.25, 0.5, 0.75, 1.0))
#assert.eq(seq.first().value, none)

// `n` edges give `n - 1` bins.
#let bins = entries-bins((0, 2, 5, 10))
#assert.eq(bins.len(), 3)
#assert.eq(bins.map(r => r.start), (0, 2, 5))
#assert.eq(bins.map(r => r.end), (2, 5, 10))
#assert.eq(bins.first().depth, 0)

#let named-bins = entries-bins((0, 2, 5), labels: ("low", "high"))
#assert.eq(named-bins.map(r => r.label), ("low", "high"))

// A bin label closure reads both bounds, since a bin label usually names them.
#let spanned = entries-bins((0, 2, 5), labels: (lo, hi) => (
  str(lo) + "-" + str(hi)
))
#assert.eq(spanned.map(r => r.label), ("0-2", "2-5"))

// A value listed under two tiers keeps the heavier one and is dropped from the
// lighter, so no position carries two ticks.
#let clashing = entries-tiered((1, 10), mid: (5, 10), minor: (5, 20))
#assert.eq(clashing.map(r => r.value), (1, 5, 10, 20))
#assert.eq(clashing.map(r => r.tier), ("major", "mid", "major", "minor"))

// Training maps `value` to `frac` through an injected closure, so this module
// never reaches forward to the scale stage. Reference: a linear map of the
// domain 0..10 onto 0..1, so 5 lands halfway.
#let to-frac = v => (v - 0) / (10 - 0)
#let trained = train-entries(entries-manual((0, 5, 10)), to-frac)
#assert.eq(trained.map(r => r.frac), (0.0, 0.5, 1.0))
#assert.eq(trained.map(r => r.value), (0, 5, 10))

// A sequence row has no `value`, so training leaves it alone.
#assert.eq(train-entries(seq, to-frac).map(r => r.frac), seq.map(r => r.frac))

#let trained-bins = train-range-entries(entries-bins((0, 5, 10)), to-frac)
#assert.eq(trained-bins.map(r => r.start), (0.0, 0.5))
#assert.eq(trained-bins.map(r => r.end), (0.5, 1.0))

// A resolved table passes through; a closure is called for its table.
#assert.eq(resolve-entries(plain), plain)
#assert.eq(resolve-entries(() => plain), plain)

// Validation accepts a trained table and a range table alike.
#assert.eq(check-entries(trained, "test").len(), 3)
#assert.eq(check-entries(trained-bins, "test").len(), 2)

// Rejection wording. `errors.typ` splits the message builders from the `fail-*`
// wrappers so the text is assertable without catching a panic; these pin what
// each guard says, not merely that it fires.
#assert.eq(
  enum-text("guide-entry", "tier", "huge", TIERS),
  "guide-entry: tier must be one of \"major\", \"mid\", \"minor\"; got \"huge\".",
)
#assert.eq(
  type-text(
    "guide-entry",
    "labels",
    3,
    "an array, a closure, or `auto`",
  ),
  "guide-entry: labels must be an array, a closure, or `auto`; got 3.",
)
#assert.eq(
  error-text(
    "guide-entry",
    "labels has 3 items for 2 values",
    hint: "Supply one label per value, a closure, or `auto`.",
  ),
  "guide-entry: labels has 3 items for 2 values. Supply one label per value, a closure, or `auto`.",
)
#assert.eq(
  type-text(
    "guide-entry",
    "entries",
    auto,
    "a resolved table",
    hint: "`auto` inherits from the parent composition; resolve it there.",
  ),
  "guide-entry: entries must be a resolved table; got auto. `auto` inherits from the parent composition; resolve it there.",
)

Guide-entry tests passed.
