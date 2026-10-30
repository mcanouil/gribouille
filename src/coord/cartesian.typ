///! Cartesian coordinate system.
///!
///! The default coordinate system used when no `coord` is passed to \@plot.
///! `x-limits` and `y-limits` clip the rendered panel without dropping rows, unlike
///! scale limits which remove rows outside the domain.

#import "../scale/train.typ": transform-fwd
#import "../utils/errors.typ": fail-type
#import "../utils/types.typ": is-native-numeric
#import "contract.typ": coord-base
#import "expand.typ": apply-expand

#let _is-limit-pair(limits) = (
  type(limits) == array and limits.len() == 2 and limits.all(is-native-numeric)
)

// x-limits/y-limits arrive in data space; pre-transformed domains live in stat space.
#let _coord-limits-to-domain(entry, lim) = {
  if not entry.at("pre-transformed", default: false) { return lim }
  let t = entry.at("transform", default: "identity")
  let (lo, hi) = lim
  (transform-fwd(t, lo), transform-fwd(t, hi))
}

// x-limits/y-limits overrides take precedence over scale training, so `train`
// re-applies them after any per-panel retraining.
#let _apply-limits(trained, x-limits, y-limits) = {
  if (
    x-limits != none
      and trained.at("x", default: none) != none
      and trained.x.type == "continuous"
  ) {
    let new-x = trained.x
    new-x.insert("domain", _coord-limits-to-domain(trained.x, x-limits))
    let _ = new-x.remove("oob-cutoff", default: none)
    trained.insert("x", new-x)
  }
  if (
    y-limits != none
      and trained.at("y", default: none) != none
      and trained.y.type == "continuous"
  ) {
    let new-y = trained.y
    new-y.insert("domain", _coord-limits-to-domain(trained.y, y-limits))
    let _ = new-y.remove("oob-cutoff", default: none)
    trained.insert("y", new-y)
  }
  trained
}

/// Cartesian coordinate system with optional panel clipping.
///
/// Clipping via `x-limits`/`y-limits` preserves the trained scales; rows outside
/// are still used for training but drawn off-panel.
///
/// \@category Coord
/// \@stability stable
///
/// \@param x-limits Pair `(lo, hi)` clipping the drawn x range, or `none`.
///
/// \@param y-limits Pair `(lo, hi)` clipping the drawn y range, or `none`.
///
/// \@param expand Whether to add a small margin around the data range.
///
/// \@param clip Set to `false` to let geoms (typically annotations) draw past the panel rectangle. Defaults to `true`.
///
/// \@returns Coordinate dictionary consumed by \@plot.
///
/// \@examples Clip the drawn panel without dropping rows from training.
/// ```
/// //| alt: "Scatter chart of a linear y = x/2 series with x from 0 to 19; the panel is clipped to x between 2 and 15 and y between 0 and 8 so only the central segment is drawn."
/// #let d = range(0, 20).map(i => (x: i, y: i * 0.5))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-point(size: 2pt),),
///   coord: coord-cartesian(x-limits: (2, 15), y-limits: (0, 8)),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@examples Disabling `expand` removes the default margin so axis lines
/// hug the data range.
/// ```
/// //| alt: "Line with points along the y = x diagonal from 0 to 10; axis lines hug the data range with no expansion margin."
/// #let d = range(0, 11).map(i => (x: i, y: i))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (geom-line(stroke: 1pt), geom-point(size: 2pt)),
///   coord: coord-cartesian(expand: false),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@examples Set `clip: false` so an annotation placed at the data edge can
/// extend past the panel rectangle.
/// ```
/// //| alt: "Scatter chart of y = x/2 from x = 0 to 9 with a text annotation 'Long label' at (9, 4.5) that extends past the right panel edge because clipping is disabled."
/// #let d = range(0, 10).map(i => (x: i, y: i * 0.5))
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: "y"),
///   layers: (
///     geom-point(size: 2pt),
///     annotate("typst", x: 9, y: 4.5, label: [Long label]),
///   ),
///   coord: coord-cartesian(clip: false),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@plot, \@scale-continuous
#let coord-cartesian(
  x-limits: none,
  y-limits: none,
  expand: true,
  clip: true,
) = {
  for (name, limits) in (("x-limits", x-limits), ("y-limits", y-limits)) {
    if limits != none and not _is-limit-pair(limits) {
      fail-type("coord-cartesian", name, limits, "`none` or a (lo, hi) pair of numbers")
    }
  }
  for (name, flag) in (("expand", expand), ("clip", clip)) {
    if type(flag) != bool {
      fail-type("coord-cartesian", name, flag, "a boolean")
    }
  }
  (
    coord-base("cartesian")
      + (
        x-limits: x-limits,
        y-limits: y-limits,
        expand: expand,
        clip: clip,
        train: trained => apply-expand(
          _apply-limits(trained, x-limits, y-limits),
          no-expand: expand == false,
        ),
      )
  )
}
