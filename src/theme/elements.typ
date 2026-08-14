///! Structured theme elements.
///!
///! `element_*` constructors. \@theme translates these into the flat theme
///! fields consumed internally by `merge-theme`.

#import "../utils/errors.typ": (
  assert-halign, assert-stroke, assert-text-size, assert-tick-length,
)
#import "../utils/types.typ": split-stroke-shorthand

/// Text element: font size, weight, colour, and angle.
///
/// Pass the result to \@theme under keys like `axis-text`, `axis-title`,
/// `legend-text`, or `legend-title`.
///
/// \@category Themes
/// \@subcategory Theme elements
/// \@stability stable
///
/// \@param size Text size. Either an absolute Typst length (e.g., `12pt`), a
///   ratio (e.g., `80%`) scaling the parent surface size, or `none` to inherit
///   the parent size unchanged. Absolute lengths win outright; ratios cascade
///   proportionally, so setting the base `text` size resizes every surface that
///   inherits via a ratio.
///
/// \@param weight Font weight (e.g., `"regular"`, `"bold"`), or `none` to inherit.
///
/// \@param colour Text colour, or `none` to inherit.
///
/// \@param angle Rotation angle (a Typst angle), or `none` to inherit. Honoured
///   on every text surface: axis tick labels (`axis-text`, seeding the
///   \@guide-axis `angle`, which overrides it), axis titles, strip text, the
///   legend title and entry labels, and the plot title, subtitle, and caption.
///   Axis titles fall back to their natural angle (0deg for x, 90deg for y)
///   when unset.
///
/// \@param font Font family (e.g., `"sans"`, `"serif"`), or `none` to inherit.
///
/// \@param margin Per-side spacing built with \@margin. Each side accepts
///   a Typst length (absolute or relative); `em` is preferred so spacing scales
///   with the surface font size. Sides left at `auto` fall through to the
///   renderer default. `none` keeps every side at the default.
///
/// \@param align Horizontal alignment of the text within its surface as a Typst
///   alignment (`left`, `center`, `right`), or `none` to use the per-surface
///   default (title and subtitle left, caption right, axis titles and strip text
///   centred, legend title left, legend entry labels centred in horizontal
///   legends and left in vertical legends). Independent of the surrounding
///   container's alignment. Axis tick labels (`axis-text`) are positioned by
///   anchor and ignore this field.
///
/// \@returns Element dictionary consumed by \@theme.
///
/// \@examples Bigger axis-title font passed via \@theme.
/// ```
/// //| alt: "Scatter plot of y against x with axis titles enlarged to 14pt via element-text passed to theme."
/// #let d = range(0, 10).map(i => (x: i, y: i * 0.5))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 2pt),),
///   theme: theme(axis-title: element-text(size: 14pt)),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@examples Combine multiple text fields and a rotation angle on axis
/// tick labels.
/// ```
/// //| alt: "Bar chart of y across quarterly categories with axis tick labels rendered in blue 9pt text rotated 30 degrees."
/// #let d = (
///   (q: "Q1", y: 3), (q: "Q2", y: 5), (q: "Q3", y: 4), (q: "Q4", y: 6),
/// )
/// #plot(
///   data: d,
///   mapping: aes(x: "q", y: "y"),
///   layers: (geom-col(),),
///   theme: theme(axis-text: element-text(
///     size: 9pt,
///     angle: 30deg,
///     colour: rgb("#1f77b4"),
///   )),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@examples Widen the gap between the axis tick labels and the axis title
/// using a relative margin that tracks the title font size.
/// ```
/// //| alt: "Scatter plot of y against x with extra 1.6em padding above and to the right of the axis titles so they sit further from the ticks."
/// #let d = range(0, 10).map(i => (x: i, y: i * 0.5))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 2pt),),
///   theme: theme(axis-title: element-text(
///     size: 11pt,
///     margin: margin(top: 1.6em, right: 1.6em),
///   )),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@examples Relative versus absolute sizes: a `12pt` base `text` rescales
/// every inheriting surface, a `120%` ratio on the axis titles scales them
/// relative to that base, and an absolute `18pt` pins the plot title outright.
/// ```
/// //| alt: "Scatter plot of y against x with a 12pt base text size, axis titles scaled to 120 percent of it, and the plot title pinned to an absolute 18pt."
/// #let d = range(0, 10).map(i => (x: i, y: i * 0.5))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 2pt),),
///   labels: labels(title: "Relative and absolute", x: "X", y: "Y"),
///   theme: theme(
///     text: element-text(size: 12pt),
///     axis-title: element-text(size: 120%),
///     plot-title: element-text(size: 18pt, weight: "bold"),
///   ),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@theme, \@element-line, \@element-rect, \@element-blank, \@element-typst, \@margin
#let element-text(
  size: none,
  weight: none,
  colour: none,
  angle: none,
  font: none,
  margin: none,
  align: none,
) = {
  assert-halign("element-text", align)
  assert-text-size("element-text", size)
  (
    kind: "element-text",
    size: size,
    weight: weight,
    colour: colour,
    angle: angle,
    font: font,
    margin: margin,
    align: align,
  )
}

/// Typst-markup text element: same fields as \@element-text plus
/// automatic Typst-markup evaluation for plain strings reaching this
/// surface.
///
/// Drop-in replacement for \@element-text on any text key. Strings
/// supplied via \@labels, scale names, or scale `labels:` callbacks are
/// evaluated as Typst markup before rendering, so users do not need to
/// wrap each value with \@typst. Per-call \@typst() and content (`[…]`)
/// values still pass through unchanged.
///
/// \@category Themes
/// \@subcategory Theme elements
/// \@stability stable
///
/// \@param size Text size. Either an absolute Typst length (e.g., `12pt`), a
///   ratio (e.g., `80%`) scaling the parent surface size, or `none` to inherit
///   the parent size unchanged.
///
/// \@param weight Font weight (e.g., `"regular"`, `"bold"`), or `none`.
///
/// \@param colour Text colour, or `none` to inherit.
///
/// \@param angle Rotation angle (a Typst angle), or `none` to inherit. Honoured
///   on every text surface: axis tick labels (`axis-text`, seeding the
///   \@guide-axis `angle`, which overrides it), axis titles, strip text, the
///   legend title and entry labels, and the plot title, subtitle, and caption.
///   Axis titles fall back to their natural angle (0deg for x, 90deg for y)
///   when unset.
///
/// \@param font Font family, or `none` to inherit.
///
/// \@param margin Per-side spacing built with \@margin. Each side accepts
///   a Typst length (absolute or relative); `em` is preferred so spacing scales
///   with the surface font size. Sides left at `auto` fall through to the
///   renderer default. `none` keeps every side at the default.
///
/// \@param align Horizontal alignment of the text within its surface as a Typst
///   alignment (`left`, `center`, `right`), or `none` to use the per-surface
///   default (title and subtitle left, caption right, axis titles and strip text
///   centred, legend title left, legend entry labels centred in horizontal
///   legends and left in vertical legends). Independent of the surrounding
///   container's alignment. Axis tick labels (`axis-text`) are positioned by
///   anchor and ignore this field.
///
/// \@returns Element dictionary consumed by \@theme.
///
/// \@examples Enable Typst markup for every plot title in a session by
/// setting `plot-title: element-typst()` on the theme.
/// ```
/// //| alt: "Scatter plot of y against x titled \"Mean x-bar over Time\" with the title rendered as 14pt bold Typst markup including a math glyph."
/// #let d = ((x: 1, y: 1), (x: 2, y: 4), (x: 3, y: 9))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 2pt),),
///   labels: labels(title: "Mean $macron(x)$ over Time"),
///   theme: theme(plot-title: element-typst(size: 14pt, weight: "bold")),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@examples Mix typst and non-typst surfaces in the same theme:
/// ```
/// //| alt: "Scatter plot of y against x with a Typst-evaluated plot title rendering math glyphs while the axis titles stay as plain text."
/// #let d = ((x: 1, y: 1), (x: 2, y: 4), (x: 3, y: 9))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 2pt),),
///   labels: labels(title: "Mean $macron(x)$", x: "Time (s)"),
///   theme: theme(
///     plot-title: element-typst(),
///     axis-title: element-text(),
///   ),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@theme, \@element-text, \@typst, \@margin
#let element-typst(
  size: none,
  weight: none,
  colour: none,
  angle: none,
  font: none,
  margin: none,
  align: none,
) = {
  assert-halign("element-typst", align)
  assert-text-size("element-typst", size)
  (
    kind: "element-typst",
    size: size,
    weight: weight,
    colour: colour,
    angle: angle,
    font: font,
    margin: margin,
    align: align,
  )
}

/// Line element: colour and stroke thickness.
///
/// Pass the result to \@theme under keys like `panel-grid` or `axis-line`.
///
/// \@category Themes
/// \@subcategory Theme elements
/// \@stability stable
///
/// \@param colour Line colour, or `none` to inherit.
///
/// \@param stroke Line thickness. Either an absolute Typst length (e.g., `1pt`),
///   a ratio (e.g., `80%`) scaling the parent surface stroke, or `none` to
///   inherit the parent thickness unchanged. Absolute lengths win outright;
///   ratios cascade proportionally, so setting the base `line` stroke rescales
///   every surface that inherits via a ratio. The native `1pt + red` form is
///   also accepted: its paint fills in `colour` unless `colour` is set.
///
/// \@returns Element dictionary consumed by \@theme.
///
/// \@examples Recolour the panel grid via \@theme.
/// ```
/// //| alt: "Scatter plot of y against x with the panel gridlines recoloured pale stone via element-line on the panel-grid surface."
/// #let d = range(0, 10).map(i => (x: i, y: i * 0.5))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 2pt),),
///   theme: theme(panel-grid: element-line(colour: rgb("#d9cfbf"))),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@examples Strengthen the axis line by setting both `colour` and
/// `stroke`.
/// ```
/// //| alt: "Scatter plot of y against x with axis lines drawn 1pt thick in red via element-line on the axis-line surface."
/// #let d = range(0, 10).map(i => (x: i, y: i * 0.5))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 2pt),),
///   theme: theme(axis-line: element-line(
///     colour: rgb("#cc0000"),
///     stroke: 1pt,
///   )),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@theme, \@element-text, \@element-rect, \@element-blank
#let element-line(colour: none, stroke: none) = {
  let split = split-stroke-shorthand(stroke, colour, none)
  let stroke = split.stroke
  let colour = split.colour
  assert-stroke("element-line", stroke)
  (
    kind: "element-line",
    colour: colour,
    stroke: stroke,
  )
}

/// Tick element: a line element that also carries the tick mark length.
///
/// Pass the result to \@theme under `axis-ticks` and its per-axis, per-side,
/// and minor variants (`axis-ticks-x`, `axis-ticks-y-right`,
/// `axis-ticks-minor`, ...). \@element-line is accepted on the same keys and
/// leaves `length` to the cascade. \@element-blank turns the marks off
/// entirely: no ink and no reserved depth around the panel.
///
/// \@category Themes
/// \@subcategory Theme elements
/// \@stability stable
///
/// \@param colour Tick colour, or `none` to inherit.
///
/// \@param stroke Tick thickness. Either an absolute Typst length (e.g., `1pt`),
///   a ratio (e.g., `80%`) scaling the parent surface stroke, or `none` to
///   inherit the parent thickness unchanged. The native `1pt + red` form is
///   also accepted: its paint fills in `colour` unless `colour` is set.
///
/// \@param length Tick mark length, measured outward from the panel edge.
///   Either an absolute Typst length (e.g., `0.2cm`), a ratio (e.g., `50%`)
///   scaling the parent surface length, or `none` to inherit the parent length
///   unchanged. `0cm` hides the marks while keeping their cascade in place.
///
/// \@returns Element dictionary consumed by \@theme.
///
/// \@examples Longer ticks in red on both axes.
/// ```
/// //| alt: "Scatter plot of y against x with 0.25cm red tick marks on both axes via element-tick on the axis-ticks surface."
/// #let d = range(0, 10).map(i => (x: i, y: i * 0.5))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 2pt),),
///   theme: theme(axis-ticks: element-tick(
///     colour: rgb("#cc0000"),
///     length: 0.25cm,
///   )),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@examples Lengthen only the y axis; the ratio scales the length inherited
/// from `axis-ticks`.
/// ```
/// //| alt: "Scatter plot of y against x where the y-axis tick marks are twice as long as the x-axis ones via a ratio length on element-tick."
/// #let d = range(0, 10).map(i => (x: i, y: i * 0.5))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 2pt),),
///   theme: theme(
///     axis-ticks: element-tick(length: 0.15cm),
///     axis-ticks-y: element-tick(length: 200%),
///   ),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@theme, \@element-line, \@element-blank
#let element-tick(colour: none, stroke: none, length: none) = {
  let split = split-stroke-shorthand(stroke, colour, none)
  let stroke = split.stroke
  let colour = split.colour
  assert-stroke("element-tick", stroke)
  assert-tick-length("element-tick", length)
  (
    kind: "element-tick",
    colour: colour,
    stroke: stroke,
    length: length,
  )
}

/// Rectangle element: fill, outline colour, stroke thickness, and per-side
/// margins. `inset` is honoured on `plot-background` (Typst `block(inset:)`
/// pads the content inward, and grows the painted fill outward past it when
/// a fill or stroke is set) and on `legend-background` (grows the legend
/// rect outward from the guide-stack bbox so the rectangle frames the legend
/// with extra inner padding). `panel-background` and `legend-bar` ignore
/// `inset` so the rect cannot bleed onto neighbours. `outset` reserves outer
/// whitespace by widening the chrome slot on `panel-background`,
/// `legend-background`, and `legend-bar`; on `plot-background` it wraps the
/// rendered block in `pad(...)`. On `legend-background`, the panel-facing
/// outset side also widens the visible gap between panel and legend.
/// On `plot-background`, both `inset` and `outset` apply whether or not a
/// fill or stroke is set, so they reserve plot padding on their own.
/// `strip-background` ignores both fields -- the facet band has no
/// surrounding slot to grow or reserve into.
/// On `legend-background`, `inset` only grows a rect that actually paints
/// (a fill or a stroke is set); an inside-panel guide additionally keeps
/// its painted rect, plus any `outset`, within the panel rather than
/// letting it overflow past an edge-flush alignment. A guide on a plot
/// side reserves that growth in its chrome slot, so the backdrop stays
/// inside the requested `width` / `height` there too.
///
/// Pass the result to \@theme under keys like `panel-background`.
///
/// \@category Themes
/// \@subcategory Theme elements
/// \@stability stable
///
/// \@param fill Rectangle fill colour, or `none` to inherit.
///
/// \@param colour Outline colour, or `none` to inherit.
///
/// \@param stroke Outline thickness. Either an absolute Typst length (e.g.,
///   `1pt`), a ratio (e.g., `80%`) scaling the parent surface stroke, or `none`
///   for no outline. Ratios with no absolute ancestor resolve against the
///   default thickness. The native `1pt + red` form is also accepted: its paint
///   fills in `colour` unless `colour` is set.
///
/// \@param inset Inner padding \@margin honoured by `plot-background` and `legend-background` (grows the painted rect outward), or `none`. Ignored on `panel-background`, `strip-background`, and `legend-bar`.
///
/// \@param outset Outer margin \@margin reserving outer whitespace (panel canvas shrinks on cetz surfaces; the rendered block is wrapped in `pad(...)` on `plot-background`), or `none`. Ignored on `strip-background`.
///
/// \@returns Element dictionary consumed by \@theme.
///
/// \@examples Tinted panel background via \@theme.
/// ```
/// //| alt: "Scatter plot of y against x with the panel background tinted warm cream via element-rect on the panel-background surface."
/// #let d = range(0, 10).map(i => (x: i, y: i * 0.5))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 2pt),),
///   theme: theme(panel-background: element-rect(fill: rgb("#f7f0e7"))),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@examples Add a stroke to frame the panel as well as fill it.
/// ```
/// //| alt: "Scatter plot of y against x with a cream-filled panel ringed by a 1pt amber stroke via element-rect fill, colour, and stroke."
/// #let d = range(0, 10).map(i => (x: i, y: i * 0.5))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 2pt),),
///   theme: theme(panel-background: element-rect(
///     fill: rgb("#fff7e6"),
///     colour: rgb("#cc7a00"),
///     stroke: 1pt,
///   )),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@examples Pad a legend background so its tinted rectangle frames the
/// guide content with breathing room (inner padding).
/// ```
/// //| alt: "Scatter plot of y against x with a tinted legend backdrop padded via inner inset margins so the rectangle frames the guide with breathing room."
/// #let d = range(0, 10).map(i => (x: i, y: i * 0.5, k: if calc.rem(i, 2) == 0 { "a" } else { "b" }))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", colour: "k"),
///   layers: (geom-point(size: 2pt),),
///   theme: theme(legend-background: element-rect(
///     fill: rgb("#f7f0e7"),
///     inset: margin(top: 0.3em, right: 0.4em, bottom: 0.3em, left: 0.4em),
///   )),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@examples An inside-panel legend keeps its painted background within
/// the panel even flush against a corner.
/// ```
/// //| alt: "Scatter plot of y against x with a tinted, stroked legend background placed inside the bottom-right corner of the panel, its backdrop staying within the panel edges."
/// #let d = range(0, 10).map(i => (x: i, y: i * 0.5, k: if calc.rem(i, 2) == 0 { "a" } else { "b" }))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", colour: "k"),
///   layers: (geom-point(size: 2pt),),
///   guides: guides(colour: guide-legend(position: bottom + right)),
///   theme: theme(legend-background: element-rect(
///     fill: rgb("#f7f0e7"),
///     colour: rgb("#cc7a00"),
///     stroke: 0.6pt,
///   )),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@theme, \@margin, \@element-text, \@element-line, \@element-blank
#let element-rect(
  fill: none,
  colour: none,
  stroke: none,
  inset: (kind: "margin", top: 5pt, right: 5pt, bottom: 5pt, left: 5pt),
  outset: none,
) = {
  let split = split-stroke-shorthand(stroke, colour, none)
  let stroke = split.stroke
  let colour = split.colour
  assert-stroke("element-rect", stroke)
  (
    kind: "element-rect",
    fill: fill,
    colour: colour,
    stroke: stroke,
    inset: inset,
    outset: outset,
  )
}

/// Blank element: hides the corresponding theme element.
///
/// Pass the result to \@theme under keys like `panel-grid` or `axis-line`
/// to turn them off entirely. On a text surface (`axis-title`, `plot-title`,
/// `legend-title`, ...) it also collapses the space the text would reserve, so
/// the data panel grows into the freed area.
///
/// \@category Themes
/// \@subcategory Theme elements
/// \@stability stable
///
/// \@returns Element dictionary consumed by \@theme.
///
/// \@examples Hide the panel grid entirely.
/// ```
/// //| alt: "Scatter plot of y against x with the panel grid hidden via element-blank, leaving only axis lines and tick labels."
/// #let d = range(0, 10).map(i => (x: i, y: i * 0.5))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 2pt),),
///   theme: theme(panel-grid: element-blank()),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@examples Combine `element-blank` with other overrides to remove
/// multiple non-data marks at once.
/// ```
/// //| alt: "Scatter plot of y against x with both panel grid and axis lines hidden via element-blank, removing the chart frame at once."
/// #let d = range(0, 10).map(i => (x: i, y: i * 0.5))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 2pt),),
///   theme: theme(
///     panel-grid: element-blank(),
///     axis-line: element-blank(),
///   ),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@examples Blank a text surface to drop its ink and reclaim its space; here
/// the axis titles collapse while tick labels stay.
/// ```
/// //| alt: "Scatter plot of y against x with both axis titles removed via element-blank, the panel filling the space the titles would occupy while tick labels remain."
/// #let d = range(0, 10).map(i => (x: i, y: i * 0.5))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 2pt),),
///   labels: labels(x: "Index", y: "Value"),
///   theme: theme(axis-title: element-blank()),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@theme, \@element-text, \@element-line, \@element-rect
#let element-blank() = (kind: "element-blank")

/// Per-side spacing record consumed by \@element-text / \@element-typst
/// (text margin to neighbours) and \@element-rect (`inset` / `outset`
/// offsets around the painted rectangle).
///
/// Each side accepts a Typst length (e.g., `1cm`, `8pt`, `0.3em`), a
/// ratio (e.g., `5%`), a relative (e.g., `5% + 1cm`), or `auto`. On rect
/// surfaces, `%` / `relative` sides resolve against the plot canvas
/// dimensions (`width-units` for horizontal sides, `height-units` for
/// vertical) at both draw time (`inset`) and layout time (`outset`).
/// `auto` falls through to the consuming surface's renderer default (text
/// gap) or to a zero offset (rect inset / outset). Bare `margin()` leaves
/// every side at `auto`.
///
/// \@category Themes
/// \@subcategory Theme elements
/// \@stability stable
///
/// \@param top Top margin (Typst length or `auto`).
///
/// \@param right Right margin.
///
/// \@param bottom Bottom margin.
///
/// \@param left Left margin.
///
/// \@returns Margin dictionary consumed by \@element-text, \@element-typst, and \@element-rect.
///
/// \@examples Loosen the gap between the y-axis tick labels and the
/// axis-title via `element-text`'s `margin`.
/// ```
/// //| alt: "Scatter plot of y against x with a wider 0.6em right-hand gap between the y-axis-title text and the axis labels via element-text margin."
/// #let d = range(0, 10).map(i => (x: i, y: i * 0.5))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 2pt),),
///   labels: labels(y: "Cumulative Response"),
///   theme: theme(axis-title-y-left: element-text(margin: margin(right: 0.6em))),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@examples Pad a panel background so its rectangle frames the data
/// region with extra breathing room (inner padding via `inset`).
/// ```
/// //| alt: "Scatter plot of y against x with the panel background tinted cream and grown outward 0.4cm on every side via element-rect inset (inner padding)."
/// #let d = range(0, 10).map(i => (x: i, y: i * 0.5))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 2pt),),
///   theme: theme(panel-background: element-rect(
///     fill: rgb("#f7f0e7"),
///     inset: margin(top: 0.4cm, right: 0.4cm, bottom: 0.4cm, left: 0.4cm),
///   )),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@examples Reserve outer whitespace around a tinted panel background;
/// the panel canvas shrinks but the rectangle still surrounds the data.
/// ```
/// //| alt: "Scatter plot of y against x with a tinted panel background and 0.4cm of reserved outer whitespace on every side via element-rect outset; the panel canvas shrinks accordingly."
/// #let d = range(0, 10).map(i => (x: i, y: i * 0.5))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 2pt),),
///   theme: theme(panel-background: element-rect(
///     fill: rgb("#f7f0e7"),
///     outset: margin(top: 0.4cm, right: 0.4cm, bottom: 0.4cm, left: 0.4cm),
///   )),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@element-text, \@element-typst, \@element-rect, \@theme
#let margin(top: auto, right: auto, bottom: auto, left: auto) = (
  kind: "margin",
  top: top,
  right: right,
  bottom: bottom,
  left: left,
)

/// Layer-default aesthetics shared across geoms.
///
/// Pass the result to \@theme under the `geom` key to set defaults that the
/// supporting geoms will pick up unless their own parameters override them.
/// Mirrors plotnine's `element_geom()`.
/// `fill` and `colour` are *global overrides* that win for every supporting
/// geom; `ink`, `paper`, `accent` are *role* colours that geoms fall back to
/// when the global override is unset, with each geom declaring which role
/// drives its default (`ink` for line/text geoms, `accent` for \@geom-smooth,
/// `paper` for \@geom-boxplot/\@geom-crossbar/\@geom-point/\@geom-label, a
/// `colour-mix(ink, paper, …)` tint for the bar/area/rect/tile family).
///
/// \@category Themes
/// \@subcategory Theme elements
/// \@stability stable
///
/// \@param fill Global override for every filled geom's default fill colour.
///
/// \@param colour Global override for every geom's default stroke or text colour, including \@geom-smooth.
///
/// \@param linewidth Default stroke thickness for line and outline geoms (Typst length).
///
/// \@param font Default font family for the text-drawing geoms (\@geom-text, \@geom-label, \@geom-typst). Falls back to the base `text` element family, then the document font.
///
/// \@param ink Geom `ink` role: default stroke/text colour for almost every geom and the dark stop of the bar/area body-fill tint. Falls back to `theme.ink`.
///
/// \@param paper Geom `paper` role: default fill for \@geom-boxplot, \@geom-crossbar, \@geom-point, \@geom-label, and the light stop of the bar/area body-fill tint. Falls back to `theme.paper`.
///
/// \@param accent Geom `accent` role: default colour for \@geom-smooth (when `colour` is unset). Falls back to `theme.accent`.
///
/// \@returns Element dictionary consumed by \@theme.
///
/// \@examples Pin a brand fill and bumped stroke thickness across the
/// supporting geoms.
/// ```
/// //| alt: "Bar chart of y against x with bars filled deep red and outlined 1pt thick via the element-geom layer defaults."
/// #let d = range(0, 10).map(i => (x: i, y: i * 0.5))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-col(),),
///   theme: theme(geom: element-geom(
///     fill: rgb("#cc3333"),
///     linewidth: 1pt,
///   )),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@examples Shift the role colours so every unset default re-tints together:
/// `ink` recolours stroke and text geoms and the dark stop of the bar fill;
/// `paper` recolours boxplot/point/label fills and the light stop; `accent`
/// recolours \@geom-smooth.
/// ```
/// //| alt: "Bar chart of y against x with a re-tinted navy and cream colour role pairing and a warm orange smooth trend line via geom-smooth."
/// #let d = range(0, 20).map(i => (x: i, y: i * 0.4 + calc.sin(i * 0.5)))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-col(), geom-smooth(se: false)),
///   theme: theme(geom: element-geom(
///     ink: rgb("#2c3e50"),
///     paper: rgb("#fff7e6"),
///     accent: rgb("#cc6600"),
///   )),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@examples Set the font for the text-drawing geoms (\@geom-text, \@geom-label,
/// \@geom-typst) without touching the axis or title surfaces.
/// ```
/// //| alt: "Scatter plot of y against x with each point labelled by its x value in DejaVu Sans Mono via the element-geom font role, while the axes keep the default font."
/// #let d = range(0, 6).map(i => (x: i, y: i * 0.5))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 2pt), geom-text(mapping: aes(label: "x"))),
///   theme: theme(geom: element-geom(font: "DejaVu Sans Mono")),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@theme, \@element-text, \@element-line, \@element-rect, \@element-blank
#let element-geom(
  fill: none,
  colour: none,
  linewidth: none,
  font: none,
  ink: none,
  paper: none,
  accent: none,
) = (
  kind: "element-geom",
  fill: fill,
  colour: colour,
  linewidth: linewidth,
  font: font,
  ink: ink,
  paper: paper,
  accent: accent,
)
