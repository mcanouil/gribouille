///! Point at `(x, y)` plus a vertical range from `ymin` to `ymax`.

#import "../deps.typ": cetz
#import "../layer.typ": make-layer, split-aes-params
#import "../utils/aes-resolve.typ": resolve-channel
#import "../utils/types.typ": parse-number
#import "../utils/radial.typ": shift-point
#import "../theme/theme.typ": resolve-geom-colour, resolve-geom-defaults
#import "../position/dodge.typ": dodge-geometry
#import "../utils/flip.typ": project-user-point, user-axes, user-columns
#import "linerange.typ": range-line-row

#let spec = (
  reads: (
    "x",
    "y",
    "ymin",
    "ymax",
    "colour",
    "fill",
    "alpha",
    "size",
    "linewidth",
    "linetype",
  ),
  extents: none,
)

/// Pointrange layer: a marker at `(x, y)` plus a linerange from `ymin` to `ymax`.
///
/// Mapping must provide `x`, `y`, `ymin`, `ymax`. `colour` paints the range
/// line and the point outline; `fill` paints the point body.
///
/// \@category Geoms
/// \@subcategory Intervals and errors
/// \@stability stable
///
/// \@param mapping Layer-specific aesthetic mapping built with \@aes. Must map `x`, `y`, `ymin`, `ymax`.
///
/// \@param data Layer-specific dataset, or a function applied to the plot data returning the layer frame. Falls back to the plot data when `none`.
///
/// \@param size Point radius (a Typst length).
///
/// \@param stroke Line thickness (a Typst length).
///
/// \@param colour Fixed range-line colour. `auto` resolves via the colour scale.
///
/// \@param fill Fixed point body fill. `auto` resolves via the fill scale, falling back to the resolved range-line colour.
///
/// \@param alpha Opacity in `[0, 1]`.
///
/// \@param linetype Dash keyword (e.g., `"solid"`, `"dashed"`). `auto` honours the linetype scale.
///
/// \@param stat Statistical transform name. Usually `"identity"`.
///
/// \@param position Position adjustment name. Usually `"identity"`.
///
/// \@param key Legend glyph override built with a `draw-key-*` helper. `auto` picks the default for the geom.
///
/// \@param inherit-aes Whether to merge the plot-level mapping into this layer's mapping.
///
/// \@returns Layer dictionary consumed by \@plot.
///
/// \@examples Centred point with vertical range, drawn together for forest-plot
/// style summaries.
/// ```
/// //| alt: "Forest-plot style: five point markers at (x, y) with vertical ranges from lo to hi for x = 1 to 5."
/// #let d = range(1, 6).map(i => (
///   x: i,
///   y: i,
///   lo: i - 0.5,
///   hi: i + 0.5,
/// ))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", ymin: "lo", ymax: "hi"),
///   layers: (geom-pointrange(size: 3pt),),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@examples Map `colour` to a categorical column to colour both the point
/// and its range per group.
/// ```
/// //| alt: "Five point ranges along x = 1 to 5 with points and lines coloured by even/odd category via the colour aesthetic."
/// #let d = range(1, 6).map(i => (
///   x: i, y: i, lo: i - 0.5, hi: i + 0.5,
///   k: if calc.rem(i, 2) == 0 { "even" } else { "odd" },
/// ))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", ymin: "lo", ymax: "hi", colour: "k"),
///   layers: (geom-pointrange(size: 3pt),),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@geom-linerange, \@geom-errorbar, \@geom-crossbar
#let geom-pointrange(
  mapping: none,
  data: none,
  size: 2.5pt,
  stroke: auto,
  colour: auto,
  fill: auto,
  alpha: auto,
  linetype: auto,
  stat: "identity",
  position: "identity",
  key: auto,
  inherit-aes: true,
  ..args,
) = make-layer(
  "pointrange",
  mapping: mapping,
  data: data,
  params: (
    size: size,
    stroke: stroke,
    colour: colour,
    fill: fill,
    alpha: alpha,
    linetype: linetype,
  )
    + split-aes-params("geom-pointrange", args, spec.reads),
  stat: stat,
  position: position,
  key: key,
  inherit-aes: inherit-aes,
)

#let draw(layer, ctx) = {
  let mapping = (ctx.resolve-mapping)(layer)
  let data = (ctx.resolve-data)(layer)
  if mapping == none { return }
  let cols = user-columns(mapping, ctx)
  if (
    cols.x == none or cols.y == none or cols.ymin == none or cols.ymax == none
  ) { return }
  if user-axes(ctx) == none { return }

  let theme-colour = resolve-geom-colour(resolve-geom-defaults(ctx.theme))
  let dodge = dodge-geometry(ctx, layer)

  for row in data {
    let xv = row.at(cols.x, default: none)
    let mid = parse-number(row.at(cols.y, default: none))
    if xv == none or mid == none { continue }
    let p-mid = project-user-point(ctx, xv, mid)
    if p-mid == none { continue }
    let res = range-line-row(
      layer.params,
      mapping,
      ctx,
      row,
      cols.x,
      cols.ymin,
      cols.ymax,
      theme-colour,
      dodge,
      line-alpha: false,
    )
    if res == none { continue }
    res.elem
    let (cx-mid, cy-mid) = shift-point(p-mid, res.dd)
    let final-fill = resolve-channel(
      "fill",
      layer.params,
      mapping,
      ctx,
      row,
      res.colour,
    )
    let radius = resolve-channel(
      "size",
      layer.params,
      mapping,
      ctx,
      row,
      layer.params.size,
    )
    cetz.draw.circle(
      (cx-mid, cy-mid),
      radius: radius,
      fill: final-fill,
      stroke: none,
    )
  }
}
