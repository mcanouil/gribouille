///! Boxed text labels at `(x, y)` positions.
///!
///! Like @geom-text but wraps the label in a rectangle with configurable
///! fill, stroke, inset, and corner radius.

#import "@preview/cetz:0.5.0"
#import "../scale/train.typ": map-position

/// Boxed text label layer reading strings from the `label` aesthetic.
///
/// One boxed text block is drawn per row at the mapped `(x, y)`. The box
/// takes its own fill, stroke, inset, and corner radius.
///
/// @category Geoms
/// @stability stable
/// @since 0.1.0
///
/// @param mapping Layer-specific aesthetic mapping built with @aes. Must map `x`, `y`, and `label`.
/// @param data Layer-specific dataset. Falls back to the plot data when `none`.
/// @param size Text size (a Typst length).
/// @param colour Text colour.
/// @param fill Box fill colour.
/// @param stroke Box stroke (length + colour).
/// @param inset Padding between text and box border (a Typst length).
/// @param radius Corner radius of the box (a Typst length).
/// @param anchor CeTZ anchor (e.g. `"center"`, `"west"`) controlling placement.
/// @param dx Horizontal offset in canvas units.
/// @param dy Vertical offset in canvas units.
/// @param inherit-aes Whether to merge the plot-level mapping into this layer's mapping.
///
/// @returns Layer dictionary consumed by @plot.
///
/// @example
/// ```
/// //| width: 10cm
/// //| height: 6cm
/// #let d = (
///   (x: 1, y: 2, name: "a"),
///   (x: 2, y: 4, name: "b"),
///   (x: 3, y: 3, name: "c"),
/// )
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", label: "name"),
///   layers: (
///     geom-point(size: 2pt),
///     geom-label(dy: 0.25),
///   ),
/// )
/// ```
///
/// @see @geom-text, @aes
#let geom-label(
  mapping: none,
  data: none,
  size: 8pt,
  colour: rgb("#222222"),
  fill: rgb("#ffffff"),
  stroke: 0.4pt + rgb("#888888"),
  inset: 2pt,
  radius: 1pt,
  anchor: "center",
  dx: 0,
  dy: 0,
  inherit-aes: true,
) = (
  kind: "layer",
  geom: "label",
  mapping: mapping,
  data: data,
  params: (
    size: size,
    colour: colour,
    fill: fill,
    stroke: stroke,
    inset: inset,
    radius: radius,
    anchor: anchor,
    dx: dx,
    dy: dy,
  ),
  stat: "identity",
  position: "identity",
  inherit-aes: inherit-aes,
)

#let draw(layer, ctx) = {
  let mapping = (ctx.resolve-mapping)(layer)
  let data = (ctx.resolve-data)(layer)
  if mapping == none or mapping.at("x", default: none) == none { return }
  if mapping.at("y", default: none) == none { return }
  let label-col = mapping.at("label", default: none)
  if label-col == none { return }
  let x-trained = ctx.trained.at("x", default: none)
  let y-trained = ctx.trained.at("y", default: none)
  if x-trained == none or y-trained == none { return }

  for row in data {
    let cx = map-position(x-trained, row.at(mapping.x, default: none), ctx.px-range)
    let cy = map-position(y-trained, row.at(mapping.y, default: none), ctx.py-range)
    if cx == none or cy == none { continue }
    let label = row.at(label-col, default: none)
    if label == none { continue }
    let body = box(
      fill: layer.params.fill,
      stroke: layer.params.stroke,
      inset: layer.params.inset,
      radius: layer.params.radius,
      text(size: layer.params.size, fill: layer.params.colour)[#label],
    )
    cetz.draw.content(
      (cx + layer.params.dx, cy + layer.params.dy),
      body,
      anchor: layer.params.anchor,
    )
  }
}
