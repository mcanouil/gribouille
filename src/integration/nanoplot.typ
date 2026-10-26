///! keisen nanoplot renderer built from the parts of a Gribouille plot.
///!
///! keisen takes a renderer as a dictionary `(kind: "nanoplot-renderer", draw,
///! readings, axis)` and never imports Gribouille, and nothing here imports
///! keisen: the two meet only through that dictionary. keisen reads every cell
///! of a column with `readings`, computes one domain for the column, then calls
///! `draw` for each cell and `axis` for the column axis with that domain.

#import "../plot.typ": plot
#import "../aes.typ": aes
#import "../guides.typ": guides
#import "../labels.typ": labels
#import "../geom/blank.typ": geom-blank
#import "../scale/continuous.typ": _continuous-scale
#import "../scale/expansion.typ": normalise-expansion
#import "../scale/secondary.typ": dup-axis
#import "../theme/void.typ": theme-void
#import "../theme/theme.typ": _normalise-margin, resolve-element
#import "../theme/elements.typ": (
  element-blank, element-rect, element-text, margin,
)
#import "../utils/errors.typ": fail-enum, fail-type

#let _SIDES = ("top", "bottom")

// The surfaces of the panel, blanked on the axis so it draws ticks and labels
// only. Each per-axis key is set as well, because a key a user theme sets below
// `panel-grid` wins over a blank set on `panel-grid` itself.
#let _PANEL-SURFACES = (
  "panel-background",
  "panel-grid",
  "panel-grid-major",
  "panel-grid-minor",
  "panel-grid-major-x",
  "panel-grid-major-y",
  "panel-grid-minor-x",
  "panel-grid-minor-y",
)

// A cell holds an array of records; anything else holds no readings. A value
// that is not a finite number is no reading either, since keisen takes the
// minimum and the maximum of every reading for the column domain.
#let _readings(value, field) = {
  if type(value) != array { return () }
  value
    .filter(record => type(record) == dictionary)
    .map(record => record.at(field, default: none))
    .filter(reading => type(reading) in (int, float, decimal))
    .map(float)
    .filter(reading => (
      not float.is-nan(reading) and not float.is-infinite(reading)
    ))
}

// The x scale the cells and the axis share: the user's scale with the column
// domain as its limits. Its other fields stay, the expansion included, so a mark
// at the end of the domain is drawn whole under Gribouille's default expansion.
#let _x-scale(scales, domain) = {
  let x = scales.at("x", default: none)
  if x == none { x = _continuous-scale("x") }
  if domain != none { x.insert("limits", (domain.first(), domain.last())) }
  x
}

// The axis is drawn on a canvas `pad` wider on each side, with `pad` added to
// the expansion, so its data area is the cells' data area moved right by `pad`.
// A label at the end of the domain then sits inside the canvas, and Gribouille
// keeps no margin for it that would narrow the data area.
#let _axis-scale(x, pad, side) = {
  let (mult-lo, add-lo, mult-hi, add-hi) = normalise-expansion(
    x.at("expand", default: auto),
    "continuous",
  )
  x.insert("expand", (
    mult-lo * 100% + add-lo * 1cm + pad,
    mult-hi * 100% + add-hi * 1cm + pad,
  ))
  // A top axis is the bottom one copied to the top edge, with the same breaks
  // and labels.
  x.insert("secondary", if side == "top" {
    dup-axis(
      breaks: x.at("breaks", default: auto),
      labels: x.at("labels", default: auto),
    )
  } else { none })
  x
}

// The axis theme: the cell theme with no panel, nothing on the other side, and
// labels on the asked side even when the theme hides them, as theme-void does.
// The canvas reaches `pad` past the column on each side, so the axis line and
// the plot background, which span the whole canvas, are not drawn.
// The plot padding stays on the left and right, where the cells have it too,
// and goes from the top and bottom, which would take the axis height.
#let _axis-theme(base, side) = {
  let other = if side == "top" { "bottom" } else { "top" }
  let out = base
  for key in _PANEL-SURFACES { out.insert(key, element-blank()) }
  let background = resolve-element(out, "plot-background")
  if background.at("kind", default: none) == "element-rect" {
    // A `none` field inherits from `rect`, so the record keeps the padding
    // only, and `rect` is blank so it gives no paint.
    let inset = _normalise-margin(background.at("inset", default: none))
    out.insert("rect", element-blank())
    out.insert("plot-background", element-rect(
      inset: margin(
        top: 0pt,
        right: inset.right,
        bottom: 0pt,
        left: inset.left,
      ),
      outset: background.at("outset", default: none),
    ))
  }
  for family in ("axis-text", "axis-ticks") {
    out.insert(family + "-x-" + other, element-blank())
  }
  for edge in _SIDES { out.insert("axis-line-x-" + edge, element-blank()) }
  let text-key = "axis-text-x-" + side
  if (
    resolve-element(out, text-key).at("kind", default: none) == "element-blank"
  ) {
    out.insert(text-key, element-text())
  }
  out
}

/// Draw a Gribouille plot in each cell of a keisen nanoplot column, with a shared axis.
///
/// `nanoplot` returns a keisen nanoplot renderer.
/// Give it to the `plot` argument of keisen's `format-nanoplot`.
/// Each cell holds an array of records, and the cell draws them as the `data` of \@plot, with the given `mapping`, `layers`, `scales` and `theme`.
///
/// keisen reads the `domain-field` of every record in the column and computes one domain.
/// Each cell then uses that domain as the `limits` of its x scale, so all cells share one x scale.
/// The other arguments of the x scale in `scales` stay as given.
/// The x scale keeps the default expansion of Gribouille unless the x scale in `scales` sets `expand`.
/// Cells draw no axes, no axis titles and no legends.
///
/// When `axis` is `true`, keisen draws the x axis of the column below the column labels and again after the last row.
/// The axis uses the same x scale and theme as the cells, so each break lines up with the cells.
/// This is not true for a geom that widens the x scale past its limits to draw whole marks, such as \@geom-col, \@geom-tile or \@geom-histogram: it widens the scale of the cells, but not the scale of the axis.
/// For these geoms, give keisen's `format-nanoplot` a `domain` that holds the whole marks, for example half a bar width past each end, as in `domain: (-0.5, 10.5)` for bars at 0 to 10.
/// A wider `expand` does not help, because the cells widen their scale past the limits all the same.
/// A tick label at the end of the domain is centred on the end, so half of it can go past the column content into the cell inset.
/// It draws the tick labels even when the theme hides them, as \@theme-void does.
/// The axis draws no axis line and no plot background, even when the theme sets them.
/// Gribouille does not import keisen: the renderer is a plain dictionary.
///
/// \@category Helpers
/// \@stability experimental
///
/// \@param mapping Aesthetic mapping from \@aes, applied to the records of each cell.
///
/// \@param layers Array of geom layers drawn in each cell.
///
/// \@param scales Scales from \@scales.
///   The x scale gets the column domain as its `limits`.
///   It must be continuous, because the column domain is numeric.
///
/// \@param theme Theme for the cells and the axis; `none` (default) uses \@theme-void.
///
/// \@param domain-field Name of the record field that holds the x values, as a string.
///   keisen reads it to compute the column domain.
///   It has no default: `none` fails.
///
/// \@param axis `true` (default) gives the column an x axis; `false` gives it none.
///
/// \@param axis-height Height of the axis, as a length; default `1.4em`.
///   The axis text takes its size from the theme, not from the table.
///   If the theme text is larger than the table text, increase `axis-height` so the tick labels fit.
///
/// \@returns A keisen nanoplot renderer, `(kind: "nanoplot-renderer", draw, readings, axis)`.
///
/// \@examples Call the drawers of the renderer as keisen does, for one cell and the axis below it.
/// ```
/// //| alt: "A strip of five points along a salary scale from 20000 to 60000, drawn without axes, above an axis with tick labels at 20000, 30000, 40000, 50000 and 60000 that line up with the points."
/// #let renderer = nanoplot(
///   mapping: aes(x: "salary", y: "y"),
///   layers: (geom-point(size: 2pt),),
///   domain-field: "salary",
/// )
/// #let cell = (25000, 32000, 41000, 50000, 58000).map(v => (salary: v, y: 0))
/// #let domain = (20000, 60000)
/// // The end labels reach past the cell, as they reach into the cell inset in a table.
/// #pad(x: 2em, stack(
///   spacing: 2pt,
///   (renderer.draw)(cell, domain: domain, width: 9cm, height: 0.6cm),
///   (renderer.axis)(domain: domain, width: 9cm, side: "bottom"),
/// ))
/// ```
///
/// \@examples-static Draw a strip of salaries in each row of a keisen table, with the axis above the first row and below the last.
/// The document imports keisen as `keisen`.
/// ```
/// #let rows = (
///   (field: "Engineering", majors: ((salary: 61000, y: 0), (salary: 72000, y: 0))),
///   (field: "Education", majors: ((salary: 38000, y: 0), (salary: 41000, y: 0))),
/// )
/// #keisen.display-table(
///   rows,
///   keisen.format-nanoplot(
///     "majors",
///     plot: nanoplot(
///       mapping: aes(x: "salary", y: "y"),
///       layers: (geom-point(size: 2pt),),
///       scales: scales(x: scale-continuous(labels: format-currency())),
///       domain-field: "salary",
///     ),
///     width: 6cm,
///     height: 0.6cm,
///     domain: (0, 115000),
///   ),
/// )
/// ```
///
/// \@see \@plot, \@scales, \@theme-void
#let nanoplot(
  mapping: none,
  layers: (),
  scales: (:),
  theme: none,
  domain-field: none,
  axis: true,
  axis-height: 1.4em,
) = {
  if type(domain-field) != str {
    fail-type(
      "nanoplot",
      "domain-field",
      domain-field,
      "a field name",
      hint: "Name the record field that holds the x values, as in domain-field: \"salary\".",
    )
  }
  if type(scales) != dictionary {
    fail-type(
      "nanoplot",
      "scales",
      scales,
      "a dictionary from scales()",
      hint: "Build it with scales(x: scale-continuous(...)).",
    )
  }
  let x-type = scales.at("x", default: (:)).at("type", default: "continuous")
  if x-type != "continuous" {
    fail-type(
      "nanoplot",
      "scales.x",
      x-type,
      "a continuous scale",
      hint: "The column domain is numeric. Use scale-continuous() for x.",
    )
  }
  if type(axis) != bool {
    fail-type("nanoplot", "axis", axis, "a boolean")
  }
  if type(axis-height) != length {
    fail-type(
      "nanoplot",
      "axis-height",
      axis-height,
      "a length",
      hint: "Give it in em or pt, as in 1.4em.",
    )
  }
  let cell-theme = if theme == none { theme-void() } else { theme }

  // keisen gives em sizes, and a plot takes absolute ones, so the drawers
  // resolve them in context.
  let draw(value, domain: none, width: 4em, height: 0.8em) = context plot(
    data: value,
    mapping: mapping,
    layers: layers,
    scales: scales + (x: _x-scale(scales, domain)),
    theme: cell-theme,
    labels: labels(x: none, y: none),
    guides: guides(default: none, x: none, y: none),
    width: width.to-absolute(),
    height: height.to-absolute(),
  )

  let draw-axis(domain: none, width: 4em, side: "bottom") = {
    if side not in _SIDES { fail-enum("nanoplot", "side", side, _SIDES) }
    if domain == none { return none }
    context {
      let width = width.to-absolute()
      let height = axis-height.to-absolute()
      // Wider than half of any tick label, so no label reaches past the canvas.
      let pad = width + 4cm
      box(width: width, height: height, place(top + left, dx: -pad, plot(
        data: ((x: domain.first(), y: 0), (x: domain.last(), y: 0)),
        mapping: aes(x: "x", y: "y"),
        layers: (geom-blank(),),
        scales: (x: _axis-scale(_x-scale(scales, domain), pad, side)),
        theme: _axis-theme(cell-theme, side),
        labels: labels(x: none, y: none),
        guides: guides(default: none, y: none),
        width: width + 2 * pad,
        height: height,
      )))
    }
  }

  (
    kind: "nanoplot-renderer",
    draw: draw,
    readings: value => _readings(value, domain-field),
    axis: if axis { draw-axis } else { none },
  )
}
