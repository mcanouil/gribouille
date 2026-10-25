// Shared scaffolding for line/path/step. Each geom supplies `build-pts`,
// the rows -> screen points transformation that distinguishes it
// (path: input order; line: sort by x; step: sort + stair).

#import "../deps.typ": cetz
#import "../utils/aes-resolve.typ": resolve-channel
#import "../utils/arrow.typ": draw-arrow-heads
#import "../utils/level-resolve.typ": discrete-index
#import "../utils/types.typ": parse-number
#import "../utils/bin.typ": bin-x-extents
#import "../scale/train.typ": mapping-ref-col
#import "../utils/group.typ": partition-by-group
#import "../utils/radial.typ": shift-point
#import "../coord/project.typ": project-point
#import "../utils/flip.typ": user-axes, user-columns
#import "../position/dodge.typ": dodge-delta, dodge-geometry
#import "../theme/theme.typ": resolve-geom-colour, resolve-geom-defaults

// The `spec` record of line, path, and step: the draw path below reads the
// same keys for all three. Rows from stat-bin (as in `geom-freqpoly`) widen
// `x` by half a bin, so the outer bins stay inside the panel.
#let spec = (
  reads: ("x", "y", "colour", "alpha", "linewidth", "linetype"),
  extents: (params, mapping, data) => (
    x: bin-x-extents(data, mapping-ref-col(mapping.at("x", default: none))),
    y: none,
  ),
)

// Sort rows by their x value: numeric for continuous scales, domain index
// for discrete ones. Drops rows whose x value can't be resolved. Sorts by
// the user's x, which coord-flip draws vertically.
#let sort-rows-by-x(rows, mapping, ctx) = {
  let x-col = user-columns(mapping, ctx).x
  let axes = user-axes(ctx)
  if x-col == none or axes == none { return () }
  let x-trained = axes.x-trained
  rows
    .map(row => {
      let xv = row.at(x-col, default: none)
      let xn = if x-trained.type == "continuous" {
        parse-number(xv)
      } else {
        discrete-index(x-trained, xv)
      }
      (row: row, xn: xn)
    })
    .filter(p => p.xn != none)
    .sorted(key: p => p.xn)
    .map(p => p.row)
}

// Map rows to (cx, cy) screen positions via `project-point`, which routes
// through `ctx.radial` when active. Skips rows whose mapped position fails
// to resolve.
//
// `dodge` is the slot `dodge-geometry` answered for the whole layer. It is
// resolved once there and handed down because resolving it costs a pass over
// every row on a continuous category axis, and this runs once a group.
#let rows-to-points(rows, mapping, ctx, dodge) = {
  let pts = ()
  for row in rows {
    let p = project-point(
      ctx,
      row.at(mapping.x, default: none),
      row.at(mapping.y, default: none),
    )
    if p == none { continue }
    pts.push(shift-point(p, dodge-delta(dodge, row)))
  }
  pts
}

#let draw-grouped-paths(layer, ctx, build-pts) = {
  let mapping = (ctx.resolve-mapping)(layer)
  let data = (ctx.resolve-data)(layer)
  if mapping == none or mapping.x == none or mapping.y == none { return }

  // theme.geom.colour fills in for unmapped lines so a brand colour propagates;
  // resolve-channel("linewidth", ...) folds the auto/theme/per-geom-default
  // cascade for stroke thickness.
  let theme-colour = resolve-geom-colour(resolve-geom-defaults(ctx.theme))
  // All three are the layer's, not the group's: resolving the slot per group
  // would scan every row of the layer again, and passing the layer itself into
  // a per-group call carries those rows with it.
  let params = layer.params
  // One head per group, at the ends of the whole path rather than each join.
  let arrow-spec = params.at("arrow", default: none)
  let dodge = dodge-geometry(ctx, layer)

  for g in partition-by-group(data, mapping, trained: ctx.trained) {
    let rows = g.data
    let pts = build-pts(rows, params, mapping, ctx, dodge)
    if pts.len() < 2 { continue }

    let leader = rows.first()
    let final-colour = resolve-channel(
      "colour",
      params,
      mapping,
      ctx,
      leader,
      theme-colour,
    )
    let dash = resolve-channel(
      "linetype",
      params,
      mapping,
      ctx,
      leader,
      none,
    )
    let thickness = resolve-channel(
      "linewidth",
      params,
      mapping,
      ctx,
      leader,
      0.8pt,
    )
    cetz.draw.line(
      ..pts,
      stroke: (paint: final-colour, thickness: thickness, dash: dash),
    )
    draw-arrow-heads(pts, arrow-spec, final-colour, thickness)
  }
}
