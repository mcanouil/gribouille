///! Column extraction and explicit coercion for tidy-row data.
///!
///! Data is an array of dictionaries (one per row). `as-numeric` and
///! `as-factor` are dual-arity helpers: call them with `(data, col)` to rewrite
///! a column, or with just `(col)` to tag an aesthetic mapping so the scale
///! picks the right (continuous vs. discrete) interpretation without mutating
///! the data.

#import "utils/types.typ": parse-number

#let column(data, name) = {
  data.map(row => row.at(name, default: none))
}

#let _mapping-ref(col, type) = (
  kind: "mapping-ref",
  var: col,
  type: type,
)

/// Coerce a column to numeric, or tag an aesthetic as continuous.
///
/// Two call forms:
/// when given `(data, col)` it returns a new dataset with `col` parsed as a
/// number in every row; when given `(col)` alone it returns a mapping-ref
/// annotation that @aes accepts in place of a column name, forcing the scale
/// system to treat that channel as continuous.
///
/// @category Core
/// @stability stable
/// @since 0.1.0
///
/// @param ..args Either `(data, col)` or `(col)`. See arities.
///
/// @arity (data, col): Return a new dataset with `col` converted to numbers via `parse-number`.
/// @arity (col): Return a `mapping-ref` dict tagging `col` as continuous for @aes.
///
/// @returns New dataset (2-arg) or mapping-ref dict (1-arg).
///
/// @example
/// ```
/// //| width: 10cm
/// //| height: 6cm
/// #let raw = (
///   (x: "1", y: 2.0),
///   (x: "2", y: 4.0),
///   (x: "3", y: 9.0),
/// )
/// #let d = as-numeric(raw, "x")
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 3pt),),
/// )
/// ```
///
/// @see @as-factor, @aes
#let as-numeric(..args) = {
  let pos = args.pos()
  if pos.len() == 1 {
    return _mapping-ref(pos.at(0), "continuous")
  }
  let (data, col) = pos
  data.map(row => {
    let v = row.at(col, default: none)
    let new-row = row
    new-row.insert(col, parse-number(v))
    new-row
  })
}

/// Coerce a column to string factors, or tag an aesthetic as discrete.
///
/// Two call forms:
/// when given `(data, col)` it returns a new dataset with `col` stringified in
/// every row; when given `(col)` alone it returns a mapping-ref annotation
/// that @aes accepts in place of a column name, forcing the scale system to
/// treat that channel as discrete.
///
/// @category Core
/// @stability stable
/// @since 0.1.0
///
/// @param ..args Either `(data, col)` or `(col)`. See arities.
///
/// @arity (data, col): Return a new dataset with `col` coerced to strings (preserving `none`).
/// @arity (col): Return a `mapping-ref` dict tagging `col` as discrete for @aes.
///
/// @returns New dataset (2-arg) or mapping-ref dict (1-arg).
///
/// @example
/// ```
/// //| width: 10cm
/// //| height: 6cm
/// #let iris = (
///   (sl: 5.1, sp: 1),
///   (sl: 7.0, sp: 2),
///   (sl: 6.3, sp: 3),
/// )
/// #plot(
///   data: iris,
///   mapping: aes(x: as-factor("sp"), y: "sl", fill: as-factor("sp")),
///   layers: (geom-col(),),
/// )
/// ```
///
/// @see @as-numeric, @aes
#let as-factor(..args) = {
  let pos = args.pos()
  if pos.len() == 1 {
    return _mapping-ref(pos.at(0), "discrete")
  }
  let (data, col) = pos
  data.map(row => {
    let v = row.at(col, default: none)
    let new-row = row
    new-row.insert(col, if v == none { none } else { str(v) })
    new-row
  })
}
