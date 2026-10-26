///! Radial coordinate system.

#import "../utils/errors.typ": fail-enum
#import "contract.typ": coord-base
#import "expand.typ": apply-expand
#import "../utils/radial.typ": polar-canvas, radial-ctx, radial-point
#import "../render/panel-radial.typ": (
  draw-radial-background, draw-radial-foreground, prepare-radial,
)

/// Radial coordinate system.
///
/// `theta = "x"` (default) distributes categories around the circle for
/// rose / radar layouts; `theta = "y"` turns stacked y values into wedges
/// for pie / donut layouts.
///
/// \@category Coord
/// \@stability stable
///
/// \@param theta Which axis is angular: `"x"` (default) or `"y"`. The radial
///   axis (the other one) automatically drops its lo-side expansion to zero
///   so bars meet at radius 0; pass an explicit `expand:` on the radial scale
///   to override.
///
/// \@param start Offset in radians from 12 o'clock for the first slice.
///
/// \@param end Offset in radians from 12 o'clock for the sweep end. `none`
///   (default) means a full sweep in the requested `direction`. On a full
///   sweep where the angular domain endpoints land on the same canvas angle,
///   the two ticks merge into a single `"end/start"` label.
///
/// \@param direction `1` (default) advances clockwise; `-1` counter-clockwise.
///
/// \@param clip `false` (default) lets marks render past the panel rectangle; `true` clips.
///
/// \@returns Coordinate dictionary consumed by \@plot.
///
/// \@examples Pie chart from a stacked column.
/// ```
/// //| alt: "Pie chart split into three wedges sized 30, 20, and 50 (kinds A, B, C) drawn from a single stacked column projected onto polar coordinates."
/// #let d = (
///   (slice: "all", value: 30, kind: "A"),
///   (slice: "all", value: 20, kind: "B"),
///   (slice: "all", value: 50, kind: "C"),
/// )
/// #plot(
///   data: d,
///   mapping: aes(x: "slice", y: "value", fill: "kind"),
///   layers: (geom-col(width: 1, position: "stack"),),
///   coord: coord-radial(theta: "y"),
///   width: 7cm,
///   height: 7cm,
/// )
/// ```
///
/// \@see \@plot, \@geom-col
#let coord-radial(
  theta: "x",
  start: 0,
  end: none,
  direction: 1,
  clip: false,
) = {
  if theta not in ("x", "y") {
    fail-enum("coord-radial", "theta", theta, ("x", "y"))
  }
  // The radial axis, the one theta does not run along: "y" for rose/radar and
  // "x" for pie. Expansion runs before trained scales exist, so it cannot
  // route through `radial-ctx`.
  let radial-axis = if theta == "x" { "y" } else { "x" }
  // The keys `radial-ctx` reads off a radial coord. `frame` closes over them
  // because the coord dict is not yet built when its closures are.
  let own = (
    theta: theta,
    start: start,
    end: end,
    direction: direction,
    clip: clip,
  )
  (
    coord-base("radial")
      + own
      + (
        train: trained => apply-expand(trained, zero-lo-axis: radial-axis),
        frame: (
          x-trained,
          y-trained,
          px-range,
          py-range,
          label-bounds: (),
          tick-cm: 0.0,
        ) => radial-ctx(
          own,
          x-trained,
          y-trained,
          px-range,
          py-range,
          label-bounds: label-bounds,
          tick-cm: tick-cm,
        ),
        prepare: prepare-radial,
        supports: geom-name => geom-name not in ("violin", "density-ridges"),
        unsupported-hint: "Draw this layer under coord-cartesian or coord-flip.",
        draw-background: draw-radial-background,
        draw-foreground: draw-radial-foreground,
        axis-range: (ctx, axis) => if axis == theta {
          ctx.radial.theta-range
        } else { ctx.radial.r-range },
        to-canvas: (ctx, u, v) => {
          let (t, r) = if ctx.radial.cat-is-theta { (u, v) } else { (v, u) }
          polar-canvas(ctx.radial, t, r)
        },
        // Kept on `radial-point` rather than the generic route, so the radial
        // float path stays the one every golden was drawn with.
        project: (ctx, xv, yv) => radial-point(xv, yv, ctx.radial),
      )
  )
}
