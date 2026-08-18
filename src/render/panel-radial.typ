// Radial-panel rendering split out of `_draw-axis-and-layers`: the pre-geom
// pass draws grid circles, spokes, the outer theta arc, and theta tick
// labels; the post-geom pass draws the r-axis tick labels so filled wedges,
// lines, and points cannot mask them.

#import "../deps.typ": cetz
#import "../scale/train.typ": map-axis-data, map-break
#import "../theme/theme.typ": _text-args
#import "../utils/radial.typ": (
  THETA-LABEL-PAD, group-theta-breaks, polar-canvas, radial-arc,
)
#import "../utils/typst-markup.typ": resolve-prose
#import "../utils/aes-resolve.typ": resolve-label
#import "axis-format.typ": (
  _axis-breaks, _axis-label, _axis-tick-values, _theta-group-label,
)
#import "guides.typ": (
  _THETA-CAP-FRAC, _THETA-CAP-MAX-RAD, _THETA-MINOR-TICK-FRAC, _read-r-guide,
  _read-theta-guide,
)

// Pre-geom radial pass. `rctx` carries the enclosing panel state: `spec`,
// `outer-radial`, `x-trained`/`y-trained`, `x-disp`/`y-disp`, `ax-text`,
// `grid-radial`, `ax-line`, `show-x-labels`.
#let _draw-radial-panel(rctx) = {
  import cetz.draw: circle, content, line
  let spec = rctx.spec
  let outer-radial = rctx.outer-radial
  let x-trained = rctx.x-trained
  let y-trained = rctx.y-trained
  let _x-disp = rctx.x-disp
  let _y-disp = rctx.y-disp
  let _ax-text = rctx.ax-text
  let _grid-radial = rctx.grid-radial
  let _ax-line = rctx.ax-line
  let show-x-labels = rctx.show-x-labels

  let theta-guide = _read-theta-guide(spec)
  let theta-suppress = theta-guide != none and theta-guide.suppress
  let (cx, cy) = outer-radial.centre
  let r-max = outer-radial.r-max
  let theta-range = outer-radial.theta-range
  let r-range = outer-radial.r-range

  let (theta-trained, r-trained, theta-disp, theta-text) = if (
    outer-radial.cat-is-theta
  ) {
    (x-trained, y-trained, _x-disp, _ax-text.xb)
  } else {
    (y-trained, x-trained, _y-disp, _ax-text.yl)
  }

  if _grid-radial != none and r-trained != none {
    if r-trained.type == "continuous" {
      for b in _axis-breaks(r-trained) {
        let r = map-axis-data(r-trained, b, r-range)
        if r > 0 and r <= r-max {
          circle((cx, cy), radius: r, fill: none, stroke: _grid-radial)
        }
      }
    }
  }

  let theta-breaks = _axis-tick-values(theta-trained)

  // Full-sweep domain endpoints can land on the same canvas angle (e.g., 0
  // and 24 on a 24-hour clock both sit at 12 o'clock); group them so we
  // draw one spoke and one merged "end/start" label per shared angle.
  let theta-groups = group-theta-breaks(
    theta-breaks,
    b => map-break(theta-trained, b, theta-range),
  )

  if _grid-radial != none and theta-trained != none {
    for group in theta-groups {
      let theta = group.first().theta
      line(
        (cx, cy),
        (cx + r-max * calc.cos(theta), cy + r-max * calc.sin(theta)),
        stroke: _grid-radial,
      )
    }
  }

  // Outer axis arc plus optional minor ticks (the `guide-axis-theta`
  // guide). Spoke-only plots (no theta guide) skip this whole block.
  if theta-guide != none and not theta-suppress and _ax-line.xb != none {
    let (theta-lo, theta-hi) = (theta-range.at(0), theta-range.at(1))
    let span = calc.abs(theta-hi - theta-lo)
    let trim = if theta-guide.cap == "none" { 0 } else {
      calc.min(span * _THETA-CAP-FRAC, _THETA-CAP-MAX-RAD)
    }
    let direction = if theta-hi >= theta-lo { 1 } else { -1 }
    let arc-lo = if theta-guide.cap == "lower" or theta-guide.cap == "both" {
      theta-lo + direction * trim
    } else { theta-lo }
    let arc-hi = if theta-guide.cap == "upper" or theta-guide.cap == "both" {
      theta-hi - direction * trim
    } else { theta-hi }
    let arc-pts = radial-arc(arc-lo, arc-hi, r-max, outer-radial)
    line(..arc-pts, stroke: _ax-line.xb)

    if theta-guide.minor-ticks and theta-groups.len() >= 2 {
      let minor-r = r-max * (1 + _THETA-MINOR-TICK-FRAC)
      let prev = theta-groups.first().first().theta
      for i in range(1, theta-groups.len()) {
        let cur = theta-groups.at(i).first().theta
        let mid = (prev + cur) / 2
        line(
          polar-canvas(outer-radial, mid, r-max),
          polar-canvas(outer-radial, mid, minor-r),
          stroke: _ax-line.xb,
        )
        prev = cur
      }
    }
  }

  if (
    show-x-labels
      and theta-text.size > 0pt
      and theta-trained != none
      and not theta-suppress
  ) {
    for group in theta-groups {
      // Shared with the chrome stage, which reserves the band this lands in.
      // A `labels` callback may return `none` to drop a wrap-side break from
      // the merged label (e.g., hide "6" so a 0..6 radar shows "0", not "6/0"),
      // and a group that resolves away entirely draws nothing.
      let label-text = _theta-group-label(
        theta-trained,
        theta-disp.labels,
        theta-disp.typst-mark,
        group,
      )
      if label-text == none { continue }
      let theta = group.first().theta
      let lr = r-max + THETA-LABEL-PAD
      content(
        (cx + lr * calc.cos(theta), cy + lr * calc.sin(theta)),
        text(.._text-args(theta-text))[#resolve-prose(
          label-text,
          eval-strings: theta-text.typst,
        )],
        anchor: "center",
        angle: if theta-guide == none { 0deg } else {
          theta-guide.angle * 1deg
        },
      )
    }
  }
}

// Post-geom radial pass: r-axis tick labels. `rctx` carries `spec`,
// `outer-radial`, `x-trained`/`y-trained`, `x-disp`/`y-disp`, `ax-text`,
// `show-y-labels`.
#let _draw-radial-r-labels(rctx) = {
  import cetz.draw: content
  let spec = rctx.spec
  let outer-radial = rctx.outer-radial

  let (cx, cy) = outer-radial.centre
  let r-max = outer-radial.r-max
  let theta-range = outer-radial.theta-range
  let r-range = outer-radial.r-range
  let r-trained = if outer-radial.cat-is-theta {
    rctx.y-trained
  } else { rctx.x-trained }
  let r-disp = if outer-radial.cat-is-theta { rctx.y-disp } else { rctx.x-disp }
  let r-text = if outer-radial.cat-is-theta {
    rctx.ax-text.yl
  } else { rctx.ax-text.xb }
  if (
    rctx.show-y-labels
      and r-text.size > 0pt
      and r-trained != none
      and r-trained.type == "continuous"
      and not _read-r-guide(spec).suppress
  ) {
    let start-angle = theta-range.at(0)
    let dx = calc.cos(start-angle)
    let dy = calc.sin(start-angle)
    for (idx, b) in _axis-breaks(r-trained).enumerate() {
      let r = map-axis-data(r-trained, b, r-range)
      if r < 0 or r > r-max { continue }
      let label-text = resolve-label(
        r-disp.labels,
        b,
        idx,
        _axis-label(r-trained, b),
        typst-mark: r-disp.typst-mark,
      )
      content(
        (cx + r * dx, cy + r * dy),
        text(.._text-args(r-text))[#resolve-prose(
          label-text,
          eval-strings: r-text.typst,
        )],
        anchor: "center",
      )
    }
  }
}
