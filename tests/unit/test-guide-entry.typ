// The entry table: constructors, tier handling, training, and validation.

#import "../../src/guide/entry.typ": (
  TIERS, check-entries, check-grid-entries, entries-manual, entries-of-tier,
  entries-tiered, entry, resolve-entries, train-entries,
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
#assert.eq(entries-of-tier(tiered, "mid").map(r => r.value), (5, 50))

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

// A resolved table passes through; a closure is called for its table.
#assert.eq(resolve-entries(plain), plain)
#assert.eq(resolve-entries(() => plain), plain)

// A trained table passes validation. A grid table is checked apart from it,
// because a key grid places its rows by their cell rather than by a fraction.
#assert.eq(check-entries(trained, "test").len(), 3)
#assert.eq(
  check-grid-entries(((value: "a", label: "a"),), "test").len(),
  1,
)

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
