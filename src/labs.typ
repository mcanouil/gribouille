///! Plot-level labels: title, subtitle, caption, and per-aesthetic names.
///!
///! `labs` is the primary constructor; `ggtitle`, `xlab`, and `ylab` are thin
///! wrappers for the common cases. The result feeds @plot, which draws the
///! title block and forwards axis names into the trained scales so axis and
///! legend titles follow.

/// Build a label dictionary for the plot title, subtitle, caption, and axes.
///
/// Pass the result to @plot as the `labs` argument.
/// Axis names (x, y, colour, fill, ...) override the corresponding scale
/// `name` at render time, so legends and axis titles pick them up.
///
/// @category Labs
/// @stability stable
/// @since 0.1.0
///
/// @param title Plot title drawn above the panel.
/// @param subtitle Smaller line drawn below the title.
/// @param caption Caption line drawn below the panel.
/// @param tag Optional tag (e.g. a figure number) drawn above the title.
/// @param alt Alt text kept on the spec for accessibility tooling.
/// @param x Title for the x axis.
/// @param y Title for the y axis.
/// @param colour Legend title for the colour aesthetic.
/// @param fill Legend title for the fill aesthetic.
/// @param size Legend title for the size aesthetic.
/// @param alpha Legend title for the alpha aesthetic.
/// @param shape Legend title for the shape aesthetic.
/// @param linetype Legend title for the linetype aesthetic.
///
/// @returns Dictionary tagged `kind: "labs"`, consumed by @plot.
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
///   layers: (geom-point(size: 3pt),),
///   labs: labs(
///     title: "Demo",
///     subtitle: "A tiny dataset",
///     caption: "Source: made up",
///     x: "Index",
///     y: "Value",
///   ),
/// )
/// ```
///
/// @see @ggtitle, @xlab, @ylab, @plot
#let labs(
  title: none,
  subtitle: none,
  caption: none,
  tag: none,
  alt: none,
  x: none,
  y: none,
  colour: none,
  fill: none,
  size: none,
  alpha: none,
  shape: none,
  linetype: none,
) = (
  kind: "labs",
  title: title,
  subtitle: subtitle,
  caption: caption,
  tag: tag,
  alt: alt,
  axes: (
    x: x,
    y: y,
    colour: colour,
    fill: fill,
    size: size,
    alpha: alpha,
    shape: shape,
    linetype: linetype,
  ),
)

/// Shortcut for setting the plot title (and optional subtitle).
///
/// Equivalent to `labs(title: title, subtitle: subtitle)`.
///
/// @category Labs
/// @stability stable
/// @since 0.1.0
///
/// @param title Plot title drawn above the panel.
/// @param subtitle Optional smaller line drawn below the title.
///
/// @returns Dictionary tagged `kind: "labs"`, consumed by @plot.
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
///   layers: (geom-point(size: 3pt),),
///   labs: ggtitle("Quick look", subtitle: "Three points"),
/// )
/// ```
///
/// @see @labs, @xlab, @ylab
#let ggtitle(title, subtitle: none) = labs(title: title, subtitle: subtitle)

/// Shortcut for setting the x axis title.
///
/// Equivalent to `labs(x: label)`.
///
/// @category Labs
/// @stability stable
/// @since 0.1.0
///
/// @param label Title drawn below the x axis.
///
/// @returns Dictionary tagged `kind: "labs"`, consumed by @plot.
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
///   layers: (geom-point(size: 3pt),),
///   labs: xlab("Index"),
/// )
/// ```
///
/// @see @labs, @ggtitle, @ylab
#let xlab(label) = labs(x: label)

/// Shortcut for setting the y axis title.
///
/// Equivalent to `labs(y: label)`.
///
/// @category Labs
/// @stability stable
/// @since 0.1.0
///
/// @param label Title drawn beside the y axis.
///
/// @returns Dictionary tagged `kind: "labs"`, consumed by @plot.
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
///   layers: (geom-point(size: 3pt),),
///   labs: ylab("Value"),
/// )
/// ```
///
/// @see @labs, @ggtitle, @xlab
#let ylab(label) = labs(y: label)
