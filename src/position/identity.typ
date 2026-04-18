///! Identity position adjustment.
///!
///! Default for most geoms: draws each row at its mapped position without
///! any offset.

/// Identity position adjustment: no offset applied to any row.
///
/// Typically set on a layer as `position: "identity"` rather than constructed
/// directly; the constructor exists for symmetry with the other positions.
///
/// @category Positions
/// @stability stable
/// @since 0.1.0
///
/// @returns Position dictionary with `name: "identity"`, consumed by @plot.
///
/// @example
/// ```
/// //| width: 10cm
/// //| height: 6cm
/// #let d = (
///   (x: 1, y: 2),
///   (x: 2, y: 4),
///   (x: 3, y: 3),
/// )
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 3pt, position: "identity"),),
/// )
/// ```
///
/// @see @position-stack, @position-dodge, @position-fill
#let position-identity() = (kind: "position", name: "identity")

#let apply(data, mapping, params: (:)) = (data: data, mapping: mapping)
