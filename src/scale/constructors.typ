///! Public aesthetic-agnostic scale constructors.
///!
///! Each constructor returns a deferred stub `(kind: "scale", family: ...,
///! args: ...)`. The aesthetic is supplied by the `scales()` key, which
///! dispatches the stub to the matching internal builder (see scale/bind.typ).
///! Pass these to \@plot through \@scales, e.g.
///! `scales(x: scale-log10(), colour: scale-viridis-d())`.

#let _stub(family, args) = (kind: "scale", family: family, args: args)

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
/// \@see \@scales, \@scale-area, \@scale-binned
#let scale-binned-area(..args) = _stub("binned-area", args)

/// Linear-radius continuous size scale.
///
/// The explicit-name alias for a linear value-to-radius size mapping;
/// \@scale-area is the area-proportional variant.
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
/// \@see \@scales, \@scale-continuous, \@scale-area
#let scale-radius(..args) = _stub("radius", args)
