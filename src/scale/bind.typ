///! Dispatch for aesthetic-agnostic scale constructors.
///!
///! The public `scale-*` constructors return a deferred stub carrying a
///! `family` name and the captured arguments; `scales()` calls `bind-scale`
///! to dispatch on `(aesthetic, family)` to the matching internal builder,
///! which bakes the aesthetic and produces the concrete scale dict.

#import "../utils/errors.typ": fail, quote-each
#import "continuous.typ": _transform-scale
#import "date.typ": _temporal-scale
#import "colour.typ": (
  _scale-brewer, _scale-distiller, _scale-fermenter, _scale-gradient,
  _scale-gradient2, _scale-gradientn, _scale-grey, _scale-hue, _scale-okabe-ito,
  _scale-steps, _scale-steps2, _scale-stepsn, _scale-viridis-b,
  _scale-viridis-c, _scale-viridis-d,
)

// A colour/fill family shares one builder across both aesthetics.
#let _cf(builder) = (colour: builder, fill: builder)

// A position family shares one builder across the x and y axes.
#let _xy(builder) = (x: builder, y: builder)

// Position transform families (log10/sqrt/reverse) pass the transform name as
// the builder's second positional.
#let _trans(name) = _xy((aesthetic, ..args) => _transform-scale(
  aesthetic,
  name,
  ..args,
))

// Temporal families inject their per-family `date-format` default when the
// caller left it unset, matching the retired `scale-x-date` wrappers.
#let _temporal(temporal, fmt) = _xy((aesthetic, ..args) => {
  let named = args.named()
  if "date-format" not in named { named.insert("date-format", fmt) }
  _temporal-scale(aesthetic, temporal, ..named)
})

// family -> (aesthetic -> builder(aesthetic, ..args))
#let _SCALE-DISPATCH = (
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
