// _text-style surfaces the cascaded `align` field. Unset stays `none` so each
// draw site applies its own per-surface default; surface and parent records
// cascade like every other element field.

#import "../../lib.typ": element-text, theme
#import "../../src/theme/defaults.typ": merge-theme
#import "../../src/theme/theme.typ": _text-style

// No override: align is none, leaving the per-surface default to the renderer.
#let plain = merge-theme(none)
#assert.eq(_text-style(plain, "plot-title").align, none)
#assert.eq(_text-style(plain, "plot-caption").align, none)
#assert.eq(_text-style(plain, "axis-title-x-bottom").align, none)

// Surface-level align is exposed verbatim.
#let user = theme(plot-caption: element-text(align: left))
#assert.eq(_text-style(merge-theme(user), "plot-caption").align, left)

// Parent `text` align cascades to descendants that do not set one.
#let parent = theme(text: element-text(align: center))
#assert.eq(_text-style(merge-theme(parent), "plot-title").align, center)

// Surface align wins over the inherited parent align.
#let both = theme(
  text: element-text(align: center),
  plot-title: element-text(align: right),
)
#assert.eq(_text-style(merge-theme(both), "plot-title").align, right)

// Per-axis cascade: axis-title sets the family, the specific side inherits it.
#let axis = theme(axis-title: element-text(align: right))
#assert.eq(_text-style(merge-theme(axis), "axis-title-x-bottom").align, right)

text-style align cascade test passed.
