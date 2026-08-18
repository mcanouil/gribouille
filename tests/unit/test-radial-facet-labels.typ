// A faceted radial panel hides the tick labels its neighbours already carry,
// through the same `show-x-labels` / `show-y-labels` flags a cartesian panel
// uses. Those flags are named for the cartesian axes, so a `theta: "y"` pie
// has to read them by role: its angular labels belong to `y` and its radial
// ones to `x`, the opposite way round from a rose.

#import "../../src/render/panel-radial.typ": _radial-label-flags

// A rose or radar (`theta: "x"`) reads them straight through.
#{
  let flags = _radial-label-flags(true, true, false)
  assert.eq(flags.theta, true)
  assert.eq(flags.r, false)
}

// A pie (`theta: "y"`) swaps them: the sweep is on `y`.
#{
  let flags = _radial-label-flags(false, true, false)
  assert.eq(flags.theta, false)
  assert.eq(flags.r, true)
}

// A panel in the corner of a facet grid carries both sets whichever way the
// sweep runs, and an interior panel carries neither.
#{
  for cat-is-theta in (true, false) {
    let both = _radial-label-flags(cat-is-theta, true, true)
    assert(both.theta and both.r, message: "a corner panel dropped a label set")
    let neither = _radial-label-flags(cat-is-theta, false, false)
    assert(
      not neither.theta and not neither.r,
      message: "an interior panel kept a label set",
    )
  }
}

Radial facet label tests passed.
