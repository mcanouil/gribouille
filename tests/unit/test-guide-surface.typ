// The theme-surface switch: which surface a guide part paints on, given its
// side and whether it sits on an axis or beside a legend.

#import "../../src/guide/gctx.typ": gctx
#import "../../src/guide/surface.typ": (
  LEGEND-TICK-GAP, LEGEND-TICK-LEN, ROLES, surface-for, tick-metrics,
)
#import "../../src/theme/theme.typ": _tick-length
#import "../../src/theme/defaults.typ": default-theme

#let th = default-theme
#let len-of = surface => _tick-length(th, surface) / 1cm

#let axis-x = gctx("bottom", "x", tick-length: len-of)
#let axis-y = gctx("left", "y", tick-length: len-of)
#let axis-top = gctx("top", "x", tick-length: len-of)
#let legend = gctx("right", "colour")

// An axis part names the side it sits on, so a theme can style one edge alone.
#assert.eq(surface-for(axis-x, "text"), "axis-text-x-bottom")
#assert.eq(surface-for(axis-x, "ticks"), "axis-ticks-x-bottom")
#assert.eq(surface-for(axis-x, "line"), "axis-line-x-bottom")
#assert.eq(surface-for(axis-x, "title"), "axis-title-x-bottom")
#assert.eq(surface-for(axis-top, "text"), "axis-text-x-top")
#assert.eq(surface-for(axis-y, "text"), "axis-text-y-left")
#assert.eq(surface-for(axis-y, "ticks"), "axis-ticks-y-left")

// The sub-decade tiers are per-axis and never per-side, matching how the theme
// parents them: `axis-ticks-minor-x` hangs off `axis-ticks-minor`, not a side.
#assert.eq(surface-for(axis-x, "ticks-minor"), "axis-ticks-minor-x")
#assert.eq(surface-for(axis-x, "ticks-mid"), "axis-ticks-mid-x")
#assert.eq(surface-for(axis-y, "ticks-minor"), "axis-ticks-minor-y")

// The same part beside a legend resolves the legend surfaces instead.
#assert.eq(surface-for(legend, "text"), "legend-text")
#assert.eq(surface-for(legend, "title"), "legend-title")
#assert.eq(surface-for(legend, "ticks"), "legend-ticks")
#assert.eq(surface-for(legend, "background"), "legend-background")
#assert.eq(surface-for(legend, "bar"), "legend-bar")

// Asymmetry, tested rather than assumed: a legend has no line surface and no
// tick tiers, so a line part measures nothing there.
#assert.eq(surface-for(legend, "line"), none)
#assert.eq(surface-for(legend, "ticks-mid"), none)
#assert.eq(surface-for(legend, "ticks-minor"), none)

// An axis has no colour-bar body.
#assert.eq(surface-for(axis-x, "bar"), none)

// A radial guide has no per-side surfaces of its own, so it reads the side the
// axis it sweeps on would use, which is what the radial draw already does.
#let theta-x = gctx("theta", "theta", axis: "x", tick-length: len-of)
#let theta-y = gctx("theta", "theta", axis: "y", tick-length: len-of)
#assert.eq(surface-for(theta-x, "ticks"), "axis-ticks-x-bottom")
#assert.eq(surface-for(theta-y, "ticks"), "axis-ticks-y-left")
#assert.eq(surface-for(theta-y, "ticks-minor"), "axis-ticks-minor-y")

// Tick geometry. On an axis the length comes from the theme; the default
// `axis-ticks` is `element-tick(length: 0.1cm)`.
#assert.eq(tick-metrics(axis-x).surface, "axis-ticks-x-bottom")
#assert.eq(tick-metrics(axis-x).len, 0.1)
#assert.eq(tick-metrics(axis-x).gap, 0.1)

// The minor tier halves the resolved major length (`axis-ticks-minor` is 50%),
// and the mid tier takes three quarters of it (`axis-ticks-mid` is 75%).
#assert.eq(
  calc.round(tick-metrics(axis-x, tier: "minor").len, digits: 6),
  0.05,
)
#assert.eq(
  calc.round(tick-metrics(axis-x, tier: "mid").len, digits: 6),
  0.075,
)

// Beside a legend the surface carries no length at all, so the two constants
// answer instead. These are the lengths the colour bar has always drawn at.
#assert.eq(LEGEND-TICK-LEN, 0.1)
#assert.eq(LEGEND-TICK-GAP, 0.08)
#assert.eq(
  tick-metrics(legend),
  (surface: "legend-ticks", len: 0.1, gap: 0.08),
)

// A tier the context has no surface for reserves nothing, so a caller reading
// `len` never leaves room for a tick that is never drawn.
#assert.eq(
  tick-metrics(legend, tier: "minor"),
  (surface: none, len: 0.0, gap: 0.0),
)
#assert.eq(
  tick-metrics(legend, tier: "mid"),
  (surface: none, len: 0.0, gap: 0.0),
)

#assert.eq(ROLES.len(), 8)

Guide-surface tests passed.
