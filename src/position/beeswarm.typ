///! Deterministic density-shaped offsets.
///!
///! A quasirandom swarm: points at the same x spread sideways in proportion
///! to the local density of their y values (or, with `orientation: "y"`, points
///! at the same y spread up and down in proportion to the density of their x values), ordered by a van der Corput
///! sequence so the cloud fills evenly without a random number generator.
///! Renders are reproducible without a seed.

#import "../utils/errors.typ": assert-number, fail-enum
#import "../utils/bucket.typ": bucket-dict
#import "../utils/types.typ": parse-number
#import "../utils/kde.typ": bw-nrd0

/// Density-shaped per-row offset on x, or on y with `orientation: "y"`.
///
/// For every bucket of rows sharing an x value, each point is offset
/// sideways by `width × (2·v − 1) × d`, where `v` walks the van der Corput
/// base-2 sequence in y order and `d` is the point's Gaussian kernel density
/// estimate normalised to the bucket's peak. Dense regions spread wide,
/// sparse tails stay close to the spine, and the result is a violin-shaped
/// swarm.
///
/// A discrete (categorical) x is swarmed directly on its level positions,
/// keeping the axis labels. \@as-factor is only needed to force a numeric
/// column onto a discrete axis.
///
/// \@category Positions
/// \@stability stable
///
/// \@param width Maximum absolute offset applied to the x position, in x data units.
///
/// \@param adjust Bandwidth multiplier for the density estimate, greater than `0`: `adjust: 0.5` halves the smoothing.
///
/// \@param orientation Axis the swarm spreads along: `"x"`, `"y"`, or `auto`. `auto` picks `"y"` when only the y axis is discrete, and `"x"` otherwise.
///
/// \@returns Position dictionary with `name: "beeswarm"`, consumed by \@plot.
///
/// \@examples Swarm overplotted points per group; a tighter `width` keeps
/// the cloud close to its spine.
/// ```
/// //| alt: "Beeswarm chart with groups a, b on the x-axis and values on the y-axis; points spread sideways into narrow swarms that taper towards sparse values."
/// #let d = ()
/// #for grp in ("a", "b") {
///   for i in range(0, 50) {
///     d.push((grp: grp, y: calc.sin(i * 0.7) + calc.sin(i * 1.9) + (if grp == "b" { 4 } else { 0 })))
///   }
/// }
/// #plot(
///   data: d,
///   mapping: aes(x: as-factor("grp"), y: "y"),
///   layers: (geom-point(size: 2pt, position: position-beeswarm(width: 0.25)),),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// A discrete y axis swarms up and down around each level:
/// ```
/// //| alt: "Beeswarm chart with groups a, b on the y-axis and values on the x-axis; points spread vertically into narrow swarms."
/// #let d = ()
/// #for grp in ("a", "b") {
///   for i in range(0, 50) {
///     d.push((grp: grp, x: calc.sin(i * 0.7) + calc.sin(i * 1.9) + (if grp == "b" { 4 } else { 0 })))
///   }
/// }
/// #plot(
///   data: d,
///   mapping: aes(x: "x", y: as-factor("grp")),
///   layers: (geom-point(size: 2pt, position: position-beeswarm(width: 0.25)),),
///   width: 10cm,
///   height: 6cm,
/// )
/// ```
///
/// \@see \@position-jitter, \@geom-beeswarm
#let position-beeswarm(width: 0.4, adjust: 1, orientation: auto) = {
  assert-number("position-beeswarm", "width", width, min: 0)
  assert-number("position-beeswarm", "adjust", adjust, positive: true)
  if orientation not in (auto, "x", "y") {
    fail-enum(
      "position-beeswarm",
      "orientation",
      orientation,
      ("auto", "x", "y"),
    )
  }
  (
    kind: "position",
    name: "beeswarm",
    params: (width: width, adjust: adjust, orientation: orientation),
  )
}

// Van der Corput base-2 value for a 1-indexed rank: the bit-reversed
// fraction (1 → 0.5, 2 → 0.25, 3 → 0.75, ...), which spreads consecutive
// ranks evenly across (0, 1).
#let _van-der-corput(n) = {
  let value = 0.0
  let denom = 1.0
  let rest = n
  while rest > 0 {
    denom *= 2
    value += calc.rem(rest, 2) / denom
    rest = calc.floor(rest / 2)
  }
  value
}

// An explicit orientation wins. `auto` swarms along y only when y is the sole
// discrete axis.
#let _resolve-orientation(orientation, discrete-axes) = {
  if orientation != auto { return orientation }
  if "y" in discrete-axes and "x" not in discrete-axes { "y" } else { "x" }
}

#let apply(data, mapping, params: (:), coord: none) = {
  let width = params.at("width", default: 0.4)
  let adjust = params.at("adjust", default: 1)
  let orientation = _resolve-orientation(
    params.at("orientation", default: auto),
    params.at("discrete-axes", default: ()),
  )
  let (swarm, value) = if orientation == "y" { ("y", "x") } else { ("x", "y") }
  let swarm-col = mapping.at(swarm, default: none)
  let value-col = mapping.at(value, default: none)
  if swarm-col == none or value-col == none or width == 0 {
    return (data: data, mapping: mapping)
  }

  // Bucket row indices by their numeric x value; rows with a non-numeric x
  // (an unforced discrete level) pass through unchanged.
  // One pass to drop the rows with no position, one to bucket what is left by
  // the slot they share.
  let placed = data
    .enumerate()
    .map(((i, row)) => (
      i: i,
      x: parse-number(row.at(swarm-col, default: none)),
      y: parse-number(row.at(value-col, default: none)),
    ))
    .filter(e => e.x != none and e.y != none)
  let buckets = bucket-dict(placed, e => str(e.x))

  let offsets = (:)
  for (key, bucket) in buckets.pairs() {
    if bucket.len() < 2 {
      for e in bucket { offsets.insert(str(e.i), 0.0) }
      continue
    }
    let ys = bucket.map(e => e.y)
    let bw = bw-nrd0(ys) * adjust
    // Unnormalised Gaussian kernel sums: each offset scales a point's density
    // by the bucket peak, so the 1/(n·bw·√(2π)) density constant cancels.
    let densities = ys.map(y => (
      ys
        .map(v => {
          let z = (y - v) / bw
          calc.exp(-0.5 * z * z)
        })
        .sum()
    ))
    let peak = calc.max(..densities)
    // Rank in y order (stable: ties keep input order) drives the van der
    // Corput walk so neighbouring values land on opposite sides.
    let by-y = range(bucket.len()).sorted(key: j => bucket.at(j).y)
    for (rank, j) in by-y.enumerate() {
      let offset = (
        width * (2 * _van-der-corput(rank + 1) - 1) * densities.at(j) / peak
      )
      offsets.insert(str(bucket.at(j).i), offset)
    }
  }

  let new-data = data
    .enumerate()
    .map(((i, row)) => {
      let offset = offsets.at(str(i), default: none)
      if offset == none { return row }
      let r = row
      r.insert(swarm-col, parse-number(row.at(swarm-col)) + offset)
      r
    })
  (data: new-data, mapping: mapping)
}
