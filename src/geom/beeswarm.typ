#import "point.typ": geom-point

///! Point wrapper that defaults `position` to `"beeswarm"`.
///!
///! Sugar for a scatter of per-group observations arranged into a
///! deterministic density-shaped swarm; equivalent to
///! `geom-point(position: position-beeswarm())`.

/// Beeswarm layer: points offset sideways into a density-shaped swarm.
///
/// Mapping must provide `x` and `y`. Offsets apply to numeric x positions;
/// force a discrete column through the swarm by mapping it
/// with \@as-factor. Customise `width` or `adjust` by passing
/// `position: position-beeswarm(...)`.
///
/// \@category Geoms
/// \@subcategory Points
/// \@stability stable
/// \@since 0.5.0
///
/// \@param mapping Layer-specific aesthetic mapping built with \@aes. Must map `x` and `y`.
///
/// \@param data Layer-specific dataset, or a function applied to the plot data returning the layer frame. Falls back to the plot data when `none`.
///
/// \@param size Marker size (a Typst length). `auto` resolves via the size scale.
///
/// \@param colour Fixed marker colour. `auto` resolves via the colour scale.
///
/// \@param fill Fixed marker fill for fillable shapes. `auto` resolves via the fill scale.
///
/// \@param stroke Marker outline thickness. `auto` honours the stroke aesthetic.
///
/// \@param alpha Marker opacity in `[0, 1]`.
///
/// \@param shape Marker shape keyword or literal glyph. `auto` honours the shape scale.
///
/// \@param stat Statistical transform name. Usually `"identity"`.
///
/// \@param position Position adjustment. Defaults to `"beeswarm"`.
///
/// \@param key Legend glyph override built with a `draw-key-*` helper. `auto` picks the default for the geom.
///
/// \@param inherit-aes Whether to merge the plot-level mapping into this layer's mapping.
///
/// \@returns Layer dictionary consumed by \@plot.
///
/// \@examples Swarms of two shifted samples over a discrete axis.
/// ```
/// //| alt: "Beeswarm chart with groups a, b on the x-axis and values on the y-axis; each group's points spread sideways into a violin-shaped swarm, wider where values cluster."
/// #let d = ()
/// #for grp in ("a", "b") {
///   for i in range(0, 40) {
///     d.push((grp: grp, y: calc.sin(i * 0.7) * 2 + (if grp == "b" { 4 } else { 0 })))
///   }
/// }
/// #plot(
///   data: d,
///   mapping: aes(x: as-factor("grp"), y: "y"),
///   layers: (geom-beeswarm(size: 2pt),),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@position-beeswarm, \@geom-jitter, \@geom-violin
#let geom-beeswarm(
  mapping: none,
  data: none,
  size: auto,
  colour: auto,
  fill: auto,
  stroke: auto,
  alpha: auto,
  shape: auto,
  stat: "identity",
  position: "beeswarm",
  key: auto,
  inherit-aes: true,
  ..args,
) = geom-point(
  mapping: mapping,
  data: data,
  size: size,
  stroke: stroke,
  fill: fill,
  colour: colour,
  alpha: alpha,
  shape: shape,
  stat: stat,
  position: position,
  key: key,
  inherit-aes: inherit-aes,
  ..args,
)
