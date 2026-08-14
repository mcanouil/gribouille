// A plot with a legend occupies exactly the width and height it was asked for.
// A legend can neither wrap nor shrink the way an axis title does: it draws the
// stack it measured, so the chrome caps it against the canvas and fails with
// the room it needs rather than shipping a figure that outgrew its box.
//
// These cases are the ones that must keep rendering. The failing side is
// verified manually, since Typst cannot catch a panic in-process; the exact
// messages are recorded at the foot of this file.

#import "../../lib.typ": *

#let d = (
  a: (1, 2, 3, 4, 5, 6),
  b: (2, 4, 3, 5, 1, 6),
  g: ("alpha", "beta", "gamma") * 2,
  f: ("u", "u", "v", "v", "w", "w"),
)

// Rounding in the chrome arithmetic is sub-point; anything larger is overflow.
#let SLACK = 0.5pt

// The axes are suppressed throughout: a tick label centred on the last break
// overhangs the panel edge, which is a separate matter from the legend and
// would blur every assertion here.
#let legended(side, width: 12cm, height: 6cm, ..args) = plot(
  data: d,
  mapping: aes(x: "a", y: "b", colour: "g"),
  layers: (geom-point(),),
  guides: guides(x: none, y: none, colour: guide-legend(position: side)),
  labels: labels(x: none, y: none),
  width: width,
  height: height,
  ..args,
)

#let fits(body, width, height, what) = {
  let m = measure(body)
  assert(
    m.width <= width + SLACK and m.height <= height + SLACK,
    message: what + " measured " + repr(m.width) + " x " + repr(m.height),
  )
}

// Every side, at a size that holds the legend: the guard reserves the slot it
// always did and nothing grows.
#context {
  for side in ("left", "right", "top", "bottom") {
    fits(legended(side), 12cm, 6cm, "a " + side + " legend")
  }
}

// `coord-fixed` shrinks the panel inside the box the margins leave, and anchors
// it bottom-left, so the centre the legend is measured from drops with it. The
// check has to follow the panel there rather than assume the whole box.
#context {
  fits(
    legended("left", width: 8cm, height: 5cm, coord: coord-fixed()),
    8cm,
    5cm,
    "a coord-fixed plot with a left legend",
  )
}

// A faceted plot hands the legend the whole panel grid, strips included, so the
// centre telescopes back to the canvas between the margins in both modes.
#context {
  fits(
    plot(
      data: d,
      mapping: aes(x: "a", y: "b", colour: "g"),
      layers: (geom-point(),),
      guides: guides(x: none, y: none, colour: guide-legend(position: "right")),
      labels: labels(x: none, y: none),
      facet: facet-wrap("f"),
      width: 12cm,
      height: 6cm,
    ),
    12cm,
    6cm,
    "a facet-wrap plot with a right legend",
  )
  fits(
    plot(
      data: d,
      mapping: aes(x: "a", y: "b", colour: "g"),
      layers: (geom-point(),),
      guides: guides(x: none, y: none, colour: guide-legend(position: "right")),
      labels: labels(x: none, y: none),
      facet: facet-grid(columns: "f"),
      width: 12cm,
      height: 6cm,
    ),
    12cm,
    6cm,
    "a facet-grid plot with a right legend",
  )
}

// An inside-panel legend reserves no chrome slot and is anchored within the
// panel, so the cap must never fire for it, however cramped the canvas.
#context {
  let m = measure(plot(
    data: d,
    mapping: aes(x: "a", y: "b", colour: "g"),
    layers: (geom-point(),),
    guides: guides(x: none, y: none, colour: guide-legend(
      position: top + left,
    )),
    labels: labels(x: none, y: none),
    width: 2cm,
    height: 1.5cm,
  ))
  assert(
    m.width > 0pt and m.height > 0pt,
    message: "an inside legend on a cramped canvas measured " + repr(m),
  )
}

// A legend the theme paints a backdrop around is capped on the block it draws,
// backdrop included, not on the guide stack alone.
#context {
  fits(
    legended(
      "right",
      theme: theme-grey(legend-background: element-rect(
        fill: rgb("#eeeeee"),
        inset: margin(top: 0.2cm, right: 0.2cm, bottom: 0.2cm, left: 0.2cm),
        outset: margin(top: 0.1cm, right: 0.1cm, bottom: 0.1cm, left: 0.1cm),
      )),
    ),
    12cm,
    6cm,
    "a legend with a painted backdrop",
  )
}

// Typst cannot catch panics in-process, so the two `fail`s the chrome raises
// are verified manually. A 1.2cm by 4cm plot with a right legend reports "the
// right legend needs 1.73 cm of width and the plot leaves it 0.85 cm"; a 6cm by
// 1.5cm plot with the same legend reports "the right legend stands 1.54 cm tall
// centred on the panel and overruns the plot by 0.2 cm".

Legend canvas fit tests passed.
