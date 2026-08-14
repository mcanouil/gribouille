///! Void theme preset.
///!
///! No axes, grid, or panel background. Useful when the plot stands on its
///! own without an axis frame (e.g., maps, annotated figures).

#import "defaults.typ": _tr-ink
#import "elements.typ": element-blank, element-rect, element-text, margin
#import "theme.typ": _preset

/// Void theme: no axes, no grid, no panel background.
///
/// \@category Themes
/// \@subcategory Complete themes
/// \@stability stable
///
/// \@param ink Foreground colour. Default: `black`.
///
/// \@param paper Plot canvas fill. Default: transparent (no canvas drawn). Pass an explicit colour to paint the canvas behind the otherwise-blank panel.
///
/// \@param accent Accent colour driving layer defaults like \@geom-smooth's stroke. Default: `rgb("#3366FF")`.
///
/// \@param ..fields Extra overrides forwarded to \@theme; see its docs for the full catalogue of structured and flat keys.
/// \@theme-fields
///
/// \@returns Theme dictionary consumed by \@plot.
///
/// \@examples Strip away axes, grid, and panel background entirely.
/// ```
/// //| alt: "Scatter plot of y against x with axes, gridlines, panel background and tick labels all stripped away."
/// #let d = range(0, 10).map(i => (x: i, y: i * 0.5))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 2pt),),
///   theme: theme-void(),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@examples Useful behind a custom annotated figure where axes would be
/// visual noise; pass an explicit `paper` for a solid background.
/// ```
/// //| alt: "Circular path of sine against cosine coloured by time on the void theme over a warm cream canvas without axes or grid."
/// #let d = range(0, 12).map(i => (
///   x: calc.cos(i * 0.5), y: calc.sin(i * 0.5), t: i,
/// ))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", colour: "t"),
///   layers: (geom-path(stroke: 1.4pt),),
///   theme: theme-void(paper: rgb("#fff7e6")),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@examples Restore a faint panel background while keeping the void
/// preset's stripped-down axes.
/// ```
/// //| alt: "Scatter plot of y against x on the void theme with a faint cream panel background restored beneath the stripped axes."
/// #let d = range(0, 10).map(i => (x: i, y: i * 0.5))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 2pt),),
///   theme: theme-void(panel-background: element-rect(fill: rgb("#f7f0e7"))),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@theme-grey, \@theme-minimal, \@theme-classic, \@theme
#let theme-void(
  ink: _tr-ink,
  paper: auto,
  accent: rgb("#3366FF"),
  ..fields,
) = {
  let _paper = if paper == auto { rgb(0, 0, 0, 0) } else { paper }
  // A void theme reserves nothing, padding included: `element-rect` defaults to
  // a 5pt inset on every side, which is a third of a centimetre off each
  // dimension and the difference between drawing and failing at sparkline
  // sizes. Only an explicit `margin(...)` record clears it: `_merge-element`
  // skips `none`, and `_normalise-margin` discards anything that is not a
  // `margin`, so both `inset: none` and `inset: 0pt` leave the default standing.
  let _plot-bg = element-rect(
    fill: if paper == auto { none } else { _paper },
    inset: margin(top: 0pt, right: 0pt, bottom: 0pt, left: 0pt),
  )
  _preset(
    "void",
    ink,
    _paper,
    accent,
    (
      panel-background: element-blank(),
      plot-background: _plot-bg,
      panel-grid: element-blank(),
      axis-line: element-blank(),
      axis-title: element-text(size: 0pt),
      axis-ticks: element-blank(),
      axis-text: element-blank(),
    ),
    fields,
  )
}
