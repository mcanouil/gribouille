// End-to-end: an actual _brand.yml on disk, parsed by Typst's `yaml()` and
// mapped onto a theme. The inline-dictionary tests cover the resolver's logic;
// this one pins the shapes real YAML parsing produces, which is the seam the
// dictionary fixtures cannot exercise.
//
// The path is root-absolute so it resolves from the project root rather than
// from this file, which is what lets a test read a fixture at all.

#import "../../src/utils/brand-yml.typ": (
  brand-colours, brand-font, brand-palette-from,
)
#import "../../src/theme/brand.typ": theme-brand
#import "../../src/theme/defaults.typ": merge-theme
#import "../../src/theme/theme.typ": _text-style, resolve-element

#let brand = yaml("/tests/fixtures/_brand.yml")

// YAML gives dictionaries for nested maps and strings for scalars.
#assert.eq(type(brand), dictionary)
#assert.eq(type(brand.color), dictionary)
#assert.eq(type(brand.color.palette), dictionary)
#assert.eq(brand.color.palette.cream, "#FFFAF0")
#assert.eq(brand.typography.base.line-height, 1.6)

// Variants and palette names resolve out of the parsed file.
#let light = brand-colours(brand, "light")
#let dark = brand-colours(brand, "dark")
#assert.eq(light.foreground, rgb("#1A1A1A"))
#assert.eq(light.background, rgb("#FFFAF0"))
#assert.eq(dark.foreground, rgb("#F4EDDF"))
#assert.eq(dark.background, rgb("#161B1E"))

// `primary` is a variant whose light side names `house-red`, itself an alias of
// `signal`: two hops through the file's own palette.
#assert.eq(light.primary, rgb("#E94C3D"))
#assert.eq(dark.primary, rgb("#FF6F60"))

// A flat colour is identical in both modes.
#assert.eq(light.danger, rgb("#B23A2B"))
#assert.eq(dark.danger, rgb("#B23A2B"))

// `info` duplicates `secondary`, so the derived palette holds five colours.
#assert.eq(
  brand-palette-from(light),
  (
    rgb("#E94C3D"),
    rgb("#1F7A8C"),
    rgb("#F4B740"),
    rgb("#7FC8A9"),
    rgb("#B23A2B"),
  ),
)

// Both typography shapes survive the round trip: an object with a family, and
// a bare string.
#assert.eq(brand-font(brand, "base"), "Inter")
#assert.eq(brand-font(brand, "headings"), "Fraunces")
#assert.eq(brand-font(brand, "monospace"), "JetBrains Mono")

// The whole theme builds from the file.
#let theme = merge-theme(theme-brand(brand))
#assert.eq(theme.ink, rgb("#1A1A1A"))
#assert.eq(theme.paper, rgb("#FFFAF0"))
#assert.eq(theme.accent, rgb("#E94C3D"))
#assert.eq(theme.palette.len(), 5)
#assert.eq(resolve-element(theme, "axis-text").font, "Inter")
#assert.eq(resolve-element(theme, "plot-title").font, "Fraunces")
#assert.eq(_text-style(theme, "plot-title").size, 12pt)

#let dark-theme = merge-theme(theme-brand(brand, mode: "dark"))
#assert.eq(dark-theme.ink, rgb("#F4EDDF"))
#assert.eq(dark-theme.paper, rgb("#161B1E"))
#assert.eq(dark-theme.plot-background.fill, rgb("#161B1E"))

// Hex colours must be quoted in the file. YAML eats an unquoted `#` as a
// comment, so the role parses to nothing rather than to a colour, and
// `theme-brand` reports it as a malformed value rather than silently ignoring
// it. Panics are uncatchable in Typst, so this pins the parse, not the panic.
#let unquoted = yaml("/tests/fixtures/_brand-unquoted.yml")
#assert.eq(unquoted.color.primary, none)
