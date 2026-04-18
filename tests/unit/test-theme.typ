// theme() translates element-text/line/rect dicts into flat keys consumed by
// merge-theme.

#import "../../src/theme/theme.typ": theme
#import "../../src/theme/elements.typ": element-text, element-line, element-rect, element-blank
#import "../../src/theme/defaults.typ": merge-theme

#let t = theme(
  axis-text-size: 11pt,
  panel-fill: rgb("#eeeeee"),
)
#assert.eq(t.axis-text-size, 11pt)
#assert.eq(t.panel-fill, rgb("#eeeeee"))

// Via element-* dicts: the theme helper should flatten axis.text into
// axis-text-size.
#let t2 = theme(
  axis-text: element-text(size: 13pt),
  panel-background: element-rect(fill: rgb("#ff9900")),
)
#assert.eq(t2.axis-text-size, 13pt)
#assert.eq(t2.panel-fill, rgb("#ff9900"))

// Merging into the defaults produces a usable theme dict.
#let merged = merge-theme(t2)
#assert.eq(merged.axis-text-size, 13pt)
#assert.eq(merged.panel-fill, rgb("#ff9900"))

Theme tests passed.
