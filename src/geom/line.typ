///! Polyline connecting observations in x order.
///!
///! Rows are sorted by x within each group, then joined with a stroked line.
///! Groups default to the combination of discrete aesthetics (colour, fill,
///! linetype) when `group` is not set explicitly.

#import "@preview/cetz:0.5.0"
#import "../scale/train.typ": map-position
#import "../utils/types.typ": parse-number
#import "../utils/palette.typ": default-linetypes

/// Line layer connecting observations in x order, one path per group.
///
/// Grouping is implicit: rows sharing the same discrete colour, fill, or
/// `group` mapping form one path. Set `group` in @aes to override when
/// you need separate lines without mapping colour.
///
/// @category Geoms
/// @stability stable
/// @since 0.1.0
///
/// @param mapping Layer-specific aesthetic mapping built with @aes. Falls back to the plot mapping when `none`.
/// @param data Layer-specific dataset. Falls back to the plot data when `none`.
/// @param stroke Line thickness (a Typst length).
/// @param colour Fixed line colour. `auto` resolves via the colour scale or a neutral default.
/// @param alpha Line opacity in `[0, 1]`.
/// @param linetype Dash keyword (e.g. `"solid"`, `"dashed"`). `auto` honours the linetype scale.
/// @param stat Statistical transform name. Usually `"identity"`.
/// @param position Position adjustment name. Usually `"identity"`.
/// @param inherit-aes Whether to merge the plot-level mapping into this layer's mapping.
///
/// @returns Layer dictionary consumed by @plot.
///
/// @example
/// ```
/// //| width: 10cm
/// //| height: 6cm
/// #let d = (
///   (x: 1, y: 2, grp: "a"),
///   (x: 2, y: 4, grp: "a"),
///   (x: 3, y: 3, grp: "a"),
///   (x: 1, y: 1, grp: "b"),
///   (x: 2, y: 2, grp: "b"),
///   (x: 3, y: 4, grp: "b"),
/// )
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", colour: "grp"),
///   layers: (geom-line(stroke: 1pt),),
/// )
/// ```
///
/// @see @geom-point, @geom-smooth, @scale-linetype, @aes
#let geom-line(
  mapping: none,
  data: none,
  stroke: 0.8pt,
  colour: auto,
  alpha: 1,
  linetype: auto,
  stat: "identity",
  position: "identity",
  inherit-aes: true,
) = (
  kind: "layer",
  geom: "line",
  mapping: mapping,
  data: data,
  params: (stroke: stroke, colour: colour, alpha: alpha, linetype: linetype),
  stat: stat,
  position: position,
  inherit-aes: inherit-aes,
)

#let _group-key(row, mapping) = {
  let keys = ()
  let group-col = mapping.at("group", default: none)
  if group-col != none {
    keys.push(str(row.at(group-col, default: "")))
  }
  for aes-name in ("colour", "fill", "linetype") {
    let col = mapping.at(aes-name, default: none)
    if col != none and col != mapping.at("x", default: none) and col != mapping.at("y", default: none) {
      keys.push(str(row.at(col, default: "")))
    }
  }
  if keys.len() == 0 { "_all" } else { keys.join("\u{1}") }
}

#let draw(layer, ctx) = {
  let mapping = (ctx.resolve-mapping)(layer)
  let data = (ctx.resolve-data)(layer)
  if mapping == none or mapping.x == none or mapping.y == none { return }
  let x-trained = ctx.trained.at("x", default: none)
  let y-trained = ctx.trained.at("y", default: none)
  if x-trained == none or y-trained == none { return }

  let colour-col = mapping.at("colour", default: none)
  let colour-trained = ctx.trained.at("colour", default: none)
  let default-colour = if layer.params.colour != auto and layer.params.colour != none {
    layer.params.colour
  } else {
    rgb("#222222")
  }

  let linetype-col = mapping.at("linetype", default: none)
  let linetype-trained = ctx.trained.at("linetype", default: none)
  let linetype-palette = if linetype-trained != none {
    if linetype-trained.at("spec", default: none) != none {
      linetype-trained.spec.at("palette", default: default-linetypes)
    } else { default-linetypes }
  } else { default-linetypes }
  let default-linetype = if layer.params.linetype != auto and layer.params.linetype != none {
    layer.params.linetype
  } else { "solid" }

  // Partition rows by group key.
  let groups = (:)
  for row in data {
    let key = _group-key(row, mapping)
    let bucket = groups.at(key, default: ())
    bucket.push(row)
    groups.insert(key, bucket)
  }

  for (key, rows) in groups.pairs() {
    // Sort by x value numerically if continuous, else by discrete index.
    let with-x = rows.map(row => {
      let xv = row.at(mapping.x, default: none)
      let xn = if x-trained.type == "continuous" {
        parse-number(xv)
      } else {
        x-trained.domain.position(v => v == str(xv))
      }
      (row: row, xn: xn)
    }).filter(p => p.xn != none).sorted(key: p => p.xn)

    let pts = ()
    for p in with-x {
      let cx = map-position(x-trained, p.row.at(mapping.x, default: none), ctx.px-range)
      let cy = map-position(y-trained, p.row.at(mapping.y, default: none), ctx.py-range)
      if cx == none or cy == none { continue }
      pts.push((cx, cy))
    }
    if pts.len() < 2 { continue }

    let colour = if colour-col != none and colour-trained != none {
      let sample = rows.first().at(colour-col, default: none)
      (ctx.resolve-colour)(colour-trained, sample, ctx.palette)
    } else { default-colour }

    let alpha = layer.params.alpha
    let final-colour = if alpha < 1 { colour.transparentize((1 - alpha) * 100%) } else { colour }

    let dash = if linetype-col != none and linetype-trained != none {
      let sample = rows.first().at(linetype-col, default: none)
      let idx = linetype-trained.domain.position(v => v == str(sample))
      if idx == none { default-linetype } else {
        linetype-palette.at(calc.rem(idx, linetype-palette.len()))
      }
    } else { default-linetype }

    cetz.draw.line(
      ..pts,
      stroke: (paint: final-colour, thickness: layer.params.stroke, dash: dash),
    )
  }
}
