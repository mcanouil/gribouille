///! Count observations per level of x.
///!
///! Backing statistic for \@geom-bar. Groups rows by the x column and returns
///! one row per level with the count as y.

#import "../utils/summaries.typ": read-weight
#import "../utils/aes-resolve.typ": stat-output-mapping
#import "../utils/types.typ": NA-KEY, is-discrete-column, is-missing, level-key

/// Count statistic: one output row per distinct x level with `y = count`.
///
/// Missing x values (`none` or an empty string) are counted together as the
/// trailing `NA` level, in a row whose x is `none`, which a discrete scale
/// draws in its `NA` slot. Output rows preserve the first-seen order of x
/// levels.
///
/// \@category Stats
/// \@subcategory Summaries
/// \@stability stable
///
/// \@returns Statistic object with `name: "count"`, consumed by geom layers.
///
/// \@examples Count rows per category, drawn as bars via \@geom-bar.
/// ```
/// //| alt: "Bar chart with categories a, b, c on the x-axis and row count on the y-axis, with bar height equal to the number of observations per category."
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
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@examples Constructor form: `stat: stat-count()` is equivalent to
/// `stat: "count"` with defaults. Both forms honour `fill` grouping identically.
/// ```
/// //| alt: "Stacked bar chart with categories a, b, c on the x-axis and count on the y-axis, with bars subdivided by fill group k showing per-category subgroup counts."
/// #let d = (
///   (grp: "a", k: "x"),
///   (grp: "b", k: "x"),
///   (grp: "a", k: "y"),
///   (grp: "c", k: "x"),
///   (grp: "a", k: "y"),
/// )
/// #plot(
///   data: d,
///   mapping: aes(x: "grp", fill: "k"),
///   layers: (geom-col(stat: stat-count()),),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@geom-bar, \@stat-bin, \@stat-identity
#let stat-count() = (kind: "stat", name: "count", params: (:))

#let apply(data, mapping, params: (:)) = {
  let x-col = if mapping != none { mapping.at("x", default: none) } else {
    none
  }
  if x-col == none {
    return (
      data: (),
      mapping: stat-output-mapping(mapping, (y: "_count")),
    )
  }
  let weight-col = if mapping != none {
    mapping.at("weight", default: none)
  } else { none }
  let counts = (:)
  let order = ()
  // A missing cell is the `NA` level of a discrete axis. On a continuous axis
  // it has no position, so its row is left out of the counts.
  let x-discrete = is-discrete-column(data, x-col)
  for row in data {
    let xv = row.at(x-col, default: none)
    if is-missing(xv) and not x-discrete { continue }
    let key = level-key(xv)
    if key not in counts { order.push(key) }
    counts.insert(
      key,
      counts.at(key, default: 0) + read-weight(row, weight-col),
    )
  }
  // Use the original x column name so the per-group framework can re-inject
  // group column values without column-name mismatches. y maps to "_count"
  // rather than clobbering any existing y column.
  let rows = order.map(k => {
    let r = (:)
    r.insert(x-col, if k == NA-KEY { none } else { k })
    r.insert("_count", counts.at(k))
    r
  })
  (data: rows, mapping: stat-output-mapping(mapping, (y: "_count")))
}
