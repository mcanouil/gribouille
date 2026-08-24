// Out-of-range pre-pass unit tests.
//
// Exercises filter-oob, over the plans `oob-plans` resolves from a synthetic
// trained dict, against a layer pair, to cover:
//   - default "drop" removes rows whose value falls outside `limits`
//   - "squish" keeps the row and clamps the cell to the nearest limit
//   - rows without user `limits` on a scale are never touched
//   - discrete `limits` drops rows whose level is outside the set
//   - rows with unparseable values survive (treated as in-range)

#import "../../src/scale/oob.typ": filter-oob, oob-plans
#import "../../src/utils/late-binding.typ": from-theme

// Mirror `_train-entry`: when a user supplies `limits`, the trained `domain`
// is overridden to match.
#let _trained-continuous(
  limits: none,
  oob: "drop",
  view-transform: none,
  transform: "identity",
  pre-transformed: false,
) = {
  let t = (
    type: "continuous",
    domain: if limits != none { limits } else { (0, 10) },
    transform: transform,
    pre-transformed: pre-transformed,
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
  let out = filter-oob((_layer(rows),), oob-plans(trained))
  assert.eq(out.layers.at(0).data, ((v: 3), (v: 4)))
  assert.eq(out.counts.at("fill"), 2)
}

// squish keeps the row and clamps the cell value
#{
  let trained = (fill: _trained-continuous(limits: (2, 5), oob: "squish"))
  let rows = ((v: 1), (v: 3), (v: 4), (v: 8))
  let out = filter-oob((_layer(rows),), oob-plans(trained))
  assert.eq(out.layers.at(0).data, ((v: 2), (v: 3), (v: 4), (v: 5)))
  assert.eq(out.counts, (:))
}

// no user limits means the pre-pass is a no-op
#{
  let trained = (fill: _trained-continuous())
  let rows = ((v: 1), (v: 99))
  let out = filter-oob((_layer(rows),), oob-plans(trained))
  assert.eq(out.layers.at(0).data, rows)
  assert.eq(out.counts, (:))
}

// discrete limits drops rows whose level is outside the set
#{
  let trained = (fill: _trained-discrete(limits: ("a", "c")))
  let rows = ((v: "a"), (v: "b"), (v: "c"), (v: "d"))
  let out = filter-oob((_layer(rows),), oob-plans(trained))
  assert.eq(out.layers.at(0).data, ((v: "a"), (v: "c")))
  assert.eq(out.counts.at("fill"), 2)
}

// unparseable continuous values are treated as in-range
#{
  let trained = (fill: _trained-continuous(limits: (2, 5)))
  let rows = ((v: 3), (v: "abc"), (v: none))
  let out = filter-oob((_layer(rows),), oob-plans(trained))
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
  let out = filter-oob((_layer(rows),), oob-plans(trained))
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
  let out = filter-oob((_layer(rows),), oob-plans(trained))
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
  let out = filter-oob((_layer(rows),), oob-plans(trained))
  assert.eq(out.layers.at(0).data, ((v: 2), (v: 1.5), (v: 4), (v: 5)))
  assert.eq(out.counts, (:))
}

// discrete `limits` keep numeric values: a number addresses a 1-indexed
// fractional level position (see `map-discrete`), so a polygon vertex or a
// jittered point placed between levels survives; only a non-numeric value
// outside the level set drops.
#{
  let trained = (fill: _trained-discrete(limits: ("a", "b", "c")))
  let rows = ((v: "a"), (v: "d"), (v: 1.5), (v: 0.74), (v: 3))
  let out = filter-oob((_layer(rows),), oob-plans(trained))
  assert.eq(out.layers.at(0).data, ((v: "a"), (v: 1.5), (v: 0.74), (v: 3)))
  assert.eq(out.counts.at("fill"), 1)
}

// a `clip: false` layer opts out of the drop pre-pass: its out-of-limits row
// survives verbatim, while a `clip: true` sibling with the same row is dropped.
#{
  let trained = (fill: _trained-continuous(limits: (2, 5)))
  let rows = ((v: 1), (v: 3), (v: 8))
  let clipped = _layer(rows)
  let unclipped = (.._layer(rows), clip: false)
  let out = filter-oob((clipped, unclipped), oob-plans(trained))
  assert.eq(out.layers.at(0).data, ((v: 3),))
  assert.eq(out.layers.at(1).data, rows)
  assert.eq(out.counts.at("fill"), 2)
}

// two limited aesthetics on one layer keep their own rule. The pre-pass
// resolves each aesthetic once before the row walk, so a mixed pair proves the
// continuous squish and the discrete censor are not resolved against each
// other's scale.
#{
  let trained = (
    fill: _trained-continuous(limits: (2, 5), oob: "squish"),
    colour: (
      .._trained-discrete(limits: ("a", "b")),
      spec: (
        aesthetic: "colour",
        type: "discrete",
        limits: ("a", "b"),
        oob: "drop",
      ),
    ),
  )
  let layer = (
    kind: "layer",
    data: ((v: 1, g: "a"), (v: 3, g: "z"), (v: 9, g: "b")),
    mapping: (fill: "v", colour: "g"),
  )
  let out = filter-oob((layer,), oob-plans(trained))
  assert.eq(out.layers.at(0).data, ((v: 2, g: "a"), (v: 5, g: "b")))
  assert.eq(out.counts.at("colour"), 1)
  assert.eq(out.counts.at("fill", default: 0), 0)
}

// a trained scale carrying `level-index` is tested through it, and one built
// by hand without it falls back to the domain. Every other case in this file
// takes the fallback, so this one pins the indexed path.
#{
  let trained = (
    fill: (
      .._trained-discrete(limits: ("a", "b", "c")),
      level-index: (a: 0, b: 1, c: 2),
    ),
  )
  let rows = ((v: "a"), (v: "d"), (v: "c"))
  let out = filter-oob((_layer(rows),), oob-plans(trained))
  assert.eq(out.layers.at(0).data, ((v: "a"), (v: "c")))
  assert.eq(out.counts.at("fill"), 1)
}

// the warp rule itself, on a synthetic entry: a scale that names a transform
// and is not `pre-transformed` warps the cell before it tests the span, so a
// domain of `(1, 9)` is read as the stat span `(1, 3)`. A cell of 4 warps to 2
// and is in range; 16 warps to 4 and drops.
//
// The trainer never emits this shape, because `_train-entry` marks every
// `log10` and `sqrt` scale `pre-transformed` and lifts the user limits into
// stat space. The case below covers the shape a real `sqrt` scale has.
#{
  let trained = (fill: _trained-continuous(limits: (1, 9), transform: "sqrt"))
  let rows = ((v: 4), (v: 16))
  let out = filter-oob((_layer(rows),), oob-plans(trained))
  assert.eq(out.layers.at(0).data, ((v: 4),))
  assert.eq(out.counts.at("fill"), 1)
}

// the shape a real `sqrt` scale has: `pre-transformed`, with the user limits
// already lifted into stat space, so `limits: (1, 9)` reaches the pre-pass as
// the domain `(1, 3)` and the row values are warped too. The cell is tested as
// it stands, and warping it a second time would drop the row that survives.
#{
  let trained = (
    fill: _trained-continuous(
      limits: (1, 3),
      transform: "sqrt",
      pre-transformed: true,
    ),
  )
  let rows = ((v: 2), (v: 9))
  let out = filter-oob((_layer(rows),), oob-plans(trained))
  assert.eq(out.layers.at(0).data, ((v: 2),))
  assert.eq(out.counts.at("fill"), 1)
}

// squish on a transformed scale compares in stat space but clamps to a data
// space endpoint. With `sqrt` limits of `(1, 9)`, a cell of 0 warps to 0 and
// clamps to 1, and a cell of 16 warps to 4 and clamps to 9. Clamping to the
// stat-space bound instead would write 1 and 3.
#{
  let trained = (
    fill: _trained-continuous(
      limits: (1, 9),
      oob: "squish",
      transform: "sqrt",
    ),
  )
  let rows = ((v: 0), (v: 16))
  let out = filter-oob((_layer(rows),), oob-plans(trained))
  assert.eq(out.layers.at(0).data, ((v: 1), (v: 9)))
  assert.eq(out.counts, (:))
}

// empty discrete `limits` censor every named level, which is the input state a
// legend answers by drawing no guide at all. A numeric cell still survives,
// because it addresses a position rather than a level name.
#{
  let trained = (fill: _trained-discrete(limits: ()))
  let rows = ((v: "a"), (v: "b"))
  let out = filter-oob((_layer(rows),), oob-plans(trained))
  assert.eq(out.layers.at(0).data, ())
  assert.eq(out.counts.at("fill"), 2)
}

// an identity scale censors nothing, whatever `limits` it carries, so the
// pre-pass never walks a layer for it.
#{
  let trained = (
    fill: (
      type: "identity",
      domain: (0, 10),
      spec: (
        aesthetic: "fill",
        type: "identity",
        limits: (2, 5),
        oob: "drop",
      ),
    ),
  )
  let rows = ((v: 1), (v: 8))
  let out = filter-oob((_layer(rows),), oob-plans(trained))
  assert.eq(out.layers.at(0).data, rows)
  assert.eq(out.counts, (:))
}

// a layer that does not map the limited aesthetic passes through untouched.
// The pre-pass binds each aesthetic to its column once per layer, so a layer
// with nothing to bind is never walked.
#{
  let trained = (fill: _trained-continuous(limits: (2, 5)))
  let rows = ((v: 1), (v: 8))
  let layer = (kind: "layer", data: rows, mapping: (x: "v"))
  let out = filter-oob((layer,), oob-plans(trained))
  assert.eq(out.layers.at(0).data, rows)
  assert.eq(out.counts, (:))
}

// a late-bound mapping names no column yet, so the pre-pass cannot read a cell
// for it and leaves the layer alone.
#{
  let trained = (fill: _trained-continuous(limits: (2, 5)))
  let rows = ((v: 1), (v: 8))
  let layer = (kind: "layer", data: rows, mapping: (fill: from-theme("ink")))
  let out = filter-oob((layer,), oob-plans(trained))
  assert.eq(out.layers.at(0).data, rows)
  assert.eq(out.counts, (:))
}

// a drop-mode continuous scale whose domain is not a pair still filters. Only
// squish reads the endpoints, so the pre-pass must not destructure them for a
// scale that never clamps.
#{
  let trained = (
    fill: (
      type: "continuous",
      domain: (1, 5, 9),
      spec: (
        aesthetic: "fill",
        type: "continuous",
        limits: (1, 5, 9),
        oob: "drop",
      ),
      view-transform: (1, 9),
    ),
  )
  let rows = ((v: 0), (v: 4), (v: 20))
  let out = filter-oob((_layer(rows),), oob-plans(trained))
  assert.eq(out.layers.at(0).data, ((v: 4),))
  assert.eq(out.counts.at("fill"), 2)
}

// strict mode panics on the first out-of-range row. Typst has no try/catch, so
// the panic cannot be asserted here, and no example compiles it either: an
// example that panicked would fail `tools/check.sh`. The path is therefore
// uncovered, and a change to it must be checked by hand.
