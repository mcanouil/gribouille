// Label formatter helpers for the `labels:` callback on scales.
//
// Each helper returns a closure suitable for `scale-*(labels: ...)`. The
// closure takes a single break value and returns either a plain string,
// content, or a `typst()`-tagged value when it produces math markup.
//
// Compose freely with `typst()` on the aes side: when the originating
// aesthetic mapping is typst-tagged, plain-string callback returns are
// wrapped automatically by the render path so they evaluate as markup.

#import "./errors.typ": check, fail-type
#import "./types.typ": parse-number
#import "./typst-markup.typ": typst

#let _format-number-impl(n, big-mark: ",", decimal-mark: ".", digits: auto) = {
  if n == none { return none }
  let value = if type(n) == str { parse-number(n) } else { n }
  if value == none { return str(n) }
  let abs-val = if value < 0 { -value } else { value }
  let d = if digits == auto { 6 } else { int(digits) }
  // Round before splitting so a fraction that rounds up to a whole unit
  // carries into the integer part instead of being dropped.
  let abs-rounded = calc.round(abs-val, digits: d)
  let int-part = int(abs-rounded)
  let frac-part = abs-rounded - int-part
  let int-str = str(int-part)
  let with-sep = if big-mark == "" { int-str } else {
    let chars = int-str.clusters().rev()
    let groups = ()
    let buf = ""
    for (i, c) in chars.enumerate() {
      buf = c + buf
      if calc.rem(i + 1, 3) == 0 and i + 1 < chars.len() {
        groups.push(buf)
        buf = ""
      }
    }
    if buf != "" { groups.push(buf) }
    groups.rev().join(big-mark)
  }
  let frac-str = if (digits == auto and frac-part == 0) or digits == 0 {
    ""
  } else {
    let scaled = calc.round(frac-part * calc.pow(10, d))
    let s = str(int(scaled))
    while s.len() < d { s = "0" + s }
    if digits == auto {
      while s.len() > 0 and s.ends-with("0") {
        s = s.slice(0, s.len() - 1)
      }
      if s == "" { "" } else { decimal-mark + s }
    } else {
      decimal-mark + s
    }
  }
  let sign = if value < 0 { "-" } else { "" }
  sign + with-sep + frac-str
}

/// Format a numeric break with optional thousands separator and decimals.
///
/// Returns a closure suitable for `scale-*(labels: ...)`. Non-numeric
/// values pass through `str()`.
///
/// \@category Helpers
/// \@subcategory Formatters
/// \@stability stable
///
/// \@param big-mark Thousands separator (e.g., `","` for English).
///
/// \@param decimal-mark Decimal separator (e.g., `"."` for English).
///
/// \@param digits Decimal digits to keep, or `auto` to drop trailing zeros.
///
/// \@param prefix String prepended to every formatted value.
///
/// \@param suffix String appended to every formatted value.
///
/// \@returns A closure `value => string`.
///
/// \@examples Format y-axis breaks with English thousands separators.
/// ```
/// //| alt: "Scatter chart of two points with y-axis tick labels formatted as English thousand-separated numbers via format-number."
/// #plot(
///   data: ((x: 1, y: 1234.5), (x: 2, y: 23456.7)),
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(),),
///   scales: scales(y: scale-continuous(labels: format-number())),
///   width: 8cm,
///   height: 5cm,
/// )
/// ```
#let format-number(
  big-mark: ",",
  decimal-mark: ".",
  digits: auto,
  prefix: "",
  suffix: "",
) = value => {
  let formatted = _format-number-impl(
    value,
    big-mark: big-mark,
    decimal-mark: decimal-mark,
    digits: digits,
  )
  if formatted == none { return none }
  prefix + formatted + suffix
}

/// Shorthand for `format-number(big-mark: ",")`.
///
/// \@category Helpers
/// \@subcategory Formatters
/// \@stability stable
///
/// \@param digits Decimal digits to keep, or `auto` to drop trailing zeros.
///
/// \@param prefix String prepended to every formatted value.
///
/// \@param suffix String appended to every formatted value.
///
/// \@returns A closure `value => string`.
///
/// \@examples Thread `format-comma()` into `scale-continuous(labels: ...)`
/// so y-axis breaks render with English thousands separators.
/// ```
/// //| alt: "Scatter chart of three points with y-axis tick labels rendered with comma thousands separators via format-comma."
/// #plot(
///   data: ((x: 1, y: 1234), (x: 2, y: 23456), (x: 3, y: 345678)),
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 3pt),),
///   scales: scales(y: scale-continuous(labels: format-comma())),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@format-number, \@format-currency
#let format-comma(digits: auto, prefix: "", suffix: "") = format-number(
  big-mark: ",",
  decimal-mark: ".",
  digits: digits,
  prefix: prefix,
  suffix: suffix,
)

/// Format a numeric break as a percentage.
///
/// Multiplies the value by `scale` (default `100`) before formatting and
/// appends `suffix`.
///
/// \@category Helpers
/// \@subcategory Formatters
/// \@stability stable
///
/// \@param scale Multiplier applied before formatting.
///
/// \@param suffix Trailing string (default `"%"`).
///
/// \@param big-mark Thousands separator.
///
/// \@param decimal-mark Decimal separator.
///
/// \@param digits Decimal digits to keep.
///
/// \@returns A closure `value => string`.
///
/// \@examples Map proportions in `[0, 1]` to percent labels on the y-axis.
/// ```
/// //| alt: "Bar chart of three discrete groups a, b, c with y-axis tick labels rendered as percentages from proportions via format-percent."
/// #plot(
///   data: ((g: "a", y: 0.1), (g: "b", y: 0.45), (g: "c", y: 0.9)),
///   mapping: aes(x: "g", y: "y"),
///   layers: (geom-col(),),
///   scales: scales(y: scale-continuous(labels: format-percent())),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@format-number, \@format-currency
#let format-percent(
  scale: 100,
  suffix: "%",
  big-mark: "",
  decimal-mark: ".",
  digits: 0,
) = value => {
  if value == none { return none }
  let v = if type(value) == str { parse-number(value) } else { value }
  if v == none { return str(value) }
  (
    _format-number-impl(
      v * scale,
      big-mark: big-mark,
      decimal-mark: decimal-mark,
      digits: digits,
    )
      + suffix
  )
}

/// Format a numeric break as currency.
///
/// Defaults to a leading dollar sign and English thousands separator.
///
/// \@category Helpers
/// \@subcategory Formatters
/// \@stability stable
///
/// \@param symbol Currency symbol prepended to the value.
///
/// \@param big-mark Thousands separator.
///
/// \@param decimal-mark Decimal separator.
///
/// \@param digits Decimal digits to keep.
///
/// \@returns A closure `value => string`.
///
/// \@examples Pin a leading pound sign and two decimal digits on the y-axis
/// labels.
/// ```
/// //| alt: "Scatter chart of three points with y-axis tick labels rendered as pound-denominated currency values via format-currency."
/// #plot(
///   data: ((x: 1, y: 1234.5), (x: 2, y: 7890.1), (x: 3, y: 12345.6)),
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 3pt),),
///   scales: scales(y: scale-continuous(labels: format-currency(symbol: "£"))),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@format-number, \@format-comma
#let format-currency(
  symbol: "$",
  big-mark: ",",
  decimal-mark: ".",
  digits: 2,
) = value => {
  let formatted = _format-number-impl(
    value,
    big-mark: big-mark,
    decimal-mark: decimal-mark,
    digits: digits,
  )
  if formatted == none { return none }
  symbol + formatted
}

/// Format a numeric break in scientific notation as Typst math.
///
/// Returns a `typst()`-tagged string so the render path evaluates the
/// result as Typst math markup. Values within `[10^(-3), 10^3)` are
/// formatted as plain numbers via `format-number`.
///
/// \@category Helpers
/// \@subcategory Formatters
/// \@stability stable
///
/// \@param digits Significant decimal digits in the mantissa.
///
/// \@returns A closure `value => content`.
///
/// \@examples Spread y across decades so the labels switch into Typst-math
/// scientific notation.
/// ```
/// //| alt: "Scatter chart of four points spanning four decades on y with axis labels rendered in Typst-math scientific notation via format-scientific."
/// #plot(
///   data: ((x: 1, y: 1e-4), (x: 2, y: 1e-2), (x: 3, y: 1), (x: 4, y: 1e4)),
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 3pt),),
///   scales: scales(y: scale-continuous(labels: format-scientific(digits: 2))),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@format-number, \@typst
#let format-scientific(digits: 2) = value => {
  if value == none { return none }
  let v = if type(value) == str { parse-number(value) } else { value }
  if v == none { return str(value) }
  if v == 0 { return typst("$0$") }
  let abs-v = if v < 0 { -v } else { v }
  if abs-v >= 1e-3 and abs-v < 1e3 {
    let formatted = _format-number-impl(v, digits: digits)
    return typst("$" + formatted + "$")
  }
  let exp = int(calc.floor(calc.log(abs-v, base: 10)))
  let mantissa = v / calc.pow(10, exp)
  // Rounding the mantissa can push it to 10 (e.g. 9.999 -> 10.00); carry the
  // overflow into the exponent so the notation stays in [1, 10).
  if calc.abs(calc.round(mantissa, digits: digits)) >= 10 {
    exp += 1
    mantissa = v / calc.pow(10, exp)
  }
  let m-str = _format-number-impl(mantissa, digits: digits)
  typst("$" + m-str + " times 10^(" + str(exp) + ")$")
}

/// Format a numeric break as a power of a base, in Typst math.
///
/// Returns a `typst()`-tagged string, so a break that is an exact power reads
/// as `10^3` with a real superscript. A break that is not an exact power keeps
/// a mantissa, which is what an automatic log axis needs: its breaks fall on
/// 1, 2, and 5 times a power. The counterpart of `scales::label_log()`, except
/// that `scales` writes a fractional exponent where this keeps the mantissa.
///
/// A secondary axis formats the value it has already transformed, so a
/// `dup-axis` or `sec-axis` needs its own `labels:` to match the primary.
///
/// \@category Helpers
/// \@subcategory Formatters
/// \@stability stable
///
/// \@param base Base of the powers; must be above 1.
///
/// \@param digits Significant decimal digits in the mantissa.
///
/// \@returns A closure `value => content`.
///
/// \@examples Decade labels on a log axis, written as powers of ten.
/// ```
/// //| alt: "Scatter chart of seven growing values with a log y axis whose labels read as powers of ten."
/// #plot(
///   data: (
///     (x: 1, y: 3), (x: 2, y: 12), (x: 3, y: 60), (x: 4, y: 250),
///     (x: 5, y: 900), (x: 6, y: 4000), (x: 7, y: 20000),
///   ),
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 3pt),),
///   scales: scales(y: scale-log10(labels: format-log())),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@format-scientific, \@breaks-log, \@typst
#let format-log(base: 10, digits: 3) = {
  if type(base) != int and type(base) != float {
    fail-type("format-log", "base", base, "a number")
  }
  check(base > 1, "format-log", "base must be above 1; got " + repr(base))
  let base-str = _format-number-impl(base, big-mark: "")
  value => {
    if value == none { return none }
    let v = if type(value) == str { parse-number(value) } else { value }
    if v == none { return str(value) }
    // A logarithm is undefined at or below zero. Such a break belongs to a
    // linear axis, so label it plainly rather than fail.
    if v <= 0 { return _format-number-impl(v, big-mark: "") }
    let e = calc.log(v, base: base)
    let rounded = calc.round(e)
    // `calc.log(1000, base: 10)` gives 2.9999999999999996, so an exact power is
    // recognised by proximity rather than by equality.
    if calc.abs(e - rounded) < 1e-9 {
      return typst("$" + base-str + "^(" + str(int(rounded)) + ")$")
    }
    let exp = int(calc.floor(e))
    let mantissa = calc.round(v / calc.pow(float(base), exp), digits: digits)
    // Rounding can push the mantissa up to the base itself; carry the overflow
    // into the exponent so the notation stays below one whole step.
    if mantissa >= base {
      exp += 1
      mantissa = calc.round(v / calc.pow(float(base), exp), digits: digits)
    }
    let m-str = _format-number-impl(mantissa, big-mark: "")
    if exp == 0 { return typst("$" + m-str + "$") }
    typst("$" + m-str + " times " + base-str + "^(" + str(exp) + ")$")
  }
}

#let _lower-clusters = "abcdefghijklmnopqrstuvwxyz".clusters()
#let _upper-clusters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".clusters()
#let _to-upper-map = {
  let m = (:)
  for (i, c) in _lower-clusters.enumerate() {
    m.insert(c, _upper-clusters.at(i))
  }
  m
}
#let _to-lower-map = {
  let m = (:)
  for (i, c) in _upper-clusters.enumerate() {
    m.insert(c, _lower-clusters.at(i))
  }
  m
}

#let _to-upper(s) = (
  s.clusters().map(c => _to-upper-map.at(c, default: c)).join()
)
#let _to-lower(s) = (
  s.clusters().map(c => _to-lower-map.at(c, default: c)).join()
)

/// Title-case a string break: capitalise the first letter of each
/// space-separated word.
///
/// \@category Helpers
/// \@subcategory Formatters
/// \@stability stable
///
/// \@returns A closure `value => string`.
///
/// \@examples Title-case discrete x-axis levels without renaming the
/// underlying data.
/// ```
/// //| alt: "Bar chart of three groups with discrete x-axis tick labels title-cased to Alpha, Beta, Gamma while the underlying levels stay alpha, beta, gamma."
/// #let d = ((g: "alpha", y: 4), (g: "beta", y: 7), (g: "gamma", y: 3))
/// #plot(
///   data: d,
///   mapping: aes(x: "g", y: "y"),
///   layers: (geom-col(),),
///   scales: scales(x: scale-discrete(labels: format-title())),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@format-upper, \@format-lower, \@format-wrap
#let format-title() = value => {
  if value == none { return none }
  let s = str(value)
  if s == "" { return s }
  let words = s.split(" ")
  let out = words.map(w => {
    if w == "" { return w }
    let first = w.first()
    let rest = w.slice(1)
    _to-upper(first) + _to-lower(rest)
  })
  out.join(" ")
}

/// Upper-case a string break (ASCII letters only).
///
/// \@category Helpers
/// \@subcategory Formatters
/// \@stability stable
///
/// \@returns A closure `value => string`.
///
/// \@examples Upper-case the discrete x-axis tick labels via the closure.
/// ```
/// //| alt: "Bar chart of three groups with discrete x-axis tick labels upper-cased to ALPHA, BETA, GAMMA via format-upper."
/// #let d = ((g: "alpha", y: 4), (g: "beta", y: 7), (g: "gamma", y: 3))
/// #plot(
///   data: d,
///   mapping: aes(x: "g", y: "y"),
///   layers: (geom-col(),),
///   scales: scales(x: scale-discrete(labels: format-upper())),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@format-lower, \@format-title
#let format-upper() = value => {
  if value == none { return none }
  _to-upper(str(value))
}

/// Lower-case a string break (ASCII letters only).
///
/// \@category Helpers
/// \@subcategory Formatters
/// \@stability stable
///
/// \@returns A closure `value => string`.
///
/// \@examples Lower-case the discrete x-axis tick labels via the closure.
/// ```
/// //| alt: "Bar chart of three groups with discrete x-axis tick labels lower-cased to alpha, beta, gamma via format-lower."
/// #let d = ((g: "ALPHA", y: 4), (g: "BETA", y: 7), (g: "GAMMA", y: 3))
/// #plot(
///   data: d,
///   mapping: aes(x: "g", y: "y"),
///   layers: (geom-col(),),
///   scales: scales(x: scale-discrete(labels: format-lower())),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@format-upper, \@format-title
#let format-lower() = value => {
  if value == none { return none }
  _to-lower(str(value))
}

/// Soft-wrap a long string by inserting a newline at word boundaries.
///
/// \@category Helpers
/// \@subcategory Formatters
/// \@stability stable
///
/// \@param width Maximum line width in characters.
///
/// \@returns A closure `value => string`.
///
/// \@examples Soft-wrap long discrete tick labels onto multiple lines at a
/// width of eight characters.
/// ```
/// //| alt: "Bar chart of three groups whose long discrete x-axis tick labels are soft-wrapped at width 8 onto two lines each via format-wrap."
/// #let d = (
///   (g: "alpha quadrant", y: 4),
///   (g: "beta sector", y: 7),
///   (g: "gamma frontier", y: 3),
/// )
/// #plot(
///   data: d,
///   mapping: aes(x: "g", y: "y"),
///   layers: (geom-col(),),
///   scales: scales(x: scale-discrete(labels: format-wrap(width: 8))),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@format-title, \@label-wrap
#let format-wrap(width: 20) = value => {
  if value == none { return none }
  let s = str(value)
  if s.len() <= width { return s }
  let words = s.split(" ")
  let lines = ()
  let line = ""
  for w in words {
    if line == "" {
      line = w
    } else if line.len() + 1 + w.len() <= width {
      line = line + " " + w
    } else {
      lines.push(line)
      line = w
    }
  }
  if line != "" { lines.push(line) }
  lines.join("\n")
}

// Compact numeric tick formatter shared by axis ticks, secondary-axis ticks,
// and legend colour-bar tick labels. Integers print as integers; near-integer
// floats round to the nearest integer; everything else prints with up to
// three significant decimal places.
#let format-break(n) = {
  if type(n) == int { return str(n) }
  if calc.abs(n - calc.round(n)) < 1e-9 { return str(calc.round(n)) }
  str(calc.round(n, digits: 3))
}
