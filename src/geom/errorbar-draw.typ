// Shared draw path for `geom-errorbar` and `geom-errorbarh`.
//
// `axis` selects which axis the bar's length spans:
//   "y" → vertical bar (errorbar): centre column = x, span columns = ymin/ymax
//   "x" → horizontal bar (errorbarh): centre column = y, span columns = xmin/xmax
// `cap-extent` is the user's `width:` (errorbar) or `height:` (errorbarh):
// either a Typst length (cap span in panel units) or a number (data units for
// continuous centre axis, fraction of slot for discrete).

#import "../deps.typ": cetz
#import "../position/apply.typ": layer-position-name
#import "../position/dodge.typ": dodge-centre, dodge-half
#import "../utils/aes-resolve.typ": resolve-channel
#import "../utils/linetype-resolve.typ": resolve-linetype
#import "../coord/project.typ": axis-mapper, project-path
#import "../utils/band.typ": axis-band
#import "../utils/flip.typ": user-axis-key
#import "../utils/radial.typ": RADIAL-DEFAULT-CAP-HALF, radial-tangent-cap
#import "../utils/types.typ": parse-number
#import "../utils/colour-resolve.typ": apply-alpha
#import "../theme/theme.typ": resolve-geom-colour, resolve-geom-defaults

#let _draw-errorbar-axis(layer, ctx, axis, cap-extent) = {
  // Under coord-flip the mapping swap carries the span onto the other axis,
  // so an errorbar draws as a horizontal bar and an errorbarh as a vertical one.
  axis = user-axis-key(axis, ctx)
  let mapping = (ctx.resolve-mapping)(layer)
  let data = (ctx.resolve-data)(layer)
  if mapping == none { return }
  let centre-axis = if axis == "y" { "x" } else { "y" }
  let centre-col = mapping.at(centre-axis, default: none)
  let span-min-col = mapping.at(axis + "min", default: none)
  let span-max-col = mapping.at(axis + "max", default: none)
  if centre-col == none or span-min-col == none or span-max-col == none {
    return
  }
  let centre-trained = ctx.trained.at(centre-axis, default: none)
  let span-trained = ctx.trained.at(axis, default: none)
  if centre-trained == none or span-trained == none { return }

  let theme-colour = resolve-geom-colour(resolve-geom-defaults(ctx.theme))

  let extent-is-length = type(cap-extent) == length
  let half = if extent-is-length {
    (cap-extent / 1cm) / 2
  } else { cap-extent / 2 }

  let centre-range = if centre-axis == "x" { ctx.px-range } else {
    ctx.py-range
  }
  let position-name = layer-position-name(layer)
  let map-centre = axis-mapper(ctx, centre-axis)
  let map-span = axis-mapper(ctx, axis)

  for row in data {
    let raw-centre = row.at(centre-col, default: none)
    let centre-c = map-centre(raw-centre)
    let lo = parse-number(row.at(span-min-col, default: none))
    let hi = parse-number(row.at(span-max-col, default: none))
    if centre-c == none or lo == none or hi == none { continue }
    let span-lo = map-span(lo)
    let span-hi = map-span(hi)
    if span-lo == none or span-hi == none { continue }

    let (cap-lo, cap-hi) = if extent-is-length {
      (centre-c - half, centre-c + half)
    } else {
      let band = axis-band(centre-trained, raw-centre, half, centre-range)
      if band == none { (centre-c, centre-c) } else { band }
    }

    // Dodge shifts the centre and shrinks the cap by the dodge slot count.
    // Only the band-derived path has a meaningful "bucket" to dodge within;
    // a pinned Typst-length cap has no relation to the discrete slot, so
    // dodge is left as a no-op there.
    if position-name == "dodge" and not extent-is-length {
      let cap-span = cap-hi - cap-lo
      centre-c = dodge-centre(row, centre-c, cap-span)
      let half = dodge-half(row, cap-span / 2)
      cap-lo = centre-c - half
      cap-hi = centre-c + half
    }

    let colour = resolve-channel(
      "colour",
      layer.params,
      mapping,
      ctx,
      row,
      theme-colour,
    )
    let alpha = resolve-channel("alpha", layer.params, mapping, ctx, row, 1)
    let final-colour = apply-alpha(colour, alpha)
    let thickness = resolve-channel(
      "linewidth",
      layer.params,
      mapping,
      ctx,
      row,
      0.8pt,
    )

    let stroke-spec = (
      paint: final-colour,
      thickness: thickness,
      dash: resolve-linetype(layer.params, mapping, ctx, row),
    )

    if ctx.at("radial", default: none) != none {
      let pairs = if axis == "y" {
        ((raw-centre, lo), (raw-centre, hi))
      } else {
        ((lo, raw-centre), (hi, raw-centre))
      }
      let path = project-path(ctx, pairs)
      if path.len() < 2 { continue }
      cetz.draw.line(..path, stroke: stroke-spec)
      // Each cap is perpendicular to the spine at its own end: radial on an
      // arc, tangent on a spoke. A radial cap stops at the centre rather than
      // cross it.
      let cap-half = if extent-is-length { half } else {
        RADIAL-DEFAULT-CAP-HALF
      }
      let (cx, cy) = ctx.radial.centre
      for (end, next) in (
        (path.first(), path.at(1)),
        (path.last(), path.at(-2)),
      ) {
        let cap = radial-tangent-cap(end, next, cap-half)
        if cap == none { continue }
        let (sx, sy) = end
        let (nx, ny) = cap
        let tips = ((sx - nx, sy - ny), (sx + nx, sy + ny)).map(((px, py)) => {
          let crosses = (px - cx) * (sx - cx) + (py - cy) * (sy - cy) < 0
          if crosses { (cx, cy) } else { (px, py) }
        })
        cetz.draw.line(..tips, stroke: stroke-spec)
      }
      continue
    }

    if axis == "y" {
      cetz.draw.line(
        (centre-c, span-lo),
        (centre-c, span-hi),
        stroke: stroke-spec,
      )
      cetz.draw.line((cap-lo, span-lo), (cap-hi, span-lo), stroke: stroke-spec)
      cetz.draw.line((cap-lo, span-hi), (cap-hi, span-hi), stroke: stroke-spec)
    } else {
      cetz.draw.line(
        (span-lo, centre-c),
        (span-hi, centre-c),
        stroke: stroke-spec,
      )
      cetz.draw.line((span-lo, cap-lo), (span-lo, cap-hi), stroke: stroke-spec)
      cetz.draw.line((span-hi, cap-lo), (span-hi, cap-hi), stroke: stroke-spec)
    }
  }
}
