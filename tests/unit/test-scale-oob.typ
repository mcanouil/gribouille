// Out-of-range pre-pass unit tests.
//
// Exercises filter-oob over a synthetic trained dict + layer pair to cover:
//   - default "drop" removes rows whose value falls outside `limits`
//   - "squish" keeps the row and clamps the cell to the nearest limit
//   - rows without user `limits` on a scale are never touched
//   - discrete `limits` drops rows whose level is outside the set
//   - rows with unparseable values survive (treated as in-range)

#import "../../src/scale/oob.typ": filter-oob

// Mirror `_train-entry`: when a user supplies `limits`, the trained `domain`
// is overridden to match.
#let _trained-continuous(limits: none, oob: "drop", view-transform: none) = {
  let t = (
    type: "continuous",
    domain: if limits != none { limits } else { (0, 10) },
    spec: (
      aesthetic: "fill",
      type: "continuous",
      limits: limits,
      oob: oob,
    ),
  )
  if view-transform != none { t.insert("view-transform", view-transform) }
  t
}

#let _trained-discrete(limits: none, oob: "drop") = (
  type: "discrete",
  domain: if limits != none { limits } else { ("a", "b", "c") },
  spec: (
    aesthetic: "fill",
    type: "discrete",
    limits: limits,
    oob: oob,
  ),
)

#let _layer(rows) = (
  kind: "layer",
  data: rows,
  mapping: (fill: "v"),
)

// drop default removes rows outside continuous limits
#{
  let trained = (fill: _trained-continuous(limits: (2, 5)))
  let rows = ((v: 1), (v: 3), (v: 4), (v: 8))
  let out = filter-oob((_layer(rows),), trained)
  assert.eq(out.layers.at(0).data, ((v: 3), (v: 4)))
  assert.eq(out.counts.at("fill"), 2)
}

// squish keeps the row and clamps the cell value
#{
  let trained = (fill: _trained-continuous(limits: (2, 5), oob: "squish"))
  let rows = ((v: 1), (v: 3), (v: 4), (v: 8))
  let out = filter-oob((_layer(rows),), trained)
  assert.eq(out.layers.at(0).data, ((v: 2), (v: 3), (v: 4), (v: 5)))
  assert.eq(out.counts, (:))
}

// no user limits means the pre-pass is a no-op
#{
  let trained = (fill: _trained-continuous())
  let rows = ((v: 1), (v: 99))
  let out = filter-oob((_layer(rows),), trained)
  assert.eq(out.layers.at(0).data, rows)
  assert.eq(out.counts, (:))
}

// discrete limits drops rows whose level is outside the set
#{
  let trained = (fill: _trained-discrete(limits: ("a", "c")))
  let rows = ((v: "a"), (v: "b"), (v: "c"), (v: "d"))
  let out = filter-oob((_layer(rows),), trained)
  assert.eq(out.layers.at(0).data, ((v: "a"), (v: "c")))
  assert.eq(out.counts.at("fill"), 2)
}

// unparseable continuous values are treated as in-range
#{
  let trained = (fill: _trained-continuous(limits: (2, 5)))
  let rows = ((v: 3), (v: "abc"), (v: none))
  let out = filter-oob((_layer(rows),), trained)
  assert.eq(out.layers.at(0).data, rows)
  assert.eq(out.counts, (:))
}

// expansion headroom: a value outside `limits` but inside the expanded
// `view-transform` survives the drop (it still maps inside the visible panel).
#{
  let trained = (
    fill: _trained-continuous(
      limits: (2, 5),
      view-transform: (1, 6),
    ),
  )
  let rows = ((v: 0.5), (v: 1.5), (v: 4), (v: 5.5), (v: 6.5))
  let out = filter-oob((_layer(rows),), trained)
  assert.eq(out.layers.at(0).data, ((v: 1.5), (v: 4), (v: 5.5)))
  assert.eq(out.counts.at("fill"), 2)
}

// expansion + squish: values beyond the expanded view clamp to the nearest
// `limits` endpoint, while in-headroom values keep their real position.
#{
  let trained = (
    fill: _trained-continuous(
      limits: (2, 5),
      oob: "squish",
      view-transform: (1, 6),
    ),
  )
  let rows = ((v: 0.5), (v: 1.5), (v: 7))
  let out = filter-oob((_layer(rows),), trained)
  assert.eq(out.layers.at(0).data, ((v: 2), (v: 1.5), (v: 5)))
  assert.eq(out.counts, (:))
}

// reversed `limits` (descending domain, axis flipped) keep an order-agnostic
// in-range test and clamp squish to the nearest endpoint in either direction.
#{
  let trained = (
    fill: _trained-continuous(
      limits: (5, 2),
      oob: "squish",
      view-transform: (6, 1),
    ),
  )
  let rows = ((v: 0.5), (v: 1.5), (v: 4), (v: 7))
  let out = filter-oob((_layer(rows),), trained)
  assert.eq(out.layers.at(0).data, ((v: 2), (v: 1.5), (v: 4), (v: 5)))
  assert.eq(out.counts, (:))
}

// strict mode panics on first OOB row. Typst has no try/catch; the panic
// path is exercised manually via examples/oob-strict-* (see PR description).
