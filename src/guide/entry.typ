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

#import "../utils/errors.typ": check, fail-enum, fail-type, quote-each

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

// A table from explicit values. `labels` is `auto` to leave every label unset
// for a later resolver, an array matching `values` one for one, or a closure
// applied to each value.
#let entries-manual(values, labels: auto, tier: "major") = {
  if type(values) != array {
    fail-type("guide-entry", "values", values, "an array")
  }
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

// A table spanning several tick weights, as a log axis draws it. Each tier
// keeps its own values; the merged table is sorted by value so a primitive can
// walk it once.
#let entries-tiered(majors, mid: (), minor: (), labels: auto) = {
  let major-rows = entries-manual(majors, labels: labels)
  let mid-rows = entries-manual(mid, tier: "mid")
  let minor-rows = entries-manual(minor, tier: "minor")
  (..major-rows, ..mid-rows, ..minor-rows).sorted(key: e => e.value)
}

// A dense sampling of the unit interval, for a continuous colour bar. There is
// no scale break behind these rows: `frac` is the sample position itself and
// `value` is left `none`, so the gizmo reads the colour straight off `frac`.
#let entries-sequence(n: 64) = {
  check(
    n >= 2,
    "guide-entry",
    "a colour-bar sequence needs at least 2 samples; got " + repr(n),
    hint: "Raise `n`.",
  )
  range(n).map(i => (
    value: none,
    frac: i / (n - 1),
    label: none,
    tier: "major",
  ))
}

// A table of bins from their edges, for a binned colour bar. `n` edges give
// `n - 1` bins, each a range entry spanning one step.
#let entries-bins(edges, labels: auto) = {
  check(
    type(edges) == array and edges.len() >= 2,
    "guide-entry",
    "bin edges need at least 2 values; got " + repr(edges),
    hint: "Supply the bin boundaries in ascending order.",
  )
  range(edges.len() - 1).map(i => range-entry(
    edges.at(i),
    edges.at(i + 1),
    label: if labels == auto { none } else if type(labels) == array {
      labels.at(i)
    } else { (labels)(edges.at(i)) },
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
