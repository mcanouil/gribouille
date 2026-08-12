// `_draw-title` paints the legend title with the whole resolved `legend-title`
// surface: its weight and font, a plain string evaluated as markup under an
// `element-typst` surface, and the surface `angle`. The box reserved for the
// guide has to follow every one of them, or the title is drawn outside the
// room the chrome kept for it.

#import "../../src/render/legend.typ": guides-for
#import "../../src/theme/defaults.typ": merge-theme
#import "../../lib.typ": element-text, element-typst, guide-legend, theme

#let TITLE = "a-legend-title-wider-than-its-keys"

#let spec-with(guides) = (
  mapping: (colour: TITLE),
  layers: (
    (
      name: "point",
      mapping: none,
      inherit-aes: true,
      params: (colour: auto, fill: auto, shape: auto),
    ),
  ),
  guides: guides,
)

#let trained = (colour: (type: "discrete", domain: ("a", "b")))

// The single guide a `legend-title` surface produces, so each case reads its
// reserved `width` and `height` straight off the record.
#let titled(el, guides: (:)) = guides-for(
  spec-with(guides),
  trained,
  theme: merge-theme(theme(legend-title: el)),
).at(0)

// A bold title advances further than a regular one at the same size.
#context {
  let regular = titled(element-text(size: 9pt, weight: "regular")).width
  let bold = titled(element-text(size: 9pt, weight: "bold")).width
  assert(
    bold > regular,
    message: "bold title reserved " + repr(bold) + ", regular " + repr(regular),
  )
}

// A themed font changes the advance widths, so the reserved width follows the
// font the title is drawn in. `DejaVu Sans Mono` ships with the Typst compiler,
// so this holds on every platform the tests run on.
#context {
  let default-font = titled(element-text(size: 9pt)).width
  let mono = titled(element-text(size: 9pt, font: "DejaVu Sans Mono")).width
  assert(
    calc.abs(mono - default-font) > 1e-6,
    message: "mono title reserved "
      + repr(mono)
      + ", the document font "
      + repr(default-font),
  )
}

// A rotated title presents its height to the box width and its width to the
// title band: turned on its side, the long title stops driving the guide width
// and starts driving the guide height.
#context {
  let upright = titled(element-text(size: 9pt))
  let turned = titled(element-text(size: 9pt, angle: 90deg))
  assert(
    turned.width < upright.width,
    message: "rotated title reserved "
      + repr(turned.width)
      + " of width, upright "
      + repr(upright.width),
  )
  assert(
    turned.height > upright.height,
    message: "rotated title reserved "
      + repr(turned.height)
      + " of height, upright "
      + repr(upright.height),
  )
}

// Under an `element-typst` surface a plain string title is drawn as evaluated
// markup, so it is measured as markup too: `#h(5cm)` reserves the 5cm it draws
// rather than the six characters it is written with.
#context {
  let markup = titled(
    element-typst(size: 9pt),
    guides: (colour: guide-legend(title: "#h(5cm)")),
  ).width
  assert(
    markup > 5.0,
    message: "evaluated title reserved " + repr(markup) + ", needs 5cm",
  )
}

legend title measurement test passed.
