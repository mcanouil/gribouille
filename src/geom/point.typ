///! Scatterplot markers.
///!
///! Draws one shape per row at the `(x, y)` position from the aesthetic
///! mapping. Colour, fill, size, shape, and alpha can each be mapped or set
///! as fixed layer parameters.

#import "@preview/cetz:0.5.0"
#import "../scale/train.typ": map-position, map-discrete
#import "../utils/palette.typ": default-shapes

/// Scatterplot layer drawing a marker for each row at `(x, y)`.
///
/// Default `stat` is `"identity"` and default `position` is `"identity"`.
/// Colour, fill, shape, and alpha can be mapped via @aes or set to fixed
/// values through the layer parameters below.
///
/// @category Geoms
/// @stability stable
/// @since 0.1.0
///
/// @param mapping Layer-specific aesthetic mapping built with @aes. Falls back to the plot mapping when `none`.
/// @param data Layer-specific dataset. Falls back to the plot data when `none`.
/// @param size Marker size (a Typst length).
/// @param stroke Marker stroke; `none` means no outline.
/// @param fill Marker fill colour. `auto` resolves via the colour scale or a neutral default.
/// @param alpha Marker opacity in `[0, 1]`.
/// @param shape Marker shape keyword (e.g. `"circle"`, `"square"`, `"triangle"`). `auto` honours the shape scale.
/// @param stat Statistical transform name. Usually left at `"identity"`.
/// @param position Position adjustment name. Usually left at `"identity"`.
/// @param inherit-aes Whether to merge the plot-level mapping into this layer's mapping.
///
/// @returns Layer dictionary consumed by @plot.
///
/// @example
/// ```
/// //| width: 10cm
/// //| height: 6cm
/// #let d = (
///   (x: 1, y: 2, sp: "a"),
///   (x: 2, y: 4, sp: "b"),
///   (x: 3, y: 3, sp: "a"),
///   (x: 4, y: 5, sp: "b"),
/// )
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", colour: "sp"),
///   layers: (geom-point(size: 3pt),),
/// )
/// ```
///
/// @see @geom-line, @geom-text, @scale-shape, @aes
#let geom-point(
  mapping: none,
  data: none,
  size: 1.5pt,
  stroke: none,
  fill: auto,
  alpha: 1,
  shape: auto,
  stat: "identity",
  position: "identity",
  inherit-aes: true,
) = (
  kind: "layer",
  geom: "point",
  mapping: mapping,
  data: data,
  params: (size: size, stroke: stroke, fill: fill, alpha: alpha, shape: shape),
  stat: stat,
  position: position,
  inherit-aes: inherit-aes,
)

// Draw a single shape at `pos`. `size` is the radius.
// Circles can take a length directly (CeTZ accepts pt for `radius:`) but for
// polygonal shapes we work in canvas units (1 unit = 1 cm) and must convert
// any Typst length to that unit system.
#let _size-to-units(size) = {
  if type(size) == length { size / 1cm } else { float(size) }
}

#let _draw-shape(pos, kind, size, paint, stroke-spec) = {
  let (cx, cy) = pos
  if kind == "circle" {
    cetz.draw.circle((cx, cy), radius: size, fill: paint, stroke: stroke-spec)
    return
  }
  let r = _size-to-units(size)
  if kind == "square" {
    cetz.draw.rect(
      (cx - r, cy - r),
      (cx + r, cy + r),
      fill: paint,
      stroke: stroke-spec,
    )
  } else if kind == "triangle" {
    cetz.draw.line(
      (cx - r, cy - r),
      (cx + r, cy - r),
      (cx, cy + r),
      close: true,
      fill: paint,
      stroke: stroke-spec,
    )
  } else if kind == "triangle-down" {
    cetz.draw.line(
      (cx - r, cy + r),
      (cx + r, cy + r),
      (cx, cy - r),
      close: true,
      fill: paint,
      stroke: stroke-spec,
    )
  } else if kind == "diamond" {
    cetz.draw.line(
      (cx, cy + r),
      (cx + r, cy),
      (cx, cy - r),
      (cx - r, cy),
      close: true,
      fill: paint,
      stroke: stroke-spec,
    )
  } else if kind == "cross" {
    let s = if stroke-spec == none { (paint: paint, thickness: r / 2 * 1cm) } else { stroke-spec }
    cetz.draw.line((cx - r, cy), (cx + r, cy), stroke: s)
    cetz.draw.line((cx, cy - r), (cx, cy + r), stroke: s)
  } else if kind == "x" {
    let s = if stroke-spec == none { (paint: paint, thickness: r / 2 * 1cm) } else { stroke-spec }
    cetz.draw.line((cx - r, cy - r), (cx + r, cy + r), stroke: s)
    cetz.draw.line((cx - r, cy + r), (cx + r, cy - r), stroke: s)
  } else if kind == "star" {
    let s = if stroke-spec == none { (paint: paint, thickness: r / 2.5 * 1cm) } else { stroke-spec }
    cetz.draw.line((cx - r, cy), (cx + r, cy), stroke: s)
    cetz.draw.line((cx, cy - r), (cx, cy + r), stroke: s)
    cetz.draw.line((cx - r, cy - r), (cx + r, cy + r), stroke: s)
    cetz.draw.line((cx - r, cy + r), (cx + r, cy - r), stroke: s)
  } else {
    cetz.draw.circle((cx, cy), radius: r, fill: paint, stroke: stroke-spec)
  }
}

#let _palette-at(palette, idx) = palette.at(calc.rem(idx, palette.len()))

#let draw(layer, ctx) = {
  let mapping = (ctx.resolve-mapping)(layer)
  let data = (ctx.resolve-data)(layer)
  if mapping == none or mapping.x == none or mapping.y == none { return }
  let x-trained = ctx.trained.at("x", default: none)
  let y-trained = ctx.trained.at("y", default: none)
  if x-trained == none or y-trained == none { return }

  let colour-col = mapping.at("colour", default: none)
  let colour-trained = ctx.trained.at("colour", default: none)
  let fill-param = layer.params.fill
  let size = layer.params.size
  let alpha = layer.params.alpha

  let shape-col = mapping.at("shape", default: none)
  let shape-trained = ctx.trained.at("shape", default: none)
  let shape-palette = if shape-trained != none {
    let p = if shape-trained.at("spec", default: none) != none {
      shape-trained.spec.at("palette", default: default-shapes)
    } else { default-shapes }
    p
  } else { default-shapes }
  let default-shape-kind = if layer.params.shape != auto and layer.params.shape != none {
    layer.params.shape
  } else { "circle" }

  for row in data {
    let cx = map-position(x-trained, row.at(mapping.x, default: none), ctx.px-range)
    let cy = map-position(y-trained, row.at(mapping.y, default: none), ctx.py-range)
    if cx == none or cy == none { continue }
    let colour = if colour-col != none and colour-trained != none {
      (ctx.resolve-colour)(colour-trained, row.at(colour-col, default: none), ctx.palette)
    } else if fill-param != auto and fill-param != none {
      fill-param
    } else {
      rgb("#222222")
    }
    let fill = if alpha < 1 { colour.transparentize((1 - alpha) * 100%) } else { colour }
    let shape-kind = if shape-col != none and shape-trained != none {
      let idx = shape-trained.domain.position(v => v == str(row.at(shape-col, default: none)))
      if idx == none { default-shape-kind } else { _palette-at(shape-palette, idx) }
    } else { default-shape-kind }
    _draw-shape((cx, cy), shape-kind, size, fill, layer.params.stroke)
  }
}
