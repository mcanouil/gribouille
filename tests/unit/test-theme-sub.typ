#import "../../src/theme/sub.typ": (
  theme-sub-axis, theme-sub-axis-bottom, theme-sub-axis-left,
  theme-sub-axis-right, theme-sub-axis-top, theme-sub-axis-x, theme-sub-axis-y,
  theme-sub-legend, theme-sub-panel, theme-sub-plot, theme-sub-strip,
)
#import "../../src/theme/elements.typ": (
  element-blank, element-line, element-rect, element-text, element-tick,
)

#let red-text = element-text(colour: red)
#let red-line = element-line(colour: red)
#let red-rect = element-rect(fill: red)
#let red-tick = element-tick(colour: red, length: 0.2cm)

#let _check-axis(ctor, suffix) = {
  let t = ctor(
    title: red-text,
    text: red-text,
    line: red-line,
    ticks: red-tick,
  )
  assert.eq(t.kind, "theme")
  assert.eq(t.at("axis-title" + suffix), red-text)
  assert.eq(t.at("axis-text" + suffix), red-text)
  assert.eq(t.at("axis-line" + suffix), red-line)
  assert.eq(t.at("axis-ticks" + suffix), red-tick)
}

#_check-axis(theme-sub-axis, "")
#_check-axis(theme-sub-axis-x, "-x")
#_check-axis(theme-sub-axis-y, "-y")
#_check-axis(theme-sub-axis-bottom, "-x-bottom")
#_check-axis(theme-sub-axis-top, "-x-top")
#_check-axis(theme-sub-axis-left, "-y-left")
#_check-axis(theme-sub-axis-right, "-y-right")

// `none` arguments are dropped by `theme()` so they don't clobber inherited
// values during cascade resolution.
#let partial = theme-sub-axis(title: red-text)
#assert.eq(partial.at("axis-title"), red-text)
#assert.eq(partial.at("axis-text", default: none), none)
#assert.eq(partial.at("axis-line", default: none), none)
#assert.eq(partial.at("axis-ticks", default: none), none)

#let tlg = theme-sub-legend(text: red-text, title: red-text)
#assert.eq(tlg.at("legend-text"), red-text)
#assert.eq(tlg.at("legend-title"), red-text)

#let tp = theme-sub-panel(grid: element-blank(), background: red-rect)
#assert.eq(tp.at("panel-grid").kind, "element-blank")
#assert.eq(tp.at("panel-background"), red-rect)

#let tpl = theme-sub-plot(
  title: red-text,
  subtitle: red-text,
  caption: red-text,
)
#assert.eq(tpl.at("plot-title"), red-text)
#assert.eq(tpl.at("plot-subtitle"), red-text)
#assert.eq(tpl.at("plot-caption"), red-text)

#let ts = theme-sub-strip(text: red-text, background: red-rect)
#assert.eq(ts.at("strip-text"), red-text)
#assert.eq(ts.at("strip-background"), red-rect)
