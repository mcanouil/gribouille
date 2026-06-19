// _text-style surfaces the cascaded `font` field. Unset stays `none` so no
// `font:` argument is emitted and the document font is kept; surface and
// parent records cascade like every other element field. The geom font role
// lives on `element-geom` as `font` and inherits the base `text` font when
// unset.

#import "../../lib.typ": (
  element-geom, element-text, geom-label, geom-text, geom-typst, theme,
)
#import "../../src/theme/defaults.typ": default-theme, merge-theme
#import "../../src/theme/theme.typ": (
  _text-style, resolve-geom-defaults, resolve-geom-font,
)

// No override: font is none, so consumers omit `text(font: ...)` entirely.
#let plain = merge-theme(none)
#assert.eq(_text-style(plain, "plot-title").font, none)
#assert.eq(_text-style(plain, "axis-text-x-bottom").font, none)
#assert.eq(_text-style(plain, "legend-text").font, none)

// Surface-level font is surfaced verbatim.
#let user = theme(plot-caption: element-text(font: "Font A"))
#assert.eq(_text-style(merge-theme(user), "plot-caption").font, "Font A")

// Parent `text` font cascades to descendants that do not set one.
#let parent = theme(text: element-text(font: "Font B"))
#assert.eq(_text-style(merge-theme(parent), "plot-title").font, "Font B")
#assert.eq(
  _text-style(merge-theme(parent), "axis-title-x-bottom").font,
  "Font B",
)

// Surface font wins over the inherited parent font.
#let both = theme(
  text: element-text(font: "Font B"),
  plot-title: element-text(font: "Font C"),
)
#assert.eq(_text-style(merge-theme(both), "plot-title").font, "Font C")

// element-typst surfaces font the same way.
#let typst = theme(plot-title: element-text(font: "Font D"))
#assert.eq(_text-style(merge-theme(typst), "plot-title").font, "Font D")

// element-geom carries a `font` role, default none.
#assert.eq(element-geom().font, none)
#assert.eq(element-geom(font: "Geom Font").font, "Geom Font")

// resolve-geom-defaults.font: element-geom.font wins; else inherits the base `text`
// font. The text-drawing geoms read this field directly (no hard fallback,
// `none` simply omits the `font:` argument).
#assert.eq(resolve-geom-defaults(plain).font, none)

#let geom-themed = merge-theme(theme(geom: element-geom(font: "Geom Font")))
#assert.eq(resolve-geom-defaults(geom-themed).font, "Geom Font")

// Unset element-geom.font inherits the base text font.
#let base-themed = merge-theme(theme(text: element-text(font: "Base Font")))
#assert.eq(resolve-geom-defaults(base-themed).font, "Base Font")

// element-geom.font overrides the inherited base text font.
#let both-themed = merge-theme(theme(
  text: element-text(font: "Base Font"),
  geom: element-geom(font: "Geom Font"),
))
#assert.eq(resolve-geom-defaults(both-themed).font, "Geom Font")

// resolve-geom-font: per-layer font wins over the theme default.
#assert.eq(resolve-geom-font("Layer Font", "Theme Font"), "Layer Font")

// `auto` defers to the theme default; a `none` default keeps the document font.
#assert.eq(resolve-geom-font(auto, "Theme Font"), "Theme Font")
#assert.eq(resolve-geom-font(auto, none), none)

// An explicit `none` per-layer value also defers to the theme default.
#assert.eq(resolve-geom-font(none, "Theme Font"), "Theme Font")

// The text-drawing geoms expose `font`, defaulting to `auto` and threading the
// pinned value into the layer params consumed at draw time.
#assert.eq(geom-text().params.font, auto)
#assert.eq(geom-text(font: "Layer Font").params.font, "Layer Font")
#assert.eq(geom-label(font: "Layer Font").params.font, "Layer Font")
#assert.eq(geom-typst(font: "Layer Font").params.font, "Layer Font")

text-style font cascade test passed.
