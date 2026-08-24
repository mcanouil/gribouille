// theme-brand maps a parsed _brand.yml onto the theme's colour roles, fonts,
// and discrete palette.

#import "../../src/theme/brand.typ": theme-brand
#import "../../src/theme/defaults.typ": default-theme, merge-theme
#import "../../src/theme/theme.typ": _text-style, resolve-element
#import "../../src/utils/palette.typ": default-discrete

#let BRAND = (
  color: (
    palette: (
      cream: "#FFFAF0",
      charcoal: "#1A1A1A",
      "ink-dark": "#F4EDDF",
      "paper-dark": "#161B1E",
    ),
    foreground: (light: "charcoal", dark: "ink-dark"),
    background: (light: "cream", dark: "paper-dark"),
    primary: (light: "#E94C3D", dark: "#FF6F60"),
    secondary: "#1F7A8C",
    tertiary: "#F4B740",
    success: "#7FC8A9",
    info: "#1F7A8C",
  ),
  typography: (
    base: (family: "Inter", size: "1rem"),
    headings: (family: "Fraunces", weight: 600),
  ),
)

#let light = merge-theme(theme-brand(BRAND))
#let dark = merge-theme(theme-brand(BRAND, mode: "dark"))

// The three colour roles map straight through, and mode flips all of them.
#assert.eq(light.name, "brand")
#assert.eq(light.ink, rgb("#1A1A1A"))
#assert.eq(light.paper, rgb("#FFFAF0"))
#assert.eq(light.accent, rgb("#E94C3D"))
#assert.eq(dark.ink, rgb("#F4EDDF"))
#assert.eq(dark.paper, rgb("#161B1E"))
#assert.eq(dark.accent, rgb("#FF6F60"))

// The canvas is painted, so a dark brand does not leave light ink on white.
#assert.eq(light.plot-background.fill, rgb("#FFFAF0"))
#assert.eq(dark.plot-background.fill, rgb("#161B1E"))

// The base family reaches every text surface through the root `text` record.
#assert.eq(resolve-element(light, "text").font, "Inter")
#assert.eq(resolve-element(light, "axis-text").font, "Inter")
#assert.eq(resolve-element(light, "legend-title").font, "Inter")

// The heading family lands on the plot title only.
#assert.eq(resolve-element(light, "plot-title").font, "Fraunces")

// Setting a font must not clobber the surface's own defaults: `merge-theme`
// replaces an element record wholesale, so a rebuilt `plot-title` would lose
// its 12/9 size ratio and bold weight.
#assert.eq(_text-style(light, "plot-title").size, 12pt)
#assert.eq(_text-style(light, "plot-title").weight, "bold")
#assert.eq(_text-style(light, "axis-text").size, 8pt)

// `info` duplicates `secondary`, so the derived palette holds four colours.
#assert.eq(
  light.palette,
  (rgb("#E94C3D"), rgb("#1F7A8C"), rgb("#F4B740"), rgb("#7FC8A9")),
)

// An explicit palette wins; `none` falls back to the library default.
#assert.eq(theme-brand(BRAND, palette: (red, blue)).palette, (red, blue))
#assert("palette" not in theme-brand(BRAND, palette: none))
#assert.eq(merge-theme(theme-brand(BRAND, palette: none)).palette, auto)

// An empty brand yields the minimal defaults rather than failing.
#let bare = merge-theme(theme-brand((:)))
#assert.eq(bare.name, "brand")
#assert.eq(bare.palette, auto)
// A brand that names no `primary` keeps the library accent, read from the
// defaults rather than repeated here, so the two cannot drift.
#assert.eq(bare.accent, default-theme.accent)
#assert.eq(resolve-element(bare, "text").at("font", default: none), none)

// A brand with too few data-ink roles keeps the library default palette.
#assert.eq(
  merge-theme(theme-brand((color: (primary: "#111111")))).palette,
  auto,
)

// Trailing overrides still win, as they do for every preset.
#assert.eq(theme-brand(BRAND, accent: rgb("#000000")).accent, rgb("#000000"))
#assert.eq(
  theme-brand(BRAND, palette: (red, blue), panel-grid: none).palette,
  (red, blue),
)

// The default palette really is Okabe-Ito once nothing overrides it.
#assert.eq(default-discrete.len(), 8)
