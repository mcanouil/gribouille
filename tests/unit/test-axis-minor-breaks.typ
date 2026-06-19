// Minor gridline break computation for continuous axes: midpoint subdivision
// with end extension on linear/sqrt, sub-decade lines on log10, explicit
// `minor-breaks` / `n-minor` overrides, and no minors for binned scales.

#import "../../src/render/axis-format.typ": _axis-minor-breaks

// ── Linear: one minor per gap (default), midpoints, clipped to domain ───────
#let lin = (
  type: "continuous",
  domain: (0, 10),
  transform: "identity",
  spec: none,
)
#assert.eq(
  _axis-minor-breaks(lin, (0, 2.5, 5, 7.5, 10)),
  (1.25, 3.75, 6.25, 8.75),
)

// Linear with a domain wider than the majors keeps the extension minors that
// fall one step beyond the first/last major.
#let lin-wide = (
  type: "continuous",
  domain: (-3, 13),
  transform: "identity",
  spec: none,
)
#assert.eq(
  _axis-minor-breaks(lin-wide, (0, 5, 10)),
  (-2.5, 2.5, 7.5, 12.5),
)

// ── n-minor: four minors between adjacent majors ───────────────────────────
#let lin-n = (
  type: "continuous",
  domain: (0, 10),
  transform: "identity",
  spec: (minor-breaks: auto, n-minor: 4, binned: false),
)
#assert.eq(
  _axis-minor-breaks(lin-n, (0, 5, 10)),
  (1.0, 2.0, 3.0, 4.0, 6.0, 7.0, 8.0, 9.0),
)

// n-minor: 0 disables minors.
#let lin-0 = (
  type: "continuous",
  domain: (0, 10),
  transform: "identity",
  spec: (minor-breaks: auto, n-minor: 0, binned: false),
)
#assert.eq(_axis-minor-breaks(lin-0, (0, 5, 10)), ())

// ── Explicit minor-breaks win, clipped to the visible domain ───────────────
#let lin-user = (
  type: "continuous",
  domain: (0, 10),
  transform: "identity",
  spec: (minor-breaks: (1, 3, 99), n-minor: auto, binned: false),
)
#assert.eq(_axis-minor-breaks(lin-user, (0, 5, 10)), (1, 3))

// A scalar minor-breaks is coerced to a one-element array.
#let lin-scalar = (
  type: "continuous",
  domain: (0, 10),
  transform: "identity",
  spec: (minor-breaks: 5, n-minor: auto, binned: false),
)
#assert.eq(_axis-minor-breaks(lin-scalar, (0, 5, 10)), (5,))

// ── Irregular majors fall back to data-space midpoints, no extension ────────
#let lin-irr = (
  type: "continuous",
  domain: (0, 4),
  transform: "identity",
  spec: none,
)
#assert.eq(_axis-minor-breaks(lin-irr, (0, 1, 4)), (0.5, 2.5))

// ── log10: sub-decade positions 2..9 within each decade ────────────────────
#let lg = (
  type: "continuous",
  domain: (0, 2),
  transform: "log10",
  pre-transformed: true,
  spec: none,
)
#assert.eq(
  _axis-minor-breaks(lg, (1, 10, 100)),
  (
    2.0,
    3.0,
    4.0,
    5.0,
    6.0,
    7.0,
    8.0,
    9.0,
    20.0,
    30.0,
    40.0,
    50.0,
    60.0,
    70.0,
    80.0,
    90.0,
  ),
)

// ── sqrt: minors subdivide in transformed space, staying within the domain ──
#let sq = (
  type: "continuous",
  domain: (1, 4),
  transform: "sqrt",
  pre-transformed: true,
  spec: none,
)
#let sq-minors = _axis-minor-breaks(sq, (1, 4, 9))
#assert(sq-minors.len() > 0)
#assert(sq-minors.all(b => b >= 1 and b <= 16))

// ── Binned scales have no minor gridlines ──────────────────────────────────
#let bn = (
  type: "continuous",
  domain: (0, 10),
  transform: "identity",
  spec: (binned: true),
)
#assert.eq(_axis-minor-breaks(bn, (1, 3, 5)), ())

// ── Fewer than two majors yields no minors ─────────────────────────────────
#assert.eq(_axis-minor-breaks(lin, (5,)), ())

Axis minor-break tests passed.
