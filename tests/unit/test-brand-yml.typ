// brand.yml parsing: alias walking, cycle detection, light/dark selection,
// font families, and the derived discrete palette.

#import "../../src/utils/brand-yml.typ": (
  _pick-variant, _walk-alias, brand-colours, brand-font, brand-palette-from,
)

// Mirrors docs/_brand.yml: light/dark variants, `info` aliasing `secondary`,
// `warning` aliasing `tertiary`, and a flat `danger`.
#let BRAND = (
  color: (
    palette: (
      paper-light: "#FFFAF0",
      paper-dark: "#161B1E",
      ink-light: "#1A1A1A",
      ink-dark: "#F4EDDF",
      crayon-red: "#E94C3D",
      "crayon-red-dk": "#FF6F60",
      "crayon-teal": "#1F7A8C",
      "crayon-teal-dk": "#5BB5C7",
      "crayon-mustard": "#F4B740",
      "crayon-mustard-dk": "#FFD166",
      "crayon-mint": "#7FC8A9",
      "crayon-mint-dk": "#9CDCC0",
    ),
    foreground: (light: "ink-light", dark: "ink-dark"),
    background: (light: "paper-light", dark: "paper-dark"),
    primary: (light: "crayon-red", dark: "crayon-red-dk"),
    secondary: (light: "crayon-teal", dark: "crayon-teal-dk"),
    tertiary: (light: "crayon-mustard", dark: "crayon-mustard-dk"),
    success: (light: "crayon-mint", dark: "crayon-mint-dk"),
    info: (light: "crayon-teal", dark: "crayon-teal-dk"),
    warning: (light: "crayon-mustard", dark: "crayon-mustard-dk"),
    danger: "#B23A2B",
  ),
  typography: (
    base: (family: "Inter", size: "1rem", line-height: 1.6),
    headings: (family: "Fraunces", weight: 600),
    monospace: "JetBrains Mono",
  ),
)

#let CYCLIC = (purple: "burgundy", burgundy: "purple")

// Alias hops resolve to the terminal hex.
#let one-hop = (accent: "#E94C3D")
#assert.eq(_walk-alias("accent", one-hop, "light").colour, rgb("#E94C3D"))
#let two-hop = (brand: "accent", accent: "#E94C3D")
#assert.eq(_walk-alias("brand", two-hop, "light").colour, rgb("#E94C3D"))

// A literal hex needs no palette at all.
#assert.eq(_walk-alias("#E94C3D", (:), "light").colour, rgb("#E94C3D"))

// All four hex widths are accepted.
#assert(_walk-alias("#abc", (:), "light").ok)
#assert(_walk-alias("#abcd", (:), "light").ok)
#assert(_walk-alias("#aabbcc", (:), "light").ok)
#assert(_walk-alias("#aabbccdd", (:), "light").ok)

// Cycle detection names the chain it walked.
#let cycle = _walk-alias("purple", CYCLIC, "light")
#assert.eq(cycle.ok, false)
#assert.eq(cycle.reason, "cycle")
#assert.eq(cycle.chain, ("purple", "burgundy", "purple"))

// A self-alias is a one-node cycle.
#let self-cycle = _walk-alias("purple", (purple: "purple"), "light")
#assert.eq(self-cycle.reason, "cycle")
#assert.eq(self-cycle.chain, ("purple", "purple"))

// Each malformed shape reports its own reason.
#assert.eq(_walk-alias("nope", (:), "light").reason, "unknown")
#assert.eq(_walk-alias("nope", (:), "light").token, "nope")
#assert.eq(_walk-alias("#12345", (:), "light").reason, "hex")
#assert.eq(_walk-alias("#gggggg", (:), "light").reason, "hex")
#assert.eq(_walk-alias(42, (:), "light").reason, "type")
#assert.eq(_walk-alias("   ", (:), "light").reason, "empty")

// Light and dark select opposite sides of a variant.
#assert.eq(brand-colours(BRAND, "light").primary, rgb("#E94C3D"))
#assert.eq(brand-colours(BRAND, "dark").primary, rgb("#FF6F60"))
#assert.eq(brand-colours(BRAND, "light").foreground, rgb("#1A1A1A"))
#assert.eq(brand-colours(BRAND, "dark").foreground, rgb("#F4EDDF"))

// A flat colour carries no variants and is used in both modes.
#assert.eq(brand-colours(BRAND, "light").danger, rgb("#B23A2B"))
#assert.eq(brand-colours(BRAND, "dark").danger, rgb("#B23A2B"))

// A one-sided variant falls back to the side it has.
#assert.eq(_pick-variant((light: "#111111"), "dark"), "#111111")
#assert.eq(_pick-variant((dark: "#111111"), "light"), "#111111")
#assert.eq(_pick-variant("#111111", "dark"), "#111111")

// A dictionary carrying neither side is handed back whole rather than raised
// from here, so the walk stays pure and answers a verdict for it.
#assert.eq(_pick-variant((foo: "#111111"), "light"), (foo: "#111111"))
#let variant = _walk-alias((foo: "#111111"), (:), "light")
#assert.eq(variant.ok, false)
#assert.eq(variant.reason, "variant")
#assert.eq(variant.token, (foo: "#111111"))
#assert.eq(variant.chain, ())

// The same verdict one hop in, where the palette entry is the malformed one.
#let hop = _walk-alias("accent", (accent: (foo: "#111111")), "light")
#assert.eq(hop.reason, "variant")
#assert.eq(hop.chain, ("accent",))

// A side that is itself a dictionary is a variant nested in a variant, not a
// misspelled key: the side was read, and what it held is the wrong type. The
// verdict has to say so, or the message demands the very keys the value has.
#let nested = _walk-alias((light: (light: "#111111")), (:), "light")
#assert.eq(nested.reason, "type")
#assert.eq(nested.token, (light: "#111111"))

// Absent is never an error.
#assert.eq(brand-colours((:), "light"), (:))
#assert.eq(brand-colours((color: (:)), "light"), (:))
#assert.eq(brand-colours((color: (palette: (:))), "light"), (:))
#assert.eq(brand-font((:), "base"), none)
#assert.eq(brand-font((typography: (:)), "headings"), none)

// Both typography shapes yield the family; a family-less block yields none.
#assert.eq(brand-font(BRAND, "base"), "Inter")
#assert.eq(brand-font(BRAND, "headings"), "Fraunces")
#assert.eq(brand-font((typography: (base: "Inter")), "base"), "Inter")
#assert.eq(brand-font((typography: (base: (weight: 600))), "base"), none)

// The derived palette drops the duplicates `info` and `warning` introduce.
#let palette-of(brand, mode) = brand-palette-from(brand-colours(brand, mode))
#let pal = palette-of(BRAND, "light")
#assert.eq(pal.len(), 5)
#assert.eq(pal.at(0), rgb("#E94C3D"))
#assert.eq(pal.dedup().len(), pal.len())
#assert.eq(
  pal,
  (
    rgb("#E94C3D"),
    rgb("#1F7A8C"),
    rgb("#F4B740"),
    rgb("#7FC8A9"),
    rgb("#B23A2B"),
  ),
)
#assert.eq(palette-of(BRAND, "dark").len(), 5)

// Below two distinct colours the brand has no usable palette.
#assert.eq(palette-of((color: (primary: "#111111")), "light"), none)
#assert.eq(palette-of((:), "light"), none)
#assert.eq(
  palette-of((color: (primary: "#111111", info: "#111111")), "light"),
  none,
)
