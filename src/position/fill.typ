///! Fill position adjustment.
///!
///! Stacks bars and then normalises each x bucket so the totals sum to 1.
///! Useful for proportion plots where absolute counts don't matter.

#import "../utils/types.typ": parse-number

/// Fill position adjustment: stack and normalise each x bucket to sum = 1.
///
/// Typically set on a layer as `position: "fill"` rather than constructed
/// directly; the constructor exists for symmetry with the other positions.
///
/// @category Positions
/// @stability stable
/// @since 0.1.0
///
/// @returns Position dictionary with `name: "fill"`, consumed by @plot.
///
/// @example
/// ```
/// //| width: 10cm
/// //| height: 6cm
/// #let d = (
///   (q: "Q1", grp: "a", y: 3),
///   (q: "Q1", grp: "b", y: 7),
///   (q: "Q2", grp: "a", y: 4),
///   (q: "Q2", grp: "b", y: 6),
///   (q: "Q3", grp: "a", y: 5),
///   (q: "Q3", grp: "b", y: 5),
/// )
/// #plot(
///   data: d,
///   mapping: aes(x: "q", y: "y", fill: "grp"),
///   layers: (geom-col(position: "fill"),),
/// )
/// ```
///
/// @see @position-stack, @position-dodge, @position-identity
#let position-fill() = (kind: "position", name: "fill")

#let apply(data, mapping, params: (:)) = {
  let x-col = mapping.at("x", default: none)
  let y-col = mapping.at("y", default: none)
  if x-col == none or y-col == none { return (data: data, mapping: mapping) }

  let totals = (:)
  for row in data {
    let xv = row.at(x-col, default: none)
    let yv = parse-number(row.at(y-col, default: none))
    if xv == none or yv == none { continue }
    let k = str(xv)
    totals.insert(k, totals.at(k, default: 0.0) + yv)
  }

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
    let tot = totals.at(k, default: 1.0)
    if tot == 0 { tot = 1.0 }
    let prev = running.at(k, default: 0.0)
    let ymin = prev / tot
    let ymax = (prev + yv) / tot
    running.insert(k, prev + yv)
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
