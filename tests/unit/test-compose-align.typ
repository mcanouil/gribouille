// compose(align-panels: true): panels are forced to a shared margin so their
// plot areas line up. The mechanism is `render-plot-deferred`'s `margin-override`
// plus the returned `margin`; this exercises both directly.

#import "../../src/plot.typ": plot
#import "../../src/aes.typ": aes
#import "../../src/geom/point.typ": geom-point
#import "../../src/render.typ": render-plot-deferred

#set page(width: auto, height: auto, margin: 0cm)

#let spec(ys) = plot(
  data: ys.map(v => (x: 1, y: v)),
  mapping: aes(x: "x", y: "y"),
  layers: (geom-point(),),
  width: 6cm,
  height: 4cm,
  as-spec: true,
)

// Narrow y labels (0..5) vs wide ones (0..1e6): the wide axis reserves a larger
// left margin, so without alignment the two panels' plot areas do not match.
#let narrow = spec((0, 5))
#let wide = spec((0, 1000000))

#context {
  let mn = render-plot-deferred(narrow).margin
  let mw = render-plot-deferred(wide).margin
  assert(
    mw.left > mn.left,
    message: "wide y labels should reserve more left margin; got "
      + repr(mn.left)
      + " vs "
      + repr(mw.left),
  )

  // Forcing the per-side maximum equalises the left margin across both panels.
  let common = (
    left: calc.max(mn.left, mw.left),
    right: calc.max(mn.right, mw.right),
    top: calc.max(mn.top, mw.top),
    bottom: calc.max(mn.bottom, mw.bottom),
  )
  let fn = render-plot-deferred(narrow, margin-override: common).margin
  let fw = render-plot-deferred(wide, margin-override: common).margin
  assert(
    fn.left == common.left and fw.left == common.left,
    message: "align-panels should force a shared left margin; got "
      + repr(fn.left)
      + " vs "
      + repr(fw.left),
  )
  assert(
    fn.bottom == common.bottom and fw.bottom == common.bottom,
    message: "align-panels should force a shared bottom margin; got "
      + repr(fn.bottom)
      + " vs "
      + repr(fw.bottom),
  )

  // A forced margin larger than the panel can hold must be clamped, never
  // inverting the plot rect: left + right and top + bottom each leave room.
  let huge = (left: 100.0, right: 100.0, top: 100.0, bottom: 100.0)
  let fc = render-plot-deferred(narrow, margin-override: huge).margin
  assert(
    fc.left + fc.right < 6,
    message: "clamp must keep horizontal plot area positive; got left "
      + repr(fc.left)
      + " + right "
      + repr(fc.right),
  )
  assert(
    fc.top + fc.bottom < 4,
    message: "clamp must keep vertical plot area positive; got top "
      + repr(fc.top)
      + " + bottom "
      + repr(fc.bottom),
  )
}

Compose align-panels test passed.
