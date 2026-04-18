///! Text labels at `(x, y)` positions.
///!
///! The label string comes from the `label` aesthetic. For a boxed variant
///! with a fill and border, use @geom-label.

#import "@preview/cetz:0.5.0"
#import "../scale/train.typ": map-position

/// Text label layer reading strings from the `label` aesthetic.
///
/// One text block is drawn per row at the mapped `(x, y)` with an optional
/// pixel offset via `dx` and `dy`.
///
/// @category Geoms
/// @stability stable
/// @since 0.1.0
///
/// @param mapping Layer-specific aesthetic mapping built with @aes. Must map `x`, `y`, and `label`.
/// @param data Layer-specific dataset. Falls back to the plot data when `none`.
/// @param size Text size (a Typst length).
/// @param colour Fixed text colour. Used when no colour mapping is active.
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
///     geom-text(dy: 0.2),
///   ),
/// )
/// ```
///
/// @see @geom-label, @aes
#let geom-text(
  mapping: none,
  data: none,
  size: 8pt,
  colour: rgb("#222222"),
  anchor: "center",
  dx: 0,
  dy: 0,
  inherit-aes: true,
) = (
  kind: "layer",
  geom: "text",
  mapping: mapping,
  data: data,
  params: (
    size: size,
    colour: colour,
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

  let colour-col = mapping.at("colour", default: none)
  let colour-trained = ctx.trained.at("colour", default: none)

  for row in data {
    let cx = map-position(x-trained, row.at(mapping.x, default: none), ctx.px-range)
    let cy = map-position(y-trained, row.at(mapping.y, default: none), ctx.py-range)
    if cx == none or cy == none { continue }
    let label = row.at(label-col, default: none)
    if label == none { continue }
    let colour = if colour-col != none and colour-trained != none {
      (ctx.resolve-colour)(colour-trained, row.at(colour-col, default: none), ctx.palette)
    } else { layer.params.colour }
    cetz.draw.content(
      (cx + layer.params.dx, cy + layer.params.dy),
      text(size: layer.params.size, fill: colour)[#label],
      anchor: layer.params.anchor,
    )
  }
}
