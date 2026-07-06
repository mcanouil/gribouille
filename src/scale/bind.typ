///! Dispatch for aesthetic-agnostic scale constructors.
///!
///! The public `scale-*` constructors return a deferred stub carrying a
///! `family` name and the captured arguments; `scales()` calls `bind-scale`
///! to dispatch on `(aesthetic, family)` to the matching internal builder,
///! which bakes the aesthetic and produces the concrete scale dict.

#import "../utils/errors.typ": fail, quote-each
#import "continuous.typ": _binned-scale, _continuous-scale, _transform-scale
#import "discrete.typ": _discrete-scale
#import "date.typ": _temporal-scale
#import "colour.typ": (
  _alpha-binned, _alpha-continuous, _alpha-identity, _alpha-manual,
  _scale-brewer, _scale-continuous, _scale-discrete, _scale-distiller,
  _scale-fermenter, _scale-gradient, _scale-gradient2, _scale-gradientn,
  _scale-grey, _scale-hue, _scale-identity, _scale-manual, _scale-okabe-ito,
  _scale-steps, _scale-steps2, _scale-stepsn, _scale-viridis-b,
  _scale-viridis-c, _scale-viridis-d,
)
#import "size.typ": (
  _size-area, _size-binned, _size-binned-area, _size-continuous, _size-identity,
  _size-manual,
)
#import "linewidth.typ": (
  _linewidth-binned, _linewidth-continuous, _linewidth-identity,
  _linewidth-manual,
)
#import "stroke.typ": (
  _stroke-binned, _stroke-continuous, _stroke-identity, _stroke-manual,
)
#import "shape.typ": (
  _shape-binned, _shape-discrete, _shape-identity, _shape-manual,
)
#import "linetype.typ": (
  _linetype-binned, _linetype-discrete, _linetype-identity, _linetype-manual,
)

// Wrap a builder that takes the aesthetic as its first positional argument.
#let _aes(builder) = (aesthetic, ..args) => builder(aesthetic, ..args)

// Wrap a builder that binds a single aesthetic and ignores the key.
#let _solo(builder) = (aesthetic, ..args) => builder(..args)

// A colour/fill family shares one aesthetic-taking builder across both.
#let _cf(builder) = (colour: _aes(builder), fill: _aes(builder))

// A position family shares one builder across the x and y axes.
#let _xy(build) = (x: build, y: build)

// Position transform families pass the transform name as the builder's second
// positional; shared across the x and y axes.
#let _trans(name) = _xy((aesthetic, ..args) => _transform-scale(
  aesthetic,
  name,
  ..args,
))

// Temporal families inject their per-family `date-format` default when the
// caller left it unset, matching the retired `scale-date` wrappers.
#let _temporal(temporal, fmt) = _xy((aesthetic, ..args) => {
  let named = args.named()
  if "date-format" not in named { named.insert("date-format", fmt) }
  _temporal-scale(aesthetic, temporal, ..named)
})

// family -> (aesthetic -> builder(aesthetic, ..args))
#let _SCALE-DISPATCH = (
  continuous: (
    x: _aes(_continuous-scale),
    y: _aes(_continuous-scale),
    colour: _aes(_scale-continuous),
    fill: _aes(_scale-continuous),
    size: _solo(_size-continuous),
    alpha: _solo(_alpha-continuous),
    linewidth: _solo(_linewidth-continuous),
    stroke: _solo(_stroke-continuous),
    linetype: _solo(_linetype-binned),
  ),
  discrete: (
    x: _aes(_discrete-scale),
    y: _aes(_discrete-scale),
    colour: _aes(_scale-discrete),
    fill: _aes(_scale-discrete),
    shape: _solo(_shape-discrete),
    linetype: _solo(_linetype-discrete),
  ),
  binned: (
    x: _aes(_binned-scale),
    y: _aes(_binned-scale),
    size: _solo(_size-binned),
    alpha: _solo(_alpha-binned),
    linewidth: _solo(_linewidth-binned),
    stroke: _solo(_stroke-binned),
    shape: _solo(_shape-binned),
    linetype: _solo(_linetype-binned),
  ),
  manual: (
    colour: _aes(_scale-manual),
    fill: _aes(_scale-manual),
    alpha: _solo(_alpha-manual),
    size: _solo(_size-manual),
    linewidth: _solo(_linewidth-manual),
    stroke: _solo(_stroke-manual),
    shape: _solo(_shape-manual),
    linetype: _solo(_linetype-manual),
  ),
  identity: (
    colour: _aes(_scale-identity),
    fill: _aes(_scale-identity),
    alpha: _solo(_alpha-identity),
    size: _solo(_size-identity),
    linewidth: _solo(_linewidth-identity),
    stroke: _solo(_stroke-identity),
    shape: _solo(_shape-identity),
    linetype: _solo(_linetype-identity),
  ),
  viridis-d: _cf(_scale-viridis-d),
  viridis-c: _cf(_scale-viridis-c),
  viridis-b: _cf(_scale-viridis-b),
  brewer: _cf(_scale-brewer),
  okabe-ito: _cf(_scale-okabe-ito),
  gradient: _cf(_scale-gradient),
  gradient2: _cf(_scale-gradient2),
  gradientn: _cf(_scale-gradientn),
  grey: _cf(_scale-grey),
  hue: _cf(_scale-hue),
  distiller: _cf(_scale-distiller),
  steps: _cf(_scale-steps),
  steps2: _cf(_scale-steps2),
  stepsn: _cf(_scale-stepsn),
  fermenter: _cf(_scale-fermenter),
  log10: _trans("log10"),
  sqrt: _trans("sqrt"),
  reverse: _trans("reverse"),
  date: _temporal("date", "[year]-[month repr:numerical]-[day]"),
  datetime: _temporal(
    "datetime",
    "[year]-[month repr:numerical]-[day] [hour]:[minute]",
  ),
  time: _temporal("time", "[hour]:[minute]"),
  area: (size: _solo(_size-area)),
  binned-area: (size: _solo(_size-binned-area)),
  radius: (size: _solo(_size-continuous)),
)

// Dispatch a deferred scale stub onto `aesthetic`, failing loudly when the
// family is not available for that aesthetic.
#let bind-scale(aesthetic, stub) = {
  let family = stub.family
  let by-aesthetic = _SCALE-DISPATCH.at(family, default: none)
  if by-aesthetic == none {
    fail("scales", "unknown scale family " + repr(family))
  }
  if aesthetic not in by-aesthetic {
    fail(
      "scales",
      "scale `"
        + family
        + "` is not available for the `"
        + aesthetic
        + "` aesthetic",
      hint: "`"
        + family
        + "` applies to "
        + quote-each(by-aesthetic.keys())
        + ".",
    )
  }
  by-aesthetic.at(aesthetic)(aesthetic, ..stub.args)
}
