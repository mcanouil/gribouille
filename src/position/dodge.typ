///! Dodge position adjustment.
///!
///! Shifts grouped bars side by side at each x. Partitions rows by a
///! secondary discrete aesthetic (fill/colour/group) and writes dodge offsets
///! consumed by @geom-col.

/// Dodge position adjustment: place grouped bars side by side.
///
/// Typically set on a layer as `position: "dodge"` rather than constructed
/// directly; the constructor exists for symmetry with the other positions.
///
/// @category Positions
/// @stability stable
/// @since 0.1.0
///
/// @param width Total width reserved for the dodged group, as a fraction of the category width.
///
/// @returns Position dictionary with `name: "dodge"`, consumed by @plot.
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
/// )
/// #plot(
///   data: d,
///   mapping: aes(x: "q", y: "y", fill: "grp"),
///   layers: (geom-col(position: "dodge"),),
/// )
/// ```
///
/// @see @position-stack, @position-fill, @position-identity
#let position-dodge(width: 0.9) = (kind: "position", name: "dodge", width: width)

#let _group-col(mapping) = {
  for aes-name in ("fill", "colour", "group", "linetype", "shape") {
    let col = mapping.at(aes-name, default: none)
    if col == none { continue }
    if col == mapping.at("x", default: none) { continue }
    if col == mapping.at("y", default: none) { continue }
    return col
  }
  none
}

#let apply(data, mapping, params: (:)) = {
  let x-col = mapping.at("x", default: none)
  if x-col == none { return (data: data, mapping: mapping) }
  let group-col = _group-col(mapping)
  if group-col == none {
    // Nothing to dodge; fall back to identity.
    return (data: data, mapping: mapping)
  }

  // Collect group levels in order of first appearance.
  let levels = ()
  for row in data {
    let g = str(row.at(group-col, default: ""))
    if not levels.contains(g) { levels.push(g) }
  }
  let n = levels.len()
  if n <= 1 { return (data: data, mapping: mapping) }

  let out = data.map(row => {
    let g = str(row.at(group-col, default: ""))
    let idx = levels.position(v => v == g)
    if idx == none { return row }
    let off = (idx + 0.5) / n - 0.5
    let new-row = row
    new-row.insert("_dodge-offset", off)
    new-row.insert("_dodge-n", n)
    new-row
  })

  (data: out, mapping: mapping)
}
