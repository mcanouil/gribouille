///! Waffle statistic: counts to unit grid cells.
///!
///! Each group's count becomes a run of unit cells on an integer grid,
///! filled column by column from the bottom-left, groups tiling the grid
///! in first-appearance order. Pair with `geom-tile` to render.

#import "../utils/aes-resolve.typ": stat-output-mapping
#import "../utils/group.typ": group-key, partition-by-group
#import "../utils/summaries.typ": read-weight
#import "../utils/errors.typ": fail

/// Waffle statistic: turn per-group counts into unit grid cells.
///
/// Counts one cell per row, or the rounded sum of the `weight` aesthetic
/// when mapped (the pre-aggregated `(category, count)` case). Cells fill
/// the grid column-major from the bottom-left: `rows` cells stack up a
/// column, then the next column starts. Groups (usually the `fill`
/// aesthetic) occupy consecutive runs in first-appearance order, so the
/// grid reads as a whole made of parts. The stat emits integer `x`/`y`
/// centres for \@geom-tile; no input `x`/`y` mapping is needed.
///
/// \@category Stats
/// \@subcategory Distributions and summaries
/// \@stability stable
/// \@since 0.8.0
///
/// \@param rows Grid height in cells (a positive integer). Columns grow as
///   needed to hold the total count.
///
/// \@returns Statistic object with `name: "waffle"`, consumed by geom
///   layers (usually \@geom-tile).
///
/// \@examples Waffle chart of pre-aggregated counts: one square per unit,
/// coloured by status.
/// ```
/// //| alt: "Waffle chart of 77 unit squares in a 7-row grid, coloured by status: 43 complete, 22 active, 12 queued, reading column by column from the left."
/// #let d = (
///   (status: "complete", n: 43),
///   (status: "active", n: 22),
///   (status: "queued", n: 12),
/// )
/// #plot(
///   data: d,
///   mapping: aes(fill: "status", weight: "n"),
///   layers: (geom-tile(stat: stat-waffle(rows: 7), width: 0.9, height: 0.9),),
///   labels: labels(x: "", y: ""),
///   guides: guides(x: none, y: none),
///   theme: theme-void(),
///   width: 11cm,
///   height: 7cm,
/// )
/// ```
///
/// \@see \@geom-tile, \@stat-count
#let stat-waffle(rows: 10) = {
  if type(rows) != int or rows < 1 {
    fail("stat-waffle", "rows must be a positive integer, got " + repr(rows))
  }
  (kind: "stat", name: "waffle", params: (rows: rows))
}

// Panel-level setup: allocate each group a contiguous run of cell indices
// in first-appearance order, so per-group apply() knows where its run
// starts without seeing the other groups.
#let setup(data, mapping, params: (:)) = {
  if mapping == none { return params }
  let weight-col = mapping.at("weight", default: none)
  let starts = (:)
  let cursor = 0
  for g in partition-by-group(data, mapping) {
    let count = calc.round(
      g.data.map(r => read-weight(r, weight-col)).sum(default: 0),
    )
    let count = calc.max(0, int(count))
    starts.insert(g.key, (start: cursor, count: count))
    cursor += count
  }
  params + (starts: starts)
}

#let apply(data, mapping, params: (:)) = {
  let new-mapping = stat-output-mapping(mapping, (x: "x", y: "y"))
  if mapping == none or data.len() == 0 {
    return (data: (), mapping: new-mapping)
  }
  let rows = params.at("rows", default: 10)
  let starts = params.at("starts", default: (:))
  let alloc = starts.at(group-key(data.first(), mapping), default: none)
  if alloc == none or alloc.count == 0 {
    return (data: (), mapping: new-mapping)
  }
  let proto = data.first()
  let cells = range(0, alloc.count).map(j => {
    let idx = alloc.start + j
    proto + (x: calc.quo(idx, rows) + 1, y: calc.rem(idx, rows) + 1)
  })
  (data: cells, mapping: new-mapping)
}
