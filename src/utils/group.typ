// Canonical grouping utilities shared across geoms, stats, and positions.
//
// Groups are determined by discrete aesthetics (non-numeric values or those
// forced discrete via as-factor()), following the compute-group pattern.
// The explicit "group" aesthetic always contributes regardless of value
// type.

#import "../utils/types.typ": is-native-numeric
#import "../scale/train.typ": mapping-ref-col, mapping-ref-type
#import "../utils/late-binding.typ": after-scale-source

/// Canonical set of aesthetics that may create groups, in priority order.
///
/// \@internal
#let group-aesthetics = ("group", "colour", "fill", "linetype", "shape")

// Grouping column for a mapping value: unwrap an `after-scale` marker to its
// source column (a stage's `start`) and a mapping-ref/typst-markup to its
// column. Returns `none` for any marker without a source column (a pure
// `after-scale` closure, an `after-stat` before its stat has run), which
// callers skip since it carries no grouping variable.
#let _group-col(value) = {
  let col = mapping-ref-col(after-scale-source(value))
  if type(col) == str { col } else { none }
}

/// The columns a group key reads, resolved once for a mapping.
///
/// Everything about which aesthetics can group is a property of the mapping and
/// the trained scales, so it is decided here rather than per row: a partition
/// walks every row and this walk costs seven dictionary lookups and up to seven
/// marker unwraps each time it runs.
///
/// One decision is left to the row. In data-type mode an aesthetic groups only
/// when its own cell is not numeric, so a column that is not forced discrete
/// carries `by-value: true` and the row is asked.
/// \@param mapping Aesthetic mapping (column names or `mapping-ref` dicts).
///
/// \@param trained Trained scales dict for scale-aware mode, or `none` for data-type mode.
/// \@returns Array of `(col: str, by-value: bool)`, in group-aesthetic order.
/// \@internal
#let group-plan(mapping, trained: none) = {
  let x-col = _group-col(mapping.at("x", default: none))
  let y-col = _group-col(mapping.at("y", default: none))
  let plan = ()
  for aes-name in group-aesthetics {
    let aes-val = mapping.at(aes-name, default: none)
    if aes-val == none { continue }
    let col-name = _group-col(aes-val)
    if col-name == none { continue }
    if col-name == x-col or col-name == y-col { continue }

    if aes-name == "group" {
      plan.push((col: col-name, by-value: false))
      continue
    }
    if trained != none {
      let t = trained.at(aes-name, default: none)
      if t == none or t.type != "discrete" { continue }
      plan.push((col: col-name, by-value: false))
      continue
    }
    plan.push((
      col: col-name,
      by-value: mapping-ref-type(aes-val) != "discrete",
    ))
  }
  plan
}

/// The group key one row falls under, given the plan its mapping resolved to.
/// \@param plan The array `group-plan` answered.
///
/// \@param row Row dictionary providing aesthetic cell values.
/// \@returns Group key string joining the qualifying discrete cell values, or `"_all"` when no aesthetic qualifies.
/// \@internal
#let plan-key(plan, row) = {
  let keys = ()
  for part in plan {
    // The two reads differ in their default on purpose: a missing cell is not
    // numeric, and it keys as the empty string rather than as `none`.
    if part.by-value and is-native-numeric(row.at(part.col, default: none)) {
      continue
    }
    keys.push(str(row.at(part.col, default: "")))
  }
  if keys.len() == 0 { "_all" } else { keys.join("\u{1}") }
}

/// Compute a canonical group key for a row.
///
/// Two modes:
///
/// `trained: none` (data-type mode, used by stats and positions before scale
/// training): includes an aesthetic when its cell value is non-numeric, or
/// when a `mapping-ref` annotation forces it discrete via `as-factor()`.
/// The `"group"` aesthetic is always included.
///
/// `trained: dict` (scale-aware mode, used by geoms which have `ctx.trained`):
/// includes an aesthetic only when its trained scale type is `"discrete"`.
/// The `"group"` aesthetic is always included.
///
/// Returns `"_all"` when no aesthetics qualify.
///
/// A caller that keys more than one row resolves the plan itself and calls
/// `plan-key`, because this rebuilds the plan on every call.
/// \@param row Row dictionary providing aesthetic cell values.
///
/// \@param mapping Aesthetic mapping (column names or `mapping-ref` dicts).
///
/// \@param trained Trained scales dict for scale-aware mode, or `none` for data-type mode.
/// \@returns Group key string joining the qualifying discrete cell values, or `"_all"` when no aesthetic qualifies.
/// \@internal
#let group-key(row, mapping, trained: none) = plan-key(
  group-plan(mapping, trained: trained),
  row,
)

/// Partition data into groups by the canonical group key.
///
/// Returns an array of `(key: str, data: array)` in first-appearance order.
/// `trained` is forwarded to `group-key`: pass `none` for data-type mode
/// (stats and positions) or `ctx.trained` for scale-aware mode (geoms).
/// \@param data Array of row dictionaries to partition.
///
/// \@param mapping Aesthetic mapping forwarded to `group-key`.
///
/// \@param trained Trained scales dict for scale-aware mode, or `none` for data-type mode.
/// \@returns Array of `(key: str, data: array)` pairs in first-appearance order.
/// \@internal
#let partition-by-group(data, mapping, trained: none) = {
  let plan = group-plan(mapping, trained: trained)
  // Buckets live in a plain array and are appended to in place. Reading one out
  // of a dictionary to push to it shares the array, so the push copies it, and
  // a single-bucket partition then costs a copy per row.
  let index = (:)
  let order = ()
  let buckets = ()
  for row in data {
    let key = plan-key(plan, row)
    let at = index.at(key, default: none)
    if at == none {
      at = buckets.len()
      index.insert(key, at)
      order.push(key)
      buckets.push(())
    }
    buckets.at(at).push(row)
  }
  order.enumerate().map(((i, k)) => (key: k, data: buckets.at(i)))
}

/// Bucket rows by the string form of one column's value, in first-appearance
/// order, dropping rows whose value is empty.
///
/// Shared by the per-level stats and geoms (boxplot, ydensity,
/// density-ridges) that reduce each distinct value of a discrete positional
/// column to one summary or curve. First-appearance order keeps the
/// downstream discrete scale's level ordering aligned with the input.
/// \@param data Array of row dictionaries to bucket.
///
/// \@param col Column name whose value keys the buckets.
/// \@returns Array of row-dictionary arrays, one bucket per distinct value, in first-appearance order.
/// \@internal
#let bucket-by-col(data, col) = {
  // Same in-place append as `partition-by-group`, for the same reason.
  let index = (:)
  let buckets = ()
  for row in data {
    let key = str(row.at(col, default: ""))
    if key == "" { continue }
    let at = index.at(key, default: none)
    if at == none {
      at = buckets.len()
      index.insert(key, at)
      buckets.push(())
    }
    buckets.at(at).push(row)
  }
  buckets
}

/// Return the column names for all grouping aesthetics (not x or y).
///
/// Used by the per-group stat framework to know which columns to re-inject
/// into stat output rows so group identity is preserved across the stat.
/// \@param mapping Aesthetic mapping (column names or `mapping-ref` dicts).
/// \@returns Array of grouping-aesthetic column names, excluding the x and y columns.
/// \@internal
#let group-cols(mapping) = {
  let out = ()
  let x-col = _group-col(mapping.at("x", default: none))
  let y-col = _group-col(mapping.at("y", default: none))
  for aes-name in group-aesthetics {
    let aes-val = mapping.at(aes-name, default: none)
    if aes-val == none { continue }
    let col-name = _group-col(aes-val)
    if col-name == none { continue }
    if col-name == x-col or col-name == y-col { continue }
    if not out.contains(col-name) { out.push(col-name) }
  }
  out
}

/// Copy each positional aesthetic's value into a column named after its source
/// when a grouping aesthetic reuses that same column.
///
/// `group-cols` cannot re-inject a column equal to x or y, so after an
/// aggregating stat renames the positional column to a generic key (`"x"` /
/// `"y"`), a `fill`/`colour`/... mapped to that same column would find no
/// value and resolve to the default ink with an empty guide. This exposes the
/// stat's positional value under the source column name so the (already
/// re-attached) grouping mapping resolves. The mapping is left untouched, and
/// the work runs only for the same-column reuse case.
/// \@param data Stat output rows (after compute-group recombination).
///
/// \@param input-mapping The layer's pre-stat mapping carrying the source columns.
///
/// \@param output-mapping The stat's output mapping naming the positional columns.
/// \@returns `data` with the source column added wherever a positional aesthetic is reused.
/// \@internal
#let expose-shared-positional(data, input-mapping, output-mapping) = {
  if input-mapping == none { return data }
  let new-data = data
  for axis in ("x", "y") {
    let src = _group-col(input-mapping.at(axis, default: none))
    if src == none { continue }
    let out-col = _group-col(output-mapping.at(axis, default: none))
    if out-col == none or out-col == src { continue }
    let reused = group-aesthetics.any(a => (
      _group-col(input-mapping.at(a, default: none)) == src
    ))
    if not reused { continue }
    new-data = new-data.map(row => {
      let v = row.at(out-col, default: none)
      if v == none or row.at(src, default: none) != none { return row }
      let r = row
      r.insert(src, v)
      r
    })
  }
  new-data
}
