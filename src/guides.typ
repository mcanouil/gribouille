///! Plot-level guide bindings.
///!
///! Map aesthetic names to guide specs built with \@guide-legend, pass `none`
///! to hide a guide, and feed the result to \@plot via the `guides:` parameter.

#import "utils/errors.typ": fail

/// Bind guide specifications to aesthetics.
///
/// Accepts named arguments where each key is an aesthetic (e.g., `colour`,
/// `fill`) and each value is a guide spec from \@guide-legend, `none` to hide
/// that guide, or `auto` for the default. The resulting dictionary threads into
/// the plot spec and is honoured by the legend renderer. For the `x` / `y`
/// axes, `none` hides the axis ticks and tick labels (the axis line and title
/// stay; remove the title with `labs(x: none)`); under `coord-radial`, `theta`
/// / `r` `none` hide the angular / radial axis labels while the spokes and
/// circles stay.
///
/// \@category Guides
/// \@stability stable
/// \@since 0.0.1
///
/// \@param args Named guide specs keyed by aesthetic name. Each value is a guide
///   spec, `none` to hide that aesthetic's guide, or `auto` for the default.
///   The reserved key `default` sets a fallback guide whose unset fields (e.g.
///   an `auto` `position`) are inherited by every aesthetic without its own
///   override, so `guides(default: guide-legend(position: "bottom"))` moves all
///   legends to the bottom in one call. `guides(default: none)` hides every
///   legend that has no override of its own.
///
/// \@returns Dictionary mapping aesthetic name to guide spec.
///
/// \@examples Lay the colour legend out across two columns.
/// ```
/// //| alt: "Scatter chart with three points coloured by group whose colour legend is laid out across two columns via guide-legend(ncolumn: 2)."
/// #let d = (
///   (x: 1, y: 1, g: "a"),
///   (x: 2, y: 2, g: "b"),
///   (x: 3, y: 3, g: "c"),
/// )
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", colour: "g"),
///   layers: (geom-point(size: 3pt),),
///   guides: guides(colour: guide-legend(ncolumn: 2)),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@examples Combine `guide-axis` and `none` to rotate x ticks and
/// hide the redundant fill legend in one call.
/// ```
/// //| alt: "Bar chart of y per month with x tick labels rotated thirty degrees via guide-axis and the fill legend suppressed by passing none."
/// #let d = (
///   (x: "January", y: 1, g: "a"),
///   (x: "February", y: 2, g: "a"),
///   (x: "March", y: 3, g: "b"),
///   (x: "April", y: 4, g: "b"),
/// )
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", fill: "g"),
///   layers: (geom-col(),),
///   guides: guides(
///     x: guide-axis(angle: 30),
///     fill: none,
///   ),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@examples Use `default` to place every legend at the bottom in one call;
/// the per-aesthetic `colour` override inherits that side and only changes its
/// column count.
/// ```
/// //| alt: "Scatter chart whose colour and shape legends both sit below the panel, with the colour legend laid out across three columns."
/// #let d = (
///   (x: 1, y: 1, g: "a", s: "p"),
///   (x: 2, y: 2, g: "b", s: "q"),
///   (x: 3, y: 3, g: "c", s: "p"),
/// )
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", colour: "g", shape: "s"),
///   layers: (geom-point(size: 3pt),),
///   guides: guides(
///     default: guide-legend(position: "bottom"),
///     colour: guide-legend(ncolumn: 3),
///   ),
///   width: 9cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@guide-legend, \@plot
#let guides(..args) = {
  let out = (:)
  for (k, v) in args.named() {
    if v == auto {
      continue
    } else if v == none {
      out.insert(k, (kind: "guide", suppress: true))
    } else if type(v) == dictionary {
      out.insert(k, v)
    } else {
      fail(
        "guides",
        "value for '"
          + k
          + "' must be a guide spec (e.g. guide-legend, guide-axis), `none` to"
          + " hide the guide, or `auto` for the default; got "
          + repr(v),
      )
    }
  }
  out
}
