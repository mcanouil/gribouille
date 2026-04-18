///! Count observations per level of x.
///!
///! Backing statistic for @geom-bar. Groups rows by the x column and returns
///! one row per level with the count as y.

/// Count statistic: one output row per distinct x level with `y = count`.
///
/// Empty strings and `none` x values are dropped. Output rows preserve the
/// first-seen order of x levels.
///
/// @category Stats
/// @stability stable
/// @since 0.1.0
///
/// @returns Statistic object with `name: "count"`, consumed by geom layers.
///
/// @example
/// ```
/// //| width: 10cm
/// //| height: 6cm
/// #let d = (
///   (grp: "a"),
///   (grp: "b"),
///   (grp: "a"),
///   (grp: "c"),
///   (grp: "a"),
/// )
/// #plot(
///   data: d,
///   mapping: aes(x: "grp"),
///   layers: (geom-bar(),),
/// )
/// ```
///
/// @see @geom-bar, @stat-bin, @stat-identity
#let stat-count() = (kind: "stat", name: "count")

#let apply(data, mapping, params: (:)) = {
  let x-col = if mapping != none { mapping.at("x", default: none) } else { none }
  if x-col == none { return (data: data, mapping: mapping) }
  let counts = (:)
  let order = ()
  for row in data {
    let raw = row.at(x-col, default: none)
    if raw == none { continue }
    let key = str(raw)
    if key == "" { continue }
    if not order.contains(key) { order.push(key) }
    counts.insert(key, counts.at(key, default: 0) + 1)
  }
  let rows = order.map(k => (x: k, y: counts.at(k)))
  (data: rows, mapping: (x: "x", y: "y"))
}
