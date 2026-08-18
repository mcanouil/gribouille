// A discrete axis draws gridlines only when the theme sets the grid below
// `panel-grid` in the cascade, on the major weight or on one axis.

#import "../../src/theme/theme.typ": (
  _line-stroke, resolve-element, surface-set-below, theme,
)
#import "../../src/theme/elements.typ": element-blank, element-line
#import "../../src/theme/defaults.typ": merge-theme
#import "../../src/theme/classic.typ": theme-classic
#import "../../src/theme/light.typ": theme-light

// The defaults set `panel-grid` only, so no axis counts as opted in.
#let base = merge-theme(theme())
#assert.eq(surface-set-below(base, "panel-grid-major-x", "panel-grid"), false)
#assert.eq(surface-set-below(base, "panel-grid-major-y", "panel-grid"), false)

// Styling the family root stays a continuous-axis change.
#let root = merge-theme(theme(panel-grid: element-line(colour: rgb("#ff0000"))))
#assert.eq(surface-set-below(root, "panel-grid-major-y", "panel-grid"), false)
#assert.eq(resolve-element(root, "panel-grid-major-y").colour, rgb("#ff0000"))

// A per-axis record opts that axis in, and that axis only.
#let per-axis = merge-theme(theme(panel-grid-major-y: element-line()))
#assert.eq(
  surface-set-below(per-axis, "panel-grid-major-y", "panel-grid"),
  true,
)
#assert.eq(
  surface-set-below(per-axis, "panel-grid-major-x", "panel-grid"),
  false,
)

// A weight record opts both axes in, since each inherits from it.
#let per-weight = merge-theme(theme(panel-grid-major: element-line()))
#assert.eq(
  surface-set-below(per-weight, "panel-grid-major-x", "panel-grid"),
  true,
)
#assert.eq(
  surface-set-below(per-weight, "panel-grid-major-y", "panel-grid"),
  true,
)

// A built-in theme sets the family root only, so it keeps the bare default.
#let preset = merge-theme(theme-light())
#assert.eq(surface-set-below(preset, "panel-grid-major-y", "panel-grid"), false)

// An explicit blank sets the key, and the stroke resolver then draws nothing.
#let blanked = merge-theme(theme(panel-grid-major-y: element-blank()))
#assert.eq(surface-set-below(blanked, "panel-grid-major-y", "panel-grid"), true)
#assert.eq(_line-stroke(blanked, "panel-grid-major-y"), none)

// Opting in on top of a blanked grid restores the line kind.
#let revived = merge-theme(theme-classic(
  panel-grid-major-y: element-line(colour: rgb("#00ff00")),
))
#assert.eq(surface-set-below(revived, "panel-grid-major-y", "panel-grid"), true)
#assert.eq(_line-stroke(revived, "panel-grid-major-y").paint, rgb("#00ff00"))

// Minor gridlines keep their default: the walk stops before `panel-grid`, and
// the default `panel-grid-minor` record makes every minor surface count as set.
// The renderer draws no minors on a discrete axis whatever this reports.
#assert.eq(surface-set-below(base, "panel-grid-minor-y", "panel-grid"), true)
