// A faceted plot occupies exactly the width and height it was asked for. The
// strip bands used to be a fixed cost the grid paid before the panels got
// anything, uncapped against the canvas, so a small faceted plot laid its top
// strip past the edge and the label ink ran off the side. The bands are now
// budgeted against the grid, giving up their fixed base and then the gutters,
// and the labels wrap into the panel they name.
//
// The failure, where the labels alone overflow, is verified manually: Typst
// cannot catch a panic in-process. Its wording is recorded at the foot.

#import "../../lib.typ": *
#import "../../src/render/facet.typ": _strip-band
#import "../../src/theme/defaults.typ": merge-theme
#import "../../src/theme/theme.typ": _text-style

// Rounding in the grid arithmetic is sub-point; anything larger is overflow.
#let SLACK = 0.5pt

#let short = (
  a: (1, 2, 3, 4, 5, 6),
  b: (2, 4, 3, 5, 1, 6),
  g: ("u", "v", "w") * 2,
  h: ("p", "q") * 3,
)
#let long = (
  a: (1, 2, 3, 4, 5, 6),
  b: (2, 4, 3, 5, 1, 6),
  g: ("alpha beta", "gamma delta", "epsilon eta") * 2,
)

#let fits(body, side, what) = {
  let m = measure(body)
  assert(
    m.width <= side + SLACK and m.height <= side + SLACK,
    message: what + " measured " + repr(m.width) + " x " + repr(m.height),
  )
}

// The reported sizes: a three-level facet-wrap under `theme-void()` overflowed
// at every one of these, by up to 11pt of height.
#context {
  for side in (1.5cm, 1.2cm, 1cm) {
    fits(
      plot(
        data: short,
        mapping: aes(x: "a", y: "b"),
        layers: (geom-point(),),
        theme: theme-void(),
        guides: guides(default: none),
        facet: facet-wrap("g"),
        width: side,
        height: side,
      ),
      side,
      "a facet-wrap plot " + repr(side) + " square",
    )
  }
}

// Level names wider than the panel they name: the band holds the lines they
// wrap onto rather than the label running off the side of the grid. Every word
// of these fits the panel, so they wrap; a word that does not fit is reported
// instead (see the foot of this file).
#context {
  for side in (4cm, 3cm) {
    fits(
      plot(
        data: long,
        mapping: aes(x: "a", y: "b"),
        layers: (geom-point(),),
        theme: theme-void(),
        guides: guides(default: none),
        facet: facet-wrap("g"),
        width: side,
        height: side,
      ),
      side,
      "a facet-wrap plot with long level names " + repr(side) + " square",
    )
  }
}

// facet-grid draws one band above the grid and one rotated beside it, so the
// budgets run on different axes and the row strip is bounded by the width.
#context {
  for side in (4cm, 3cm) {
    fits(
      plot(
        data: short,
        mapping: aes(x: "a", y: "b"),
        layers: (geom-point(),),
        theme: theme-void(),
        guides: guides(default: none),
        facet: facet-grid(rows: "h", columns: "g"),
        width: side,
        height: side,
      ),
      side,
      "a facet-grid plot " + repr(side) + " square",
    )
  }
}

// Free scales and a secondary axis put a band inside every cell, which is a
// cost the strips are budgeted after, not before.
#context {
  let m = measure(plot(
    data: short,
    mapping: aes(x: "a", y: "b"),
    layers: (geom-point(),),
    scales: scales(y: scale-continuous(
      secondary: sec-axis(transform: v => v * 2),
    )),
    facet: facet-wrap("g", scales: "free"),
    width: 4cm,
    height: 3cm,
  ))
  assert(
    m.height <= 3cm + SLACK,
    message: "free scales with a secondary axis grew the plot to "
      + repr(m.height),
  )
}

// A legend beside a faceted plot is centred on the panel grid, strips included,
// so budgeting the strips must not move what the chrome predicted for it.
#context {
  let m = measure(plot(
    data: short,
    mapping: aes(x: "a", y: "b", colour: "g"),
    layers: (geom-point(),),
    guides: guides(x: none, y: none, colour: guide-legend(position: "right")),
    labels: labels(x: none, y: none),
    facet: facet-grid(columns: "g"),
    width: 12cm,
    height: 6cm,
  ))
  assert(
    m.width <= 12cm + SLACK and m.height <= 6cm + SLACK,
    message: "a faceted plot with a right legend measured " + repr(m),
  )
}

// A plot with room to spare lays out exactly as it always did.
#context {
  let m = measure(plot(
    data: short,
    mapping: aes(x: "a", y: "b"),
    layers: (geom-point(),),
    facet: facet-wrap("g"),
    width: 12cm,
    height: 8cm,
  ))
  assert(
    m.width <= 12cm + SLACK and m.height <= 8cm + SLACK,
    message: "a roomy facet-wrap plot measured " + repr(m),
  )
}

// The band arithmetic on its own, away from any layout.
#context {
  let style = (strip-text: _text-style(merge-theme(none), "strip-text"))
  let labels = ("u", "v", "w")
  let natural = _strip-band(labels, style, 0.45)
  // No budget reproduces the old band: the fixed base, or the label if taller.
  assert.eq(natural.band, calc.max(0.45, natural.text))
  assert.eq(natural.alongs, (none, none, none))
  assert.eq(natural.min-width, 0.0)
  // A budget under the base but over the label buys the base back.
  let squeezed = _strip-band(labels, style, 0.45, budget: 0.4)
  assert.eq(squeezed.band, 0.4)
  assert(
    squeezed.text < 0.4,
    message: "expected the label to fit a 0.4 cm budget",
  )
  // A budget under the label stops at the label: ink is not negotiable.
  assert.eq(_strip-band(labels, style, 0.45, budget: 0.05).band, natural.text)
  // Room to spare leaves the band exactly where it was.
  assert.eq(_strip-band(labels, style, 0.45, budget: 99.0).band, natural.band)
  // A label wider than its band wraps, which makes the band thicker, and the
  // draw side is handed the box it was measured in.
  let wrapped = _strip-band(
    ("a level name far wider than its panel",),
    style,
    0.45,
    along-cm: 1.0,
  )
  assert.eq(wrapped.alongs, (1.0,))
  assert(
    wrapped.text > natural.text,
    message: "expected a wrapped label to reserve more than a single line",
  )
  // Every word of it fits the box, so it wraps into the panel and the caller's
  // check passes.
  assert(
    wrapped.min-width < 1.0,
    message: "expected every word to fit a 1 cm box",
  )
  // One word wider than the box cannot wrap into it however the label breaks,
  // so the room that word needs is reported instead.
  let unbreakable = _strip-band(
    ("alevelnamefarwiderthanitspanel",),
    style,
    0.45,
    along-cm: 1.0,
  )
  assert(
    unbreakable.min-width > 1.0,
    message: "expected an unbreakable word to overrun a 1 cm box",
  )
  // The decision is per label: a label that fits keeps its own natural width
  // even when the one beside it wraps.
  let mixed = _strip-band(
    ("u", "a level name far wider than its panel"),
    style,
    0.45,
    along-cm: 1.0,
  )
  assert.eq(mixed.alongs, (none, 1.0))
}

// Typst cannot catch panics in-process, so the `fail` this feeds is verified
// manually. A 3cm by 0.4cm plot with `facet-wrap("g", ncolumn: 1)` over three
// levels reports "the facet strips need 1.04 cm of height along a panel grid
// of 0 cm, and their labels do not fit in less". A 4cm square plot with
// `facet-wrap("g", ncolumn: 3)` over a level named
// "alevelnamefarwiderthanitspanel" reports "the facet strips have a 3.71 cm
// word that cannot wrap into the 0.63 cm the panel leaves it".

Facet strip fit tests passed.
