// Radial-panel rendering split out of `_draw-axis-and-layers`: the pre-geom
// pass draws grid circles, spokes, the outer theta arc, and theta tick
// labels; the post-geom pass draws the r-axis tick labels so filled wedges,
// lines, and points cannot mask them.

#import "../deps.typ": cetz
#import "../scale/train.typ": map-axis-data, map-break
#import "../theme/defaults.typ": resolve-colour
#import "../theme/theme.typ": _line-stroke, _text-args, _tick-length
#import "../utils/radial.typ": (
  THETA-LABEL-PAD, group-theta-breaks, polar-canvas, radial-arc,
)
#import "../utils/typst-markup.typ": resolve-prose
#import "../utils/aes-resolve.typ": resolve-label
#import "axis-format.typ": (
  _axis-breaks, _axis-label, _axis-tick-values, _theta-group-label,
)
#import "common.typ": _should-draw-tick
#import "guides.typ": (
  _THETA-CAP-FRAC, _THETA-CAP-MAX-RAD, _read-r-guide, _read-theta-guide,
)

// Two canvas angles are the same direction when they differ by a whole number
// of turns: a full sweep puts its first and last break on one ray.
#let _FULL-TURN-EPS = 1e-6

#let _same-angle(a, b) = {
  let turn = 2 * calc.pi
  let d = calc.rem(calc.abs(a - b), turn)
  calc.min(d, turn - d) < _FULL-TURN-EPS
}

// The theta tick marks a radial panel will draw, resolved once so the layout
// and the draw site cannot disagree. `theta-axis` is the axis the sweep runs
// along, "x" on a rose or radar and "y" on a pie, and the surfaces are read
// off it rather than off `x`: a pie's angular ticks belong to its `y` scale.
// `reach` is how far past `r-max` the longest weight that actually draws
// reaches, which is what `radial-ctx` keeps back; a blank surface, an axis
// `guides(theta: none)` suppressed, an untrained sweep, and minors nobody
// asked for all reach nothing, so none of them costs the circle any radius.
// Every condition the draw site checks is checked here, or the circle gives up
// radius for ink that never appears.
#let _theta-tick-marks(theme, theta-axis, theta-guide, theta-trained) = {
  let nothing = (
    major: none,
    major-len: 0.0,
    minor: none,
    minor-len: 0.0,
    reach: 0.0,
  )
  if theta-axis == none or theta-trained == none { return nothing }
  if theta-guide != none and theta-guide.suppress { return nothing }

  let ink = resolve-colour(theme, "ink")
  let side = if theta-axis == "x" { "x-bottom" } else { "y-left" }
  let read = surface => (
    _line-stroke(theme, surface, fallback-colour: ink),
    _tick-length(theme, surface) / 1cm,
  )

  let (major, major-len) = read("axis-ticks-" + side)
  if not _should-draw-tick(major, major-len) {
    major = none
    major-len = 0.0
  }

  let (minor, minor-len) = read("axis-ticks-minor-" + theta-axis)
  let wants-minor = theta-guide != none and theta-guide.minor-ticks
  if not (wants-minor and _should-draw-tick(minor, minor-len)) {
    minor = none
    minor-len = 0.0
  }

  (
    major: major,
    major-len: major-len,
    minor: minor,
    minor-len: minor-len,
    reach: calc.max(major-len, minor-len),
  )
}

// Which facet visibility flag governs each radial axis. A faceted panel hides
// the tick labels its neighbours already carry, and the two flags are named
// for the cartesian axes, so a `theta: "y"` pie reads them the other way
// round: its angular labels belong to `y` and its radial ones to `x`.
#let _radial-label-flags(cat-is-theta, show-x-labels, show-y-labels) = if (
  cat-is-theta
) {
  (theta: show-x-labels, r: show-y-labels)
} else {
  (theta: show-y-labels, r: show-x-labels)
}

// Pre-geom radial pass. `rctx` carries the enclosing panel state: `spec`,
// `outer-radial`, `x-trained`/`y-trained`, `x-disp`/`y-disp`, `ax-text`,
// `grid-radial`, `grid-radial-discrete`, `ax-line`, `theta-ticks`,
// `show-x-labels`, `show-y-labels`.
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
  let _grid-radial-discrete = rctx.grid-radial-discrete
  let _ax-line = rctx.ax-line
  let _theta-ticks = rctx.theta-ticks
  let show-theta-labels = _radial-label-flags(
    rctx.outer-radial.cat-is-theta,
    rctx.show-x-labels,
    rctx.show-y-labels,
  ).theta

  let theta-guide = _read-theta-guide(spec)
  let theta-suppress = theta-guide != none and theta-guide.suppress
  let (cx, cy) = outer-radial.centre
  let r-max = outer-radial.r-max
  let theta-range = outer-radial.theta-range
  let r-range = outer-radial.r-range

  // The angular axis owns the sweep, so its chrome is read off whichever
  // scale carries it: `x` on a rose or radar, `y` on a pie.
  let (theta-trained, r-trained, theta-disp, theta-text, theta-line) = if (
    outer-radial.cat-is-theta
  ) {
    (x-trained, y-trained, _x-disp, _ax-text.xb, _ax-line.xb)
  } else {
    (y-trained, x-trained, _y-disp, _ax-text.yl, _ax-line.yl)
  }

  // A discrete r scale draws its circles only when the theme sets the grid on
  // the major weight, matching the cartesian rule. The spokes below carry no
  // such gate: a radial panel with no spokes reads as an empty disc.
  let draw-r-grid = (
    _grid-radial != none
      and r-trained != none
      and (r-trained.type == "continuous" or _grid-radial-discrete)
  )
  if draw-r-grid {
    for b in _axis-tick-values(r-trained) {
      let r = map-break(r-trained, b, r-range)
      if r > 0 and r <= r-max {
        circle((cx, cy), radius: r, fill: none, stroke: _grid-radial)
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

  // Outer axis arc (the `guide-axis-theta` guide). Spoke-only plots, which
  // bind no theta guide, skip it.
  if theta-guide != none and not theta-suppress and theta-line != none {
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
    line(..arc-pts, stroke: theta-line)
  }

  // Tick marks, drawn outward from the circle into the band `radial-ctx` kept
  // back for them. `_theta-tick-marks` has already folded in every reason not
  // to draw, so a `none` weight here means the band it would have needed was
  // never taken off the radius either.
  let tick(theta, len, stroke) = line(
    polar-canvas(outer-radial, theta, r-max),
    polar-canvas(outer-radial, theta, r-max + len),
    stroke: stroke,
  )
  let sweep = theta-range.at(1) - theta-range.at(0)

  // Majors sit on the breaks, and unlike the arc they need no guide to appear.
  // A capped end is the exception: `cap` fades the arc out short of the end
  // angle, so a tick there would float in the gap the cap just opened.
  if _theta-ticks.major != none {
    let capping = if theta-guide == none { "none" } else { theta-guide.cap }
    let ends = ()
    if capping == "lower" or capping == "both" {
      ends.push(theta-range.at(0))
    }
    if capping == "upper" or capping == "both" {
      ends.push(theta-range.at(1))
    }
    for group in theta-groups {
      let theta = group.first().theta
      if ends.any(end => _same-angle(theta, end)) { continue }
      tick(theta, _theta-ticks.major-len, _theta-ticks.major)
    }
  }

  // Minors bisect each gap between majors, and are opt-in through
  // `guide-axis-theta(minor-ticks: true)`. A full turn closes the ring: its
  // last group and its first sit a gap apart like any other pair, so bisect
  // that one too rather than leaving the wrap gap bare.
  if _theta-ticks.minor != none and theta-groups.len() >= 2 {
    let angles = theta-groups.map(g => g.first().theta)
    if calc.abs(calc.abs(sweep) - 2 * calc.pi) < _FULL-TURN-EPS {
      angles.push(angles.first() + sweep)
    }
    for i in range(1, angles.len()) {
      let mid = (angles.at(i - 1) + angles.at(i)) / 2
      tick(mid, _theta-ticks.minor-len, _theta-ticks.minor)
    }
  }

  if (
    show-theta-labels
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
      let lr = r-max + _theta-ticks.reach + THETA-LABEL-PAD
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
// `show-x-labels`, `show-y-labels`.
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
  let show-r-labels = _radial-label-flags(
    outer-radial.cat-is-theta,
    rctx.show-x-labels,
    rctx.show-y-labels,
  ).r
  if (
    show-r-labels
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
