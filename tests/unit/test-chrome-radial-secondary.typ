// A radial panel draws no secondary axis (`_draw-axis-and-layers` gates the
// whole secondary block on `not is-radial`), so the chrome stage must not
// reserve tick, label, gap, or title depth for one either. Reserving it
// donates panel area to a margin nothing ever draws in: an empty right margin
// for a secondary y, an empty top margin for a secondary x.

#import "../../src/coord/radial.typ": coord-radial
#import "../../src/render/chrome.typ": _chrome-margins
#import "../../src/scale/secondary.typ": sec-axis
#import "../../src/theme/defaults.typ": merge-theme

#let approx-eq(a, b, eps: 1e-6) = calc.abs(a - b) < eps

#let trained-axis(secondary) = (
  type: "continuous",
  domain: (0, 100),
  spec: (secondary: secondary),
)

// Both axes carry a named secondary, so a reservation on either side shows up
// as a non-zero extent and a fattened margin.
#let chrome-of(coord, secondary: true) = {
  let sec-x = if secondary { sec-axis(name: "Secondary x") } else { none }
  let sec-y = if secondary { sec-axis(name: "Secondary y") } else { none }
  _chrome-margins((
    spec: (mapping: none, guides: (:), coord: coord),
    theme: merge-theme(none),
    trained: (x: trained-axis(sec-x), y: trained-axis(sec-y)),
    coord: coord,
    guides: (),
    extents: (top: 0.0, right: 0.0, bottom: 0.0, left: 0.0, inside: ()),
    legend-gap: 0.0,
    width-units: 10.0,
    height-units: 8.0,
    facet-grid-mode: false,
    free-x: false,
    free-y: false,
    grid-n-rows: 1,
    grid-n-cols: 1,
    panel-trained-list: (),
    margin-override: none,
  ))
}

// Label measurement needs a known context, so every chrome call runs inside
// one.
#context {
  // Cartesian is the control: the secondary chrome is both drawn and reserved.
  let cartesian = chrome-of(none)
  assert(
    cartesian.sec-x-extent > 0,
    message: "cartesian secondary x reserves no chrome",
  )
  assert(
    cartesian.sec-y-extent > 0,
    message: "cartesian secondary y reserves no chrome",
  )

  // Radial reserves nothing, because it draws nothing.
  let radial = chrome-of(coord-radial())
  assert.eq(radial.sec-x-extent, 0.0)
  assert.eq(radial.sec-y-extent, 0.0)

  // And the margin is the one a radial plot without any secondary spec gets:
  // the panel keeps every millimetre the undrawn axis would have taken.
  let radial-plain = chrome-of(coord-radial(), secondary: false)
  for side in ("top", "right", "bottom", "left") {
    assert(
      approx-eq(radial.margin.at(side), radial-plain.margin.at(side)),
      message: (
        "radial "
          + side
          + " margin with a secondary spec is "
          + repr(radial.margin.at(side))
          + ", plain radial is "
          + repr(radial-plain.margin.at(side))
      ),
    )
  }
}

Chrome radial secondary tests passed.
