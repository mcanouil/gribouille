///! Public aesthetic-agnostic scale constructors.
///!
///! Each constructor returns a deferred stub `(kind: "scale", name: ...,
///! args: ...)`. The aesthetic is supplied by the `scales()` key, which
///! dispatches the stub to the matching internal builder (see scale/bind.typ).
///! Pass these to \@plot through \@scales, e.g.
///! `scales(x: scale-log10(), colour: scale-viridis-d())`.

// The stub defers `args` unvalidated because the valid key set depends on
// the aesthetic, which is only known when `scales()` binds the stub.
// `bind-scale` (scale/bind.typ) then checks every named key against the
// bound builder's key tuple and rejects positional arguments before
// spreading, so a misspelled argument fails with a scales-scoped message
// listing the valid keys for that scale and aesthetic.
#let _stub(family, args) = (kind: "scale", name: family, args: args)

// Generic scales ------------------------------------------------------------

/// Continuous scale for any continuous aesthetic.
///
/// Keyed to `x`/`y` it controls the axis (`limits`, `breaks`, `transform`,
/// `expand`, `secondary`); keyed to `colour`/`fill` it sets the `palette`;
/// keyed to `size`/`alpha`/`linewidth`/`stroke` it sets the output `range`.
///
/// \@category Scales
/// \@subcategory Generic scales
/// \@stability stable
/// \@since 0.5.0
///
/// \@param args Named arguments forwarded to the bound scale (e.g. `name`, `limits`, `breaks`, `labels`, and aesthetic-specific keys such as `transform` or `range`).
///
/// \@returns Deferred scale spec consumed by \@scales.
///
/// \@examples Pin the x domain and rename the axis with a continuous scale.
/// ```
/// //| alt: "Scatter chart of ten squared values with the x axis renamed to Index and pinned to the range 0 through 12."
/// #let d = range(1, 11).map(i => (x: i, y: i * i))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 2pt),),
///   scales: scales(x: scale-continuous(name: "Index", limits: (0, 12))),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@scales, \@scale-discrete, \@scale-binned
#let scale-continuous(..args) = _stub("continuous", args)

/// Discrete scale for any categorical aesthetic.
///
/// Keyed to `x`/`y` it orders the axis levels; keyed to `colour`/`fill`,
/// `shape`, or `linetype` it assigns the per-level palette, defaulting to that
/// aesthetic's built-in set.
///
/// \@category Scales
/// \@subcategory Generic scales
/// \@stability stable
/// \@since 0.5.0
///
/// \@param args Named arguments forwarded to the bound scale (e.g. `name`, `limits`, `labels`, `palette`).
///
/// \@returns Deferred scale spec consumed by \@scales.
///
/// \@examples Force the level order on a discrete x axis.
/// ```
/// //| alt: "Bar chart with three categorical bars ordered a, b, c on a discrete x axis with heights 5, 3, 2."
/// #let d = ((grp: "b", y: 3), (grp: "a", y: 5), (grp: "c", y: 2))
/// #plot(
///   data: d,
///   mapping: aes(x: "grp", y: "y"),
///   layers: (geom-col(),),
///   scales: scales(x: scale-discrete(limits: ("a", "b", "c"))),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@scales, \@scale-continuous, \@scale-manual
#let scale-discrete(..args) = _stub("discrete", args)

/// Binned scale that quantises a continuous variable into `n-breaks` bins.
///
/// Valid on `x`/`y`, `size`, `alpha`, `linewidth`, `stroke`, `shape`, and
/// `linetype`; the per-row mapping stays continuous while the legend or axis
/// snaps to bin midpoints.
///
/// \@category Scales
/// \@subcategory Generic scales
/// \@stability stable
/// \@since 0.5.0
///
/// \@param args Named arguments forwarded to the bound scale (e.g. `n-breaks`, `breaks`, `name`, `limits`, and `range` or `palette`).
///
/// \@returns Deferred scale spec consumed by \@scales.
///
/// \@examples Quantise the x axis into five equal-width bins.
/// ```
/// //| alt: "Scatter chart of a sinusoidal series along an x axis cut into five equal-width bins whose midpoints place the tick labels."
/// #let d = range(0, 30).map(i => (x: i / 3.0, y: calc.sin(i / 4.0)))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 2pt),),
///   scales: scales(x: scale-binned(n-breaks: 5)),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@scales, \@scale-continuous
#let scale-binned(..args) = _stub("binned", args)

/// Manual discrete scale: supply a per-level array of output values.
///
/// Valid on `colour`/`fill`, `alpha`, `size`, `linewidth`, `stroke`, `shape`,
/// and `linetype`. Pass the outputs through `values`.
///
/// \@category Scales
/// \@subcategory Generic scales
/// \@stability stable
/// \@since 0.5.0
///
/// \@param args Named arguments forwarded to the bound scale (e.g. `values`, `name`, `limits`, `labels`).
///
/// \@returns Deferred scale spec consumed by \@scales.
///
/// \@examples Assign explicit per-level colours with a manual scale.
/// ```
/// //| alt: "Scatter chart of three groups coloured by a manual palette pinning a to orange, b to purple, and c to teal."
/// #let d = ((x: 1, y: 1, g: "a"), (x: 2, y: 2, g: "b"), (x: 3, y: 3, g: "c"))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", colour: "g"),
///   layers: (geom-point(size: 3pt),),
///   scales: scales(colour: scale-manual(
///     values: (rgb("#ff8c00"), rgb("#800080"), rgb("#008B8B")),
///   )),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@scales, \@scale-discrete, \@scale-identity
#let scale-manual(..args) = _stub("manual", args)

/// Identity scale: use each row's value as the visual output directly.
///
/// Valid on `colour`/`fill`, `alpha`, `size`, `linewidth`, `stroke`, `shape`,
/// and `linetype`. Draws no legend.
///
/// \@category Scales
/// \@subcategory Generic scales
/// \@stability stable
/// \@since 0.5.0
///
/// \@param args Named arguments forwarded to the bound scale (e.g. `name`).
///
/// \@returns Deferred scale spec consumed by \@scales.
///
/// \@examples Use a column of colours directly as the fill with an identity scale.
/// ```
/// //| alt: "Scatter chart of three points whose fill colours come straight from the c column as red, green, and blue, drawn with no legend."
/// #let d = (
///   (x: 1, y: 1, c: rgb("#e41a1c")),
///   (x: 2, y: 2, c: rgb("#4daf4a")),
///   (x: 3, y: 3, c: rgb("#377eb8")),
/// )
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", fill: "c"),
///   layers: (geom-point(size: 4pt),),
///   scales: scales(fill: scale-identity()),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@scales, \@scale-manual
#let scale-identity(..args) = _stub("identity", args)

// Position transform and temporal scales ------------------------------------

/// Position scale on a base-10 log axis (`x` or `y`).
///
/// All mapped values must be strictly positive.
///
/// \@category Scales
/// \@subcategory Position scales
/// \@stability stable
/// \@since 0.5.0
///
/// \@param args Named arguments forwarded to the axis scale (e.g. `name`, `limits`, `breaks`, `minor-breaks`, `n-minor`, `labels`).
///
/// \@returns Deferred scale spec consumed by \@scales.
///
/// \@examples Compress an exponential growth curve onto a log-10 y axis.
/// ```
/// //| alt: "Scatter chart of ten exponential values where a log10 y axis compresses the steep curve into an evenly spaced sequence of points."
/// #let d = range(1, 11).map(i => (x: i, y: calc.pow(2, i)))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 2pt),),
///   scales: scales(y: scale-log10(name: "Value")),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@scales, \@scale-continuous, \@scale-sqrt
#let scale-log10(..args) = _stub("log10", args)

/// Position scale on a square-root axis (`x` or `y`).
///
/// All mapped values must be non-negative.
///
/// \@category Scales
/// \@subcategory Position scales
/// \@stability stable
/// \@since 0.5.0
///
/// \@param args Named arguments forwarded to the axis scale (e.g. `name`, `limits`, `breaks`, `minor-breaks`, `n-minor`, `labels`).
///
/// \@returns Deferred scale spec consumed by \@scales.
///
/// \@examples Straighten a quadratic relationship on a square-root x axis.
/// ```
/// //| alt: "Scatter chart of eleven points on a square-root x axis that spreads small values and compresses large ones into an even sequence."
/// #let d = range(0, 11).map(i => (x: i * i, y: i))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 2pt),),
///   scales: scales(x: scale-sqrt(name: "x")),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@scales, \@scale-continuous, \@scale-log10
#let scale-sqrt(..args) = _stub("sqrt", args)

/// Position scale with the axis direction reversed (`x` or `y`).
///
/// Tick labels stay in data units; only the axis direction flips.
///
/// \@category Scales
/// \@subcategory Position scales
/// \@stability stable
/// \@since 0.5.0
///
/// \@param args Named arguments forwarded to the axis scale (e.g. `name`, `limits`, `breaks`, `minor-breaks`, `n-minor`, `labels`).
///
/// \@returns Deferred scale spec consumed by \@scales.
///
/// \@examples Reverse the y axis so larger values sit at the bottom.
/// ```
/// //| alt: "Scatter chart of ten diagonal points on a reversed y axis where larger values sit at the bottom while tick labels stay in data units."
/// #let d = range(1, 11).map(i => (x: i, y: i))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 2pt),),
///   scales: scales(y: scale-reverse(name: "Rank")),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@scales, \@scale-continuous
#let scale-reverse(..args) = _stub("reverse", args)

/// Temporal position scale formatting axis labels as dates (`x` or `y`).
///
/// Column values may be numeric days since 2000-01-01 or ISO-8601 `YYYY-MM-DD`
/// strings.
///
/// \@category Scales
/// \@subcategory Position scales
/// \@stability stable
/// \@since 0.5.0
///
/// \@param args Named arguments forwarded to the axis scale (e.g. `name`, `limits`, `breaks`, `labels`, `expand`, `date-format`).
///
/// \@returns Deferred scale spec consumed by \@scales.
///
/// \@examples Format an x axis of numeric days since 2000-01-01 as year-month ticks.
/// ```
/// //| alt: "Line-and-point chart of twelve rising values on an x axis showing year-month ticks decoded from numeric days since 2000-01-01."
/// #let d = range(0, 12).map(i => (x: 8766 + 30 * i, y: i))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-line(), geom-point(size: 2pt)),
///   scales: scales(x: scale-date(date-format: "[year]-[month repr:numerical]")),
///   width: 12cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@scales, \@scale-datetime, \@scale-time
#let scale-date(..args) = _stub("date", args)

/// Temporal position scale formatting axis labels as datetimes (`x` or `y`).
///
/// \@category Scales
/// \@subcategory Position scales
/// \@stability stable
/// \@since 0.5.0
///
/// \@param args Named arguments forwarded to the axis scale (e.g. `name`, `limits`, `breaks`, `labels`, `expand`, `date-format`).
///
/// \@returns Deferred scale spec consumed by \@scales.
///
/// \@examples Label a y axis of elapsed seconds as clock times.
/// ```
/// //| alt: "Line chart of seven rising points on a y axis whose ticks read as hour-and-minute clock times decoded from elapsed seconds."
/// #let d = range(0, 7).map(i => (x: i, y: i * 3600))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-line(),),
///   scales: scales(y: scale-datetime(date-format: "[hour]:[minute]")),
///   width: 12cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@scales, \@scale-date, \@scale-time
#let scale-datetime(..args) = _stub("datetime", args)

/// Temporal position scale formatting axis labels as times (`x` or `y`).
///
/// \@category Scales
/// \@subcategory Position scales
/// \@stability stable
/// \@since 0.5.0
///
/// \@param args Named arguments forwarded to the axis scale (e.g. `name`, `limits`, `breaks`, `labels`, `expand`, `date-format`).
///
/// \@returns Deferred scale spec consumed by \@scales.
///
/// \@examples Label a y axis of elapsed seconds as times of day.
/// ```
/// //| alt: "Line chart of seven rising points on a y axis whose ticks read as hour-and-minute times decoded from elapsed seconds."
/// #let d = range(0, 7).map(i => (x: i, y: i * 900))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-line(),),
///   scales: scales(y: scale-time()),
///   width: 12cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@scales, \@scale-date, \@scale-datetime
#let scale-time(..args) = _stub("time", args)

// Colour and fill palette scales --------------------------------------------

/// Discrete viridis colour/fill scale.
///
/// `option` selects `"viridis"`, `"magma"`, `"plasma"`, `"inferno"`, or
/// `"cividis"`.
///
/// \@category Scales
/// \@subcategory Colour and fill scales
/// \@stability stable
/// \@since 0.5.0
///
/// \@param args Named arguments forwarded to the colour/fill scale (e.g. `option`, `name`, `limits`, `labels`).
///
/// \@returns Deferred scale spec consumed by \@scales.
///
/// \@examples Colour three groups with a discrete viridis palette.
/// ```
/// //| alt: "Scatter chart of three points coloured by group with the discrete viridis palette."
/// #let d = ((x: 1, y: 1, g: "a"), (x: 2, y: 2, g: "b"), (x: 3, y: 3, g: "c"))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", colour: "g"),
///   layers: (geom-point(size: 3pt),),
///   scales: scales(colour: scale-viridis-d()),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@scales, \@scale-viridis-c, \@scale-viridis-b
#let scale-viridis-d(..args) = _stub("viridis-d", args)

/// Continuous viridis colour/fill scale.
///
/// \@category Scales
/// \@subcategory Colour and fill scales
/// \@stability stable
/// \@since 0.5.0
///
/// \@param args Named arguments forwarded to the colour/fill scale (e.g. `option`, `name`, `limits`, `breaks`, `labels`).
///
/// \@returns Deferred scale spec consumed by \@scales.
///
/// \@examples Map a numeric column onto a continuous viridis fill.
/// ```
/// //| alt: "Scatter chart of seven diagonal points whose fill tracks a numeric column along the continuous viridis palette."
/// #let d = range(1, 8).map(i => (x: i, y: i, w: i))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", fill: "w"),
///   layers: (geom-point(size: 5pt),),
///   scales: scales(fill: scale-viridis-c(option: "magma")),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@scales, \@scale-viridis-d, \@scale-viridis-b
#let scale-viridis-c(..args) = _stub("viridis-c", args)

/// Binned viridis colour/fill scale.
///
/// \@category Scales
/// \@subcategory Colour and fill scales
/// \@stability stable
/// \@since 0.5.0
///
/// \@param args Named arguments forwarded to the colour/fill scale (e.g. `option`, `n-breaks`, `breaks`, `name`, `limits`, `labels`).
///
/// \@returns Deferred scale spec consumed by \@scales.
///
/// \@examples Bin a numeric column onto a stepped viridis fill.
/// ```
/// //| alt: "Scatter chart of twelve diagonal points whose fill steps through four binned viridis bands."
/// #let d = range(0, 12).map(i => (x: i, y: i, w: i + 1))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", fill: "w"),
///   layers: (geom-point(size: 5pt),),
///   scales: scales(fill: scale-viridis-b(n-breaks: 4)),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@scales, \@scale-viridis-c, \@scale-steps
#let scale-viridis-b(..args) = _stub("viridis-b", args)

/// Discrete ColorBrewer colour/fill scale.
///
/// `palette` names a ColorBrewer set such as `"Set1"` or `"Spectral"`.
///
/// \@category Scales
/// \@subcategory Colour and fill scales
/// \@stability stable
/// \@since 0.5.0
///
/// \@param args Named arguments forwarded to the colour/fill scale (e.g. `palette`, `name`, `limits`, `labels`).
///
/// \@returns Deferred scale spec consumed by \@scales.
///
/// \@examples Colour groups with a discrete ColorBrewer palette.
/// ```
/// //| alt: "Scatter chart of three points coloured by group with the ColorBrewer Set1 palette."
/// #let d = ((x: 1, y: 1, g: "a"), (x: 2, y: 2, g: "b"), (x: 3, y: 3, g: "c"))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", colour: "g"),
///   layers: (geom-point(size: 3pt),),
///   scales: scales(colour: scale-brewer(palette: "Set1")),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@scales, \@scale-distiller, \@scale-fermenter
#let scale-brewer(..args) = _stub("brewer", args)

/// Discrete Okabe-Ito colourblind-safe colour/fill scale.
///
/// \@category Scales
/// \@subcategory Colour and fill scales
/// \@stability stable
/// \@since 0.5.0
///
/// \@param args Named arguments forwarded to the colour/fill scale (e.g. `name`, `limits`, `labels`).
///
/// \@returns Deferred scale spec consumed by \@scales.
///
/// \@examples Colour groups with the colourblind-safe Okabe-Ito palette.
/// ```
/// //| alt: "Scatter chart of three points coloured by group with the Okabe-Ito colourblind-safe palette."
/// #let d = ((x: 1, y: 1, g: "a"), (x: 2, y: 2, g: "b"), (x: 3, y: 3, g: "c"))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", colour: "g"),
///   layers: (geom-point(size: 3pt),),
///   scales: scales(colour: scale-okabe-ito()),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@scales, \@scale-brewer
#let scale-okabe-ito(..args) = _stub("okabe-ito", args)

/// Two-colour continuous gradient colour/fill scale.
///
/// Interpolates between `low` and `high`.
///
/// \@category Scales
/// \@subcategory Colour and fill scales
/// \@stability stable
/// \@since 0.5.0
///
/// \@param args Named arguments forwarded to the colour/fill scale (e.g. `low`, `high`, `name`, `limits`, `breaks`, `labels`).
///
/// \@returns Deferred scale spec consumed by \@scales.
///
/// \@examples Interpolate a numeric fill between two colours.
/// ```
/// //| alt: "Scatter chart of seven diagonal points whose fill interpolates between a low and high colour with a numeric column."
/// #let d = range(1, 8).map(i => (x: i, y: i, w: i))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", fill: "w"),
///   layers: (geom-point(size: 5pt),),
///   scales: scales(fill: scale-gradient(low: rgb("#132B43"), high: rgb("#56B1F7"))),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@scales, \@scale-gradient2, \@scale-gradientn
#let scale-gradient(..args) = _stub("gradient", args)

/// Diverging three-colour gradient colour/fill scale.
///
/// Interpolates `low`-`mid`-`high` around `midpoint`.
///
/// \@category Scales
/// \@subcategory Colour and fill scales
/// \@stability stable
/// \@since 0.5.0
///
/// \@param args Named arguments forwarded to the colour/fill scale (e.g. `low`, `mid`, `high`, `midpoint`, `name`, `limits`, `breaks`, `labels`).
///
/// \@returns Deferred scale spec consumed by \@scales.
///
/// \@examples Diverge a signed numeric fill around zero.
/// ```
/// //| alt: "Scatter chart of eleven diagonal points whose fill diverges from a low colour through white to a high colour around a midpoint of zero."
/// #let d = range(0, 11).map(i => (x: i, y: i, w: i - 5))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", fill: "w"),
///   layers: (geom-point(size: 5pt),),
///   scales: scales(fill: scale-gradient2(midpoint: 0)),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@scales, \@scale-gradient, \@scale-gradientn
#let scale-gradient2(..args) = _stub("gradient2", args)

/// N-colour continuous gradient colour/fill scale.
///
/// Interpolates through the `colours` array.
///
/// \@category Scales
/// \@subcategory Colour and fill scales
/// \@stability stable
/// \@since 0.5.0
///
/// \@param args Named arguments forwarded to the colour/fill scale (e.g. `colours`, `name`, `limits`, `breaks`, `labels`).
///
/// \@returns Deferred scale spec consumed by \@scales.
///
/// \@examples Interpolate a numeric fill through several colours.
/// ```
/// //| alt: "Scatter chart of seven diagonal points whose fill interpolates through a black, grey, and white colour ramp."
/// #let d = range(1, 8).map(i => (x: i, y: i, w: i))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", fill: "w"),
///   layers: (geom-point(size: 5pt),),
///   scales: scales(fill: scale-gradientn(
///     colours: (rgb("#000000"), rgb("#888888"), rgb("#ffffff")),
///   )),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@scales, \@scale-gradient, \@scale-gradient2
#let scale-gradientn(..args) = _stub("gradientn", args)

/// Discrete greyscale colour/fill scale.
///
/// `start` and `end` bound the grey range in `[0, 1]`.
///
/// \@category Scales
/// \@subcategory Colour and fill scales
/// \@stability stable
/// \@since 0.5.0
///
/// \@param args Named arguments forwarded to the colour/fill scale (e.g. `start`, `end`, `name`, `limits`, `labels`).
///
/// \@returns Deferred scale spec consumed by \@scales.
///
/// \@examples Colour groups along a discrete greyscale ramp.
/// ```
/// //| alt: "Scatter chart of three points coloured by group along a discrete greyscale ramp from light to dark."
/// #let d = ((x: 1, y: 1, g: "a"), (x: 2, y: 2, g: "b"), (x: 3, y: 3, g: "c"))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", colour: "g"),
///   layers: (geom-point(size: 3pt),),
///   scales: scales(colour: scale-grey(start: 0.1, end: 0.8)),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@scales, \@scale-brewer
#let scale-grey(..args) = _stub("grey", args)

/// Discrete evenly-spaced HCL hue colour/fill scale.
///
/// \@category Scales
/// \@subcategory Colour and fill scales
/// \@stability stable
/// \@since 0.5.0
///
/// \@param args Named arguments forwarded to the colour/fill scale (e.g. `hue`, `chroma`, `luminance`, `name`, `limits`, `labels`).
///
/// \@returns Deferred scale spec consumed by \@scales.
///
/// \@examples Colour groups with evenly-spaced HCL hues.
/// ```
/// //| alt: "Scatter chart of three points coloured by group with evenly spaced HCL hues."
/// #let d = ((x: 1, y: 1, g: "a"), (x: 2, y: 2, g: "b"), (x: 3, y: 3, g: "c"))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", colour: "g"),
///   layers: (geom-point(size: 3pt),),
///   scales: scales(colour: scale-hue()),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@scales, \@scale-brewer
#let scale-hue(..args) = _stub("hue", args)

/// Continuous ColorBrewer colour/fill scale (distiller).
///
/// \@category Scales
/// \@subcategory Colour and fill scales
/// \@stability stable
/// \@since 0.5.0
///
/// \@param args Named arguments forwarded to the colour/fill scale (e.g. `palette`, `direction`, `name`, `limits`, `breaks`, `labels`).
///
/// \@returns Deferred scale spec consumed by \@scales.
///
/// \@examples Map a numeric fill through a continuous ColorBrewer ramp.
/// ```
/// //| alt: "Scatter chart of seven diagonal points whose fill runs through a continuous Spectral ColorBrewer ramp."
/// #let d = range(1, 8).map(i => (x: i, y: i, w: i))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", fill: "w"),
///   layers: (geom-point(size: 5pt),),
///   scales: scales(fill: scale-distiller(palette: "Spectral")),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@scales, \@scale-brewer, \@scale-fermenter
#let scale-distiller(..args) = _stub("distiller", args)

/// Binned two-colour gradient colour/fill scale (steps).
///
/// \@category Scales
/// \@subcategory Colour and fill scales
/// \@stability stable
/// \@since 0.5.0
///
/// \@param args Named arguments forwarded to the colour/fill scale (e.g. `low`, `high`, `n-breaks`, `breaks`, `name`, `limits`, `labels`).
///
/// \@returns Deferred scale spec consumed by \@scales.
///
/// \@examples Bin a numeric fill into stepped gradient bands.
/// ```
/// //| alt: "Scatter chart of twelve diagonal points whose fill steps through five binned two-colour gradient bands."
/// #let d = range(0, 12).map(i => (x: i, y: i, w: i + 1))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", fill: "w"),
///   layers: (geom-point(size: 5pt),),
///   scales: scales(fill: scale-steps(n-breaks: 5)),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@scales, \@scale-gradient, \@scale-stepsn
#let scale-steps(..args) = _stub("steps", args)

/// Binned diverging three-colour gradient colour/fill scale (steps2).
///
/// \@category Scales
/// \@subcategory Colour and fill scales
/// \@stability stable
/// \@since 0.5.0
///
/// \@param args Named arguments forwarded to the colour/fill scale (e.g. `low`, `mid`, `high`, `midpoint`, `n-breaks`, `breaks`, `name`, `limits`, `labels`).
///
/// \@returns Deferred scale spec consumed by \@scales.
///
/// \@examples Bin a signed numeric fill into diverging stepped bands.
/// ```
/// //| alt: "Scatter chart of eleven diagonal points whose fill steps through diverging binned bands around a midpoint of zero."
/// #let d = range(0, 11).map(i => (x: i, y: i, w: i - 5))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", fill: "w"),
///   layers: (geom-point(size: 5pt),),
///   scales: scales(fill: scale-steps2(midpoint: 0, n-breaks: 6)),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@scales, \@scale-gradient2, \@scale-steps
#let scale-steps2(..args) = _stub("steps2", args)

/// Binned N-colour gradient colour/fill scale (stepsn).
///
/// \@category Scales
/// \@subcategory Colour and fill scales
/// \@stability stable
/// \@since 0.5.0
///
/// \@param args Named arguments forwarded to the colour/fill scale (e.g. `colours`, `n-breaks`, `breaks`, `name`, `limits`, `labels`).
///
/// \@returns Deferred scale spec consumed by \@scales.
///
/// \@examples Bin a numeric fill into N-colour stepped bands.
/// ```
/// //| alt: "Scatter chart of twelve diagonal points whose fill steps through binned bands drawn from a three-colour ramp."
/// #let d = range(0, 12).map(i => (x: i, y: i, w: i + 1))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", fill: "w"),
///   layers: (geom-point(size: 5pt),),
///   scales: scales(fill: scale-stepsn(
///     colours: (rgb("#000000"), rgb("#888888"), rgb("#ffffff")),
///     n-breaks: 4,
///   )),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@scales, \@scale-gradientn, \@scale-steps
#let scale-stepsn(..args) = _stub("stepsn", args)

/// Binned ColorBrewer colour/fill scale (fermenter).
///
/// \@category Scales
/// \@subcategory Colour and fill scales
/// \@stability stable
/// \@since 0.5.0
///
/// \@param args Named arguments forwarded to the colour/fill scale (e.g. `palette`, `n-breaks`, `breaks`, `direction`, `name`, `limits`, `labels`).
///
/// \@returns Deferred scale spec consumed by \@scales.
///
/// \@examples Bin a numeric fill into ColorBrewer stepped bands.
/// ```
/// //| alt: "Scatter chart of twelve diagonal points whose fill steps through five binned Spectral ColorBrewer bands."
/// #let d = range(0, 12).map(i => (x: i, y: i, w: i + 1))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", fill: "w"),
///   layers: (geom-point(size: 5pt),),
///   scales: scales(fill: scale-fermenter(palette: "Spectral", n-breaks: 5)),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@scales, \@scale-distiller, \@scale-steps
#let scale-fermenter(..args) = _stub("fermenter", args)

// Size scales ---------------------------------------------------------------

/// Area-proportional continuous size scale.
///
/// Marker area, rather than diameter, scales linearly with the value.
///
/// \@category Scales
/// \@subcategory Size scales
/// \@stability stable
/// \@since 0.5.0
///
/// \@param args Named arguments forwarded to the size scale (e.g. `range`, `name`, `limits`, `breaks`, `labels`).
///
/// \@returns Deferred scale spec consumed by \@scales.
///
/// \@examples Scale marker area, not diameter, with the value.
/// ```
/// //| alt: "Scatter chart of seven diagonal points where marker area grows with the square root of a quadratic column so visual area tracks the value."
/// #let d = range(1, 8).map(i => (x: i, y: i, w: i * i))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", size: "w"),
///   layers: (geom-point(),),
///   scales: scales(size: scale-area(range: (1pt, 12pt))),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@scales, \@scale-continuous, \@scale-radius
#let scale-area(..args) = _stub("area", args)

/// Binned area-proportional size scale.
///
/// \@category Scales
/// \@subcategory Size scales
/// \@stability stable
/// \@since 0.5.0
///
/// \@param args Named arguments forwarded to the size scale (e.g. `n-breaks`, `breaks`, `range`, `name`, `limits`, `labels`).
///
/// \@returns Deferred scale spec consumed by \@scales.
///
/// \@examples Bin an area-proportional size scale into discrete steps.
/// ```
/// //| alt: "Scatter chart of seven diagonal points where a quadratic column is cut into four area-proportional size bins."
/// #let d = range(1, 8).map(i => (x: i, y: i, w: i * i))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", size: "w"),
///   layers: (geom-point(),),
///   scales: scales(size: scale-binned-area(n-breaks: 4, range: (1pt, 12pt))),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@scales, \@scale-area, \@scale-binned
#let scale-binned-area(..args) = _stub("binned-area", args)

/// Linear-radius continuous size scale.
///
/// The explicit-name alias for a linear value-to-radius size mapping. The
/// area-proportional variant is \@scale-area.
///
/// \@category Scales
/// \@subcategory Size scales
/// \@stability stable
/// \@since 0.5.0
///
/// \@param args Named arguments forwarded to the size scale (e.g. `range`, `name`, `limits`, `breaks`, `labels`).
///
/// \@returns Deferred scale spec consumed by \@scales.
///
/// \@examples Scale marker radius linearly with the value.
/// ```
/// //| alt: "Scatter chart of seven diagonal points where marker radius scales linearly with a numeric column from small to large."
/// #let d = range(1, 8).map(i => (x: i, y: i, w: i))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y", size: "w"),
///   layers: (geom-point(),),
///   scales: scales(size: scale-radius(range: (1pt, 8pt))),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@scales, \@scale-continuous, \@scale-area
#let scale-radius(..args) = _stub("radius", args)
