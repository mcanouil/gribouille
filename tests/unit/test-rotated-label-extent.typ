// Rotating tick labels turns their bounding box, and the margin has to
// reserve the turned box. The extent was composed from `cos` and `sin` of the
// absolute angle without taking the terms themselves absolute, so past a
// quarter turn the reservation shrank instead of growing back, went negative,
// and the labels ran off the canvas.

#import "../../lib.typ": *
#import "../../src/render/extents.typ": _x-label-depth, _y-label-width

#let approx-eq(a, b, eps: 1e-9) = calc.abs(a - b) < eps

// A quarter turn either way presents the same box as the quarter turn before
// it, mirrored, so the extents have to agree pairwise around the circle.
#let W = 3.0
#let H = 0.4
#for (a, b) in ((135, 45), (180, 0), (225, 45), (270, 90), (315, 45)) {
  assert(
    approx-eq(_x-label-depth(a, 1, W, H), _x-label-depth(b, 1, W, H)),
    message: (
      "x-label depth at "
        + str(a)
        + " degrees is "
        + repr(_x-label-depth(a, 1, W, H))
        + ", at "
        + str(b)
        + " degrees "
        + repr(_x-label-depth(b, 1, W, H))
    ),
  )
  assert(
    approx-eq(_y-label-width(a, 1, W, H), _y-label-width(b, 1, W, H)),
    message: (
      "y-label width at "
        + str(a)
        + " degrees is "
        + repr(_y-label-width(a, 1, W, H))
        + ", at "
        + str(b)
        + " degrees "
        + repr(_y-label-width(b, 1, W, H))
    ),
  )
}

// No angle reserves a negative extent, which would let the margin shrink
// below the unrotated one.
#for a in range(0, 361, step: 15) {
  assert(
    _x-label-depth(a, 1, W, H) > 0 and _y-label-width(a, 1, W, H) > 0,
    message: "extent at " + str(a) + " degrees is not positive",
  )
}

// End to end: the reserved depth is the one the labels occupy, so the plot
// fits the size it was asked for at every rotation.
#let LEVELS = ("Alpha-long-label", "Beta-long-label", "Gamma-long-label")
#let SLACK = 0.5pt

#context {
  for a in (-90, -45, -30, 0, 30, 45, 90) {
    let m = measure(plot(
      data: (k: LEVELS, v: (3, 5, 2)),
      mapping: aes(x: "k", y: "v"),
      layers: (geom-col(),),
      guides: guides(x: guide-axis(angle: a)),
      width: 8cm,
      height: 5cm,
    ))
    assert(
      m.height <= 5cm + SLACK,
      message: (
        "labels at "
          + str(a)
          + " degrees render "
          + repr(m.height)
          + " tall, asked for "
          + repr(5cm)
      ),
    )
  }
}

Rotated label extent tests passed.
