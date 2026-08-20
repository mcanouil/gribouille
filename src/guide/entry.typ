///! The entry table: what a guide annotates, independent of how it is drawn.
///!
///! An entry table is an array of dicts, one dict per drawn row: an axis tick,
///! a legend row, a colour-bar tick. A primitive consumes the table and knows
///! nothing about the scale that produced it, which is what lets one primitive
///! serve an axis and a legend alike.
///!
///! A standard entry carries `value` (the break in data space), `frac` (its
///! place inside the data area, 0 at one end and 1 at the other), `label`, and
///! `tier`. A range entry carries `start`, `end`, `label`, and `depth`, and
///! backs the bracket and box primitives.
///!
///! `frac` is filled by `train-entries`, which takes the mapping as a closure.
///! The scale lives downstream of this module, so the caller supplies the map
///! rather than this module reaching forward for it.

#import "../utils/errors.typ": check, fail-enum, fail-type

// The tick weights a guide draws. `major` is the labelled tick, `mid` the half
// step of a log decade, `minor` the rest. Named `tier` because `type` already
// means the trained-scale kind, and because the log-tick draw already calls
// these its tiers.
#let TIERS = ("major", "mid", "minor")

// One standard entry. `frac` stays `none` until `train-entries` fills it, so a
// table that reached a primitive untrained fails loudly rather than drawing at
// the origin.
#let entry(value, label: none, tier: "major") = {
  if not TIERS.contains(tier) {
    fail-enum("guide-entry", "tier", tier, TIERS)
  }
  (value: value, frac: none, label: label, tier: tier)
}

// One range entry. `depth` is the nesting level: 0 is the row nearest the
// panel, and each further level stacks outward.
#let range-entry(start, end, label: none, depth: 0) = (
  start: start,
  end: end,
  label: label,
  depth: depth,
)

// Reject a `labels` argument the table constructors cannot apply, so a typo
// names the guide rather than panicking inside a call to a non-function.
#let _check-labels(labels, scope) = {
  if labels == auto or type(labels) == array or type(labels) == function {
    return labels
  }
  fail-type(scope, "labels", labels, "an array, a closure, or `auto`")
}

// A table from explicit values. `labels` is `auto` to leave every label unset
// for a later resolver, an array matching `values` one for one, or a closure
// called with one value.
#let entries-manual(values, labels: auto, tier: "major") = {
  if type(values) != array {
    fail-type("guide-entry", "values", values, "an array")
  }
  let _ = _check-labels(labels, "guide-entry")
  if type(labels) == array {
    check(
      labels.len() == values.len(),
      "guide-entry",
      "labels has "
        + str(labels.len())
        + " items for "
        + str(values.len())
        + " values",
      hint: "Supply one label per value, a closure, or `auto`.",
    )
  }
  values
    .enumerate()
    .map(((i, v)) => entry(
      v,
      label: if labels == auto { none } else if type(labels) == array {
        labels.at(i)
      } else { (labels)(v) },
      tier: tier,
    ))
}

// A table spanning several tick weights, as a log axis draws it. The merged
// table is sorted by value so a primitive can walk it once.
//
// A value listed under more than one tier keeps the heaviest one and is dropped
// from the rest, because two entries at one position would draw two overlapping
// ticks of different lengths and report the value under both tiers.
#let entries-tiered(majors, mid: (), minor: (), labels: auto) = {
  let seen = majors
  let mid-kept = mid.filter(v => not seen.contains(v))
  seen = seen + mid-kept
  let minor-kept = minor.filter(v => not seen.contains(v))
  let major-rows = entries-manual(majors, labels: labels)
  let mid-rows = entries-manual(mid-kept, tier: "mid")
  let minor-rows = entries-manual(minor-kept, tier: "minor")
  (..major-rows, ..mid-rows, ..minor-rows).sorted(key: e => e.value)
}

// A dense sampling of the unit interval, for a continuous colour bar. There is
// no scale break behind these rows: `frac` is the sample position itself and
// `value` is left `none`, so the gizmo reads the colour straight off `frac`.
#let entries-sequence(n: 64) = {
  check(
    type(n) == int and n >= 2,
    "guide-entry",
    "a colour-bar sequence needs a whole number of at least 2 samples; got "
      + repr(n),
    hint: "Raise `n` to a whole number of 2 or more.",
  )
  range(n).map(i => (
    value: none,
    frac: i / (n - 1),
    label: none,
    tier: "major",
  ))
}

// A table of bins from their edges, for a binned colour bar. `n` edges give
// `n - 1` bins, each a range entry spanning one step. A `labels` closure is
// called with both bounds, because a bin label usually reads them both.
#let entries-bins(edges, labels: auto) = {
  check(
    type(edges) == array and edges.len() >= 2,
    "guide-entry",
    "bin edges need at least 2 values; got " + repr(edges),
    hint: "Supply the bin boundaries in ascending order.",
  )
  let _ = _check-labels(labels, "guide-entry")
  if type(labels) == array {
    check(
      labels.len() == edges.len() - 1,
      "guide-entry",
      "labels has "
        + str(labels.len())
        + " items for "
        + str(edges.len() - 1)
        + " bins",
      hint: "Supply one label per bin, a closure, or `auto`.",
    )
  }
  range(edges.len() - 1).map(i => range-entry(
    edges.at(i),
    edges.at(i + 1),
    label: if labels == auto { none } else if type(labels) == array {
      labels.at(i)
    } else { (labels)(edges.at(i), edges.at(i + 1)) },
  ))
}

// Resolve whatever a guide was given for its entries into a literal table.
// `auto` means inherit from the parent composition and is resolved by the
// composition, never here. A closure is called with no arguments, the caller
// having already closed over the scale it needs.
#let resolve-entries(spec, scope: "guide-entry") = {
  if spec == auto {
    fail-type(
      scope,
      "entries",
      spec,
      "a resolved table",
      hint: "`auto` inherits from the parent composition; resolve it there.",
    )
  }
  if type(spec) == array { return spec }
  if type(spec) == function { return spec() }
  fail-type(scope, "entries", spec, "an array or a closure")
}

// Fill `frac` on every standard entry by mapping its `value` through `to-frac`.
// Rows that already carry a `frac` and no `value` (a colour-bar sequence) pass
// through untouched.
#let train-entries(entries, to-frac) = entries.map(e => {
  if e.at("value", default: none) == none { return e }
  (..e, frac: (to-frac)(e.value))
})

// Fill `start` and `end` on every range entry, the range counterpart of
// `train-entries`.
#let train-range-entries(entries, to-frac) = entries.map(e => (
  ..e,
  start: (to-frac)(e.start),
  end: (to-frac)(e.end),
))

// Reject a table a primitive cannot draw. Runs at the boundary between the
// builder that produced the table and the primitive that consumes it, so a
// malformed table names the guide that built it rather than failing inside the
// draw with a missing-field panic.
#let check-entries(entries, scope) = {
  if type(entries) != array {
    fail-type(scope, "entries", entries, "an array of entry dicts")
  }
  for (i, e) in entries.enumerate() {
    if type(e) != dictionary {
      fail-type(scope, "entry " + str(i), e, "a dictionary")
    }
    let tier = e.at("tier", default: none)
    if tier != none and not TIERS.contains(tier) {
      fail-enum(scope, "entry " + str(i) + " tier", tier, TIERS)
    }
    let ranged = "start" in e and "end" in e
    check(
      ranged or "frac" in e,
      scope,
      "entry " + str(i) + " carries neither `frac` nor `start`/`end`",
      hint: "Run the table through `train-entries` before drawing it.",
    )
    if not ranged and e.frac == none {
      check(
        false,
        scope,
        "entry " + str(i) + " is untrained; its `frac` is `none`",
        hint: "Run the table through `train-entries` before drawing it.",
      )
    }
  }
  entries
}

// Reject a grid table a keys primitive cannot draw.
//
// A grid entry is placed by the cell it lands in rather than by a fraction, so
// it carries no `frac` and `check-entries` does not apply to it. What it must
// carry is the value its glyph is inked from, and the label that glyph stands
// beside, which is all the walk reads.
//
// The render stage stamps the label geometry on these rows as well, but it
// stamps it for itself: the column widths and the row offsets are built from
// those numbers before the table reaches a primitive, so they are not part of
// the contract checked here.
#let check-grid-entries(entries, scope) = {
  if type(entries) != array {
    fail-type(scope, "entries", entries, "an array of entry dicts")
  }
  for (i, e) in entries.enumerate() {
    if type(e) != dictionary {
      fail-type(scope, "entry " + str(i), e, "a dictionary")
    }
    check(
      "value" in e,
      scope,
      "entry " + str(i) + " carries no `value`",
      hint: "A key glyph is inked from the level the entry stands for.",
    )
    check(
      "label" in e,
      scope,
      "entry " + str(i) + " carries no `label`",
      hint: "Use `label: none` for a key that shows no label.",
    )
  }
  entries
}

// The distinct tiers a table uses, in draw order. Lets a ticks primitive walk
// its tiers without hard-coding which ones the table happens to carry.
#let entry-tiers(entries) = TIERS.filter(t => (
  entries.any(e => e.at("tier", default: "major") == t)
))

// Every entry of one tier.
#let entries-of-tier(entries, tier) = {
  if not TIERS.contains(tier) {
    fail-enum("guide-entry", "tier", tier, TIERS)
  }
  entries.filter(e => e.at("tier", default: "major") == tier)
}
