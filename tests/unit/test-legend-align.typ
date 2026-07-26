// Legend entry-label alignment helpers: anchor maths and the per-guide /
// theme / per-direction precedence resolved by `_label-align`, plus the legend
// title precedence resolved by `_title-align` and the alignment stored by the
// `guide-legend` / `element-text` constructors.

#import "../../src/render/legend.typ": (
  _align-offset, _hjust-below, _hjust-right-of, _label-align, _title-align,
  _title-resolved-align,
)
#import "../../src/guide/legend.typ": guide-legend
#import "../../src/theme/elements.typ": element-text, element-typst
#import "../../src/theme/defaults.typ": merge-theme
#import "../../lib.typ": theme

// Labels drawn to the right of a mark justify within the slot `[start, start +
// slot-w]`; `left` keeps the west anchor at `start`. The `mid-*` family centres
// on the cap-height / baseline band, so a descender never lifts a label.
#assert.eq(_hjust-right-of(left, 1.0, 2.0), (1.0, "mid-west"))
#assert.eq(_hjust-right-of(center, 1.0, 2.0), (2.0, "mid"))
#assert.eq(_hjust-right-of(right, 1.0, 2.0), (3.0, "mid-east"))

// Labels drawn below a mark hold x at `cx` and only vary the anchor; `center`
// keeps the current north anchor.
#assert.eq(_hjust-below(left, 5.0), (5.0, "north-west"))
#assert.eq(_hjust-below(center, 5.0), (5.0, "north"))
#assert.eq(_hjust-below(right, 5.0), (5.0, "north-east"))

#let guide-with(align, direction) = (
  align: align,
  placement: (direction: direction),
)

// Per-direction default with no guide or theme override: horizontal centres,
// vertical keeps left.
#assert.eq(_label-align(guide-with(none, "horizontal"), none), center)
#assert.eq(_label-align(guide-with(none, "vertical"), none), left)

// The theme `legend-text` align overrides the per-direction default.
#assert.eq(_label-align(guide-with(none, "vertical"), right), right)
#assert.eq(_label-align(guide-with(none, "horizontal"), left), left)

// A per-guide align wins over both the theme align and the default.
#assert.eq(_label-align(guide-with(center, "vertical"), right), center)
#assert.eq(_label-align(guide-with(right, "horizontal"), left), right)

// `_title-align`: a per-guide align overrides the theme legend-title align;
// otherwise the theme align (or its `none` default) flows through to the
// left default in `_draw-title`.
#assert.eq(_title-align(left, right), left)
#assert.eq(_title-align(none, right), right)
#assert.eq(_title-align(none, none), none)

// The constructors store the Typst alignment verbatim (and `none` when unset).
#assert.eq(guide-legend(align: right).align, right)
#assert.eq(guide-legend().align, none)
#assert.eq(element-text(align: center).align, center)
#assert.eq(element-typst(align: left).align, left)

// `_align-offset` justifies a graphic of width `graphic-w` within `total-w`:
// `left` pins the left edge, `center` splits the slack, `right` pins the right.
#assert.eq(_align-offset(left, 10.0, 4.0), 0.0)
#assert.eq(_align-offset(center, 10.0, 4.0), 3.0)
#assert.eq(_align-offset(right, 10.0, 4.0), 6.0)

// `_title-resolved-align` applies the `none -> left` default so the key graphic
// can be justified the same way the title is.
#let plain = merge-theme(none)
#assert.eq(_title-resolved-align((:), plain), left)
#assert.eq(_title-resolved-align((align: center), plain), center)
// The `legend-title` theme align applies when the guide leaves `align` unset.
#let titled = merge-theme(theme(legend-title: element-text(align: right)))
#assert.eq(_title-resolved-align((:), titled), right)
#assert.eq(_title-resolved-align((align: center), titled), center)

Legend-align tests passed.
