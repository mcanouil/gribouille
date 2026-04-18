///! Custom theme builder.
///!
///! `theme` accepts per-element overrides via named arguments. Keys can be
///! either low-level fields (same names as the internal `default-theme`) or
///! structured element records from @element-text, @element-line,
///! @element-rect, and @element-blank.

#let _apply-element(out, key, value) = {
  if value == none { return out }
  let el-kind = if type(value) == dictionary { value.at("kind", default: none) } else { none }

  if key == "axis-text" and el-kind == "element-text" {
    if value.size != none { out.insert("axis-text-size", value.size) }
    return out
  }
  if key == "axis-title" and el-kind == "element-text" {
    if value.size != none { out.insert("axis-title-size", value.size) }
    return out
  }
  if key == "legend-text" and el-kind == "element-text" {
    if value.size != none { out.insert("legend-text-size", value.size) }
    return out
  }
  if key == "legend-title" and el-kind == "element-text" {
    if value.size != none { out.insert("legend-title-size", value.size) }
    return out
  }
  if key == "panel-background" and el-kind == "element-rect" {
    if value.fill != none { out.insert("panel-fill", value.fill) }
    return out
  }
  if key == "panel-grid" and el-kind == "element-line" {
    if value.colour != none { out.insert("grid-colour", value.colour) }
    if value.thickness != none { out.insert("grid-thickness", value.thickness) }
    return out
  }
  if key == "panel-grid" and el-kind == "element-blank" {
    out.insert("grid-colour", none)
    return out
  }
  if key == "axis-line" and el-kind == "element-line" {
    if value.colour != none { out.insert("axis-colour", value.colour) }
    if value.thickness != none { out.insert("axis-thickness", value.thickness) }
    return out
  }
  if key == "axis-line" and el-kind == "element-blank" {
    out.insert("axis-colour", none)
    return out
  }

  // Low-level passthrough: unknown keys land as-is so users can still
  // override the flat fields defined in `default-theme`.
  out.insert(key, value)
  out
}

/// Build a custom theme from per-element overrides.
///
/// Pass named arguments like `axis-title: element-text(size: 12pt)` or
/// low-level keys like `panel-fill: rgb("#f7f0e7")`. Structured element
/// records are translated into the flat theme fields consumed internally.
///
/// @category Themes
/// @stability stable
/// @since 0.1.0
///
/// @param ..fields Named per-element overrides. Keys may be structured (`axis-title`, `panel-grid`, ...) or flat (`axis-title-size`, `panel-fill`, ...).
///
/// @returns Theme dictionary consumed by @plot.
///
/// @example
/// ```
/// //| width: 10cm
/// //| height: 6cm
/// #let d = range(0, 10).map(i => (x: i, y: i * 0.5))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 2pt),),
///   theme: theme(
///     axis-title: element-text(size: 12pt),
///     panel-background: element-rect(fill: rgb("#f7f0e7")),
///     panel-grid: element-line(colour: rgb("#d9cfbf")),
///   ),
/// )
/// ```
///
/// @see @theme-grey, @theme-minimal, @theme-classic, @theme-void, @element-text, @element-line, @element-rect, @element-blank
#let theme(..fields) = {
  let out = (kind: "theme", name: "custom")
  for (k, v) in fields.named().pairs() {
    out = _apply-element(out, k, v)
  }
  out
}
