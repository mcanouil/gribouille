// Shared helpers in `train.typ`: the two spellings of the stat-space warp,
// and the discrete level lookup.
//
// `_to-stat` and `to-stat-fn` state the same warp twice.
//
// `_to-stat` stays a direct two-line body because it sits on the per-value
// render path, and `to-stat-fn` captures the two fields once for a caller that
// warps many values, such as the out-of-range pre-pass. The duplication is
// deliberate, so this pins the two against each other: if one gains a branch
// and the other does not, `filter-oob` and `map-position` would disagree about
// which rows are in range, and the only symptom would be missing or wrongly
// clamped data.

#import "../../src/scale/train.typ": _to-stat, level-lookup, to-stat-fn

#let _scale(transform, pre-transformed) = (
  type: "continuous",
  domain: (1, 100),
  transform: transform,
  pre-transformed: pre-transformed,
)

// Positive throughout, since `log10` refuses anything else and the point here
// is agreement between the two spellings, not their input validation.
#let _values = (0.25, 1, 2.5, 4, 9, 100)

#for transform in ("identity", "reverse", "log10", "sqrt") {
  for pre-transformed in (false, true) {
    let t = _scale(transform, pre-transformed)
    let warp = to-stat-fn(t)
    for v in _values {
      assert.eq(
        warp(v),
        _to-stat(t, v),
        message: "to-stat-fn disagrees with _to-stat for transform "
          + transform
          + ", pre-transformed "
          + repr(pre-transformed)
          + ", value "
          + repr(v),
      )
    }
  }
}

// A scale carrying neither field takes the same defaults through both.
#{
  let t = (type: "continuous", domain: (1, 10))
  assert.eq((to-stat-fn(t))(4), _to-stat(t, 4))
}

// `level-lookup` keys by the stringified level, so a hand-built domain holding
// a non-string level answers `none` rather than failing on the key. That keeps
// the behaviour the two call sites had before they shared this helper.
#{
  let t = (type: "discrete", domain: (1, "b"))
  assert.eq(level-lookup(t).at("b", default: none), 1)
  assert.eq(level-lookup(t).at("zz", default: none), none)
  // A non-string level is reachable by its own string, which is how every
  // caller spells the lookup. Keying the index by the raw value failed
  // outright here, because a Typst dictionary key must be a string. A trained
  // scale never carries one, since user `limits` are checked and a domain from
  // data is stringified, but a hand-built dict may.
  assert.eq(level-lookup(t).at("1", default: none), 0)
}

to-stat and level-lookup tests passed.
