// The `palette` theme key: default, resolution, and precedence against a
// scale's own palette.

#import "../../src/theme/theme.typ": resolve-theme-palette, theme
#import "../../src/theme/defaults.typ": merge-theme
#import "../../src/utils/palette.typ": (
  default-continuous, default-discrete, spec-palette,
)

// The library default is `auto`, which resolves to Okabe-Ito.
#assert.eq(merge-theme(none).palette, auto)
#assert.eq(merge-theme(theme()).palette, auto)
#assert.eq(resolve-theme-palette(merge-theme(none)), default-discrete)

// A partial theme dict missing the key behaves like `auto`, and a themeless
// call (the stat-only layer paths) takes the library default too.
#assert.eq(resolve-theme-palette((:)), default-discrete)
#assert.eq(resolve-theme-palette((palette: none)), default-discrete)
#assert.eq(resolve-theme-palette(none), default-discrete)

// An array passes through. Reaching this at all proves `palette` landed in
// `_KNOWN-THEME-KEYS`; `merge-theme` panics on any key outside that set.
#let pal = (rgb("#e94c3d"), rgb("#1f7a8c"))
#assert.eq(resolve-theme-palette(merge-theme(theme(palette: pal))), pal)

// A one-colour palette is legal: `palette-at` wraps modulo.
#assert.eq(
  resolve-theme-palette(merge-theme(theme(palette: (rgb("#e94c3d"),)))),
  (rgb("#e94c3d"),),
)

// Precedence: a scale's own palette beats the theme fallback.
#assert.eq(
  spec-palette((type: "discrete", spec: (palette: (red,))), pal),
  (red,),
)
#assert.eq(spec-palette((type: "discrete", spec: (:)), pal), pal)

// Continuous scales never see the discrete fallback.
#assert.eq(
  spec-palette((type: "continuous", spec: (:)), pal),
  default-continuous,
)
