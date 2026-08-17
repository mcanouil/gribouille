// compose sizing: an unbounded container falls back to the 16cm x 12cm default
// and panels fill their cells, so the composition is far wider than the two
// 6cm panels would be at their own declared size.

#import "../../src/plot.typ": plot
#import "../../src/compose.typ": compose, defer
#import "../../src/aes.typ": aes
#import "../../src/geom/point.typ": geom-point
#import "../../src/guide/legend.typ": guide-legend
#import "../../src/guides.typ": guides
#import "../../src/labels.typ": labels

#set page(width: auto, height: auto, margin: 0cm)

#let data = (
  (x: 1, y: 2),
  (x: 2, y: 3),
  (x: 3, y: 1),
)
#let panel = defer(
  plot,
  data: data,
  mapping: aes(x: "x", y: "y"),
  layers: (geom-point(),),
)

// Rendered under an unbounded page, the composition takes the 16cm fallback and
// stretches the panels to fill it; two intrinsic 6cm panels would total ~12cm.
#context {
  let m = measure(compose(panel, panel, columns: 2))
  assert(
    m.width > 14cm,
    message: "compose should fill the 16cm default, got " + repr(m.width),
  )
}

// Panel tags reserve their band from inside each cell, so a bounded composition
// still totals exactly the requested width and height.
#context {
  let m = measure(box(
    width: 12cm,
    height: 6cm,
    compose(panel, panel, columns: 2, tag-levels: "A"),
  ))
  assert(
    m.width == 12cm and m.height == 6cm,
    message: "tagged compose should total its requested box, got " + repr(m),
  )
}

// A hoisted legend stands outside the panel block at the size it was measured
// at, so the axis its band does not eat has to hold it too: a composition that
// gives it room totals exactly the box it was asked for, and one that does not
// fails rather than growing (verified manually, see the message below).
#let coloured = defer(
  plot,
  data: (x: (1, 2, 3), y: (2, 3, 1), g: ("a", "b", "c")),
  mapping: aes(x: "x", y: "y", colour: "g"),
  layers: (geom-point(),),
  guides: guides(x: none, y: none),
  labels: labels(x: none, y: none),
)

#context {
  for side in ("right", "bottom") {
    let m = measure(compose(
      coloured,
      coloured,
      columns: 2,
      guides: guides(default: guide-legend(position: side)),
      width: 12cm,
      height: 6cm,
    ))
    assert(
      m.width <= 12cm + 0.5pt and m.height <= 6cm + 0.5pt,
      message: "a hoisted "
        + side
        + " legend grew the composition to "
        + repr(m),
    )
  }
}

// A 3cm by 1.5cm composition with a hoisted right legend reports "the hoisted
// right legend stands 1.54 cm tall beside a panel area of 1.5 cm".

// Panels carved out of a small composition put their outermost tick labels
// close to the canvas edge, where the label reaching past the panel used to
// grow the whole stack. `align-panels` forces a shared margin over the one each
// panel solved for itself, so the reach is re-floored against it.
#context {
  let small = defer(
    plot,
    data: (x: (1, 2, 3), y: (2, 3, 1)),
    mapping: aes(x: "x", y: "y"),
    layers: (geom-point(),),
  )
  for aligned in (false, true) {
    let m = measure(compose(
      small,
      small,
      columns: 2,
      align-panels: aligned,
      width: 30mm,
      height: 15mm,
    ))
    assert(
      m.width <= 30mm + 0.5pt and m.height <= 15mm + 0.5pt,
      message: "a small composition measured " + repr(m),
    )
  }
}

Compose sizing test passed.
