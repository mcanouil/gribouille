///! Stack position adjustment.
///!
///! Cumulates y per x bucket, writing `ymin` and `ymax` per row so geoms
///! that honour them (like @geom-col) can draw the stacked segment. Groups
///! sharing the same x and discrete aesthetic are stacked in the order rows
///! appear in `data`.

#import "../utils/types.typ": parse-number

/// Stack position adjustment: cumulate y per x bucket.
///
/// Typically set on a layer as `position: "stack"` rather than constructed
/// directly; the constructor exists for symmetry with the other positions.
///
/// @category Positions
/// @stability stable
/// @since 0.1.0
///
/// @returns Position dictionary with `name: "stack"`, consumed by @plot.
///
/// @example
/// ```
/// //| width: 10cm
/// //| height: 6cm
/// #let d = (
///   (q: "Q1", grp: "a", y: 3),
///   (q: "Q1", grp: "b", y: 5),
///   (q: "Q2", grp: "a", y: 4),
///   (q: "Q2", grp: "b", y: 2),
///   (q: "Q3", grp: "a", y: 6),
///   (q: "Q3", grp: "b", y: 4),
/// )
/// #plot(
///   data: d,
///   mapping: aes(x: "q", y: "y", fill: "grp"),
///   layers: (geom-col(position: "stack"),),
/// )
/// ```
///
/// @see @position-dodge, @position-fill, @position-identity
#let position-stack() = (kind: "position", name: "stack")

#let _group-id(row, mapping) = {
  let keys = ()
  for aes-name in ("group", "fill", "colour", "linetype", "shape") {
    let col = mapping.at(aes-name, default: none)
    if col == none { continue }
    if col == mapping.at("x", default: none) { continue }
    if col == mapping.at("y", default: none) { continue }
    keys.push(str(row.at(col, default: "")))
  }
  if keys.len() == 0 { "_all" } else { keys.join("\u{1}") }
}

#let apply(data, mapping, params: (:)) = {
  let x-col = mapping.at("x", default: none)
  let y-col = mapping.at("y", default: none)
  if x-col == none or y-col == none { return (data: data, mapping: mapping) }

  // Cumulative running totals keyed by x value.
  let running = (:)
  let out = ()
  for row in data {
    let xv = row.at(x-col, default: none)
    let yv = parse-number(row.at(y-col, default: none))
    if xv == none or yv == none {
      out.push(row)
      continue
    }
    let k = str(xv)
    let prev = running.at(k, default: 0.0)
    let ymin = prev
    let ymax = prev + yv
    running.insert(k, ymax)
    let new-row = row
    new-row.insert("ymin", ymin)
    new-row.insert("ymax", ymax)
    new-row.insert(y-col, ymax)
    out.push(new-row)
  }

  let new-mapping = mapping
  new-mapping.insert("ymin", "ymin")
  new-mapping.insert("ymax", "ymax")
  (data: out, mapping: new-mapping)
}
