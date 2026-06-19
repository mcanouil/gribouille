// Unit tests for the extra theme presets: bw, linedraw, light, dark.

#import "../../src/theme/bw.typ": theme-bw
#import "../../src/theme/linedraw.typ": theme-linedraw
#import "../../src/theme/light.typ": theme-light
#import "../../src/theme/dark.typ": theme-dark
#import "../../src/theme/grey.typ": theme-grey
#import "../../src/theme/minimal.typ": theme-minimal
#import "../../src/theme/classic.typ": theme-classic
#import "../../src/theme/void.typ": theme-void
#import "../../src/theme/elements.typ": (
  element-blank, element-geom, element-line, element-rect, element-text,
)
#import "../../src/theme/defaults.typ": default-theme, merge-theme
#import "../../src/theme/theme.typ": _line-stroke, resolve-geom-defaults

// Keys that merge-theme consumes: every default-theme key must survive a merge.
#let _expected-keys = default-theme.keys()

#let _check-theme(t, expected-name) = {
  assert.eq(type(t), dictionary)
  assert.eq(t.kind, "theme")
  assert.eq(t.name, expected-name)
  let merged = merge-theme(t)
  for k in _expected-keys {
    assert(
      k in merged,
      message: "missing key " + k + " in merged " + expected-name,
    )
  }
  // Theme-supplied fields propagate through merge.
  for (k, v) in t.pairs() {
    assert.eq(merged.at(k), v)
  }
}

#_check-theme(theme-bw(), "bw")
#_check-theme(theme-linedraw(), "linedraw")
#_check-theme(theme-light(), "light")
#_check-theme(theme-dark(), "dark")

// Each theme must define the structural surfaces the renderer reads via
// resolve-element.
#let _structural = (
  "ink",
  "paper",
  "accent",
  "panel-background",
  "panel-grid",
  "axis-line",
)
#for t in (
  theme-bw(),
  theme-linedraw(),
  theme-light(),
  theme-dark(),
) {
  for k in _structural {
    assert(k in t, message: "theme " + t.name + " missing " + k)
  }
}

// theme-bw: white panel, light grey grid, black axes.
#let bw = theme-bw()
#assert.eq(bw.panel-background.fill, white)
#assert.eq(bw.axis-line.colour, black)
#assert(bw.panel-grid.colour != none)

// theme-linedraw: white panel, very faint grid, black axes.
#let ld = theme-linedraw()
#assert.eq(ld.panel-background.fill, white)
#assert.eq(ld.axis-line.colour, black)

// Custom ink/paper propagate.
#let custom = theme-bw(ink: rgb("#222222"), paper: rgb("#fafafa"))
#assert.eq(custom.ink, rgb("#222222"))
#assert.eq(custom.paper, rgb("#fafafa"))
#assert.eq(custom.panel-background.fill, rgb("#fafafa"))

// ── Spot-overrides on complete themes ───────────────────────────────────────

// Element override on top of a preset replaces the surface record.
#let m1 = theme-minimal(axis-text: element-text(size: 11pt))
#assert.eq(m1.axis-text.size, 11pt)
#assert.eq(m1.panel-grid.colour, color.mix(
  (black, 0.3),
  (white, 0.7),
  space: rgb,
))
#assert.eq(m1.name, "minimal")

// Structured rect override on theme-bw.
#let bw1 = theme-bw(panel-background: element-rect(fill: rgb("#ff9900")))
#assert.eq(bw1.panel-background.fill, rgb("#ff9900"))
#assert.eq(bw1.axis-line.colour, black)
#assert.eq(bw1.name, "bw")

// Structured text override on theme-classic.
#let c1 = theme-classic(axis-title: element-text(size: 14pt))
#assert.eq(c1.axis-title.size, 14pt)
#assert.eq(c1.panel-background.fill, white)
#assert.eq(c1.name, "classic")

// element-blank zeroes the targeted line on a complete theme.
#let v1 = theme-void(panel-grid: element-blank())
#assert.eq(v1.panel-grid.kind, "element-blank")

// Overrides survive merge-theme: the user value wins against the default.
#let g1 = theme-grey(panel-background: element-rect(fill: rgb("#abcdef")))
#assert.eq(g1.panel-background.fill, rgb("#abcdef"))
#let g1-merged = merge-theme(g1)
#assert.eq(g1-merged.panel-background.fill, rgb("#abcdef"))
#assert.eq(g1-merged.name, "grey")

// Multiple overrides combined in one call.
#let m2 = theme-minimal(
  axis-title: element-text(size: 14pt),
  panel-background: element-rect(fill: rgb("#f7f0e7")),
  panel-grid: element-line(colour: rgb("#d9cfbf")),
)
#assert.eq(m2.axis-title.size, 14pt)
#assert.eq(m2.panel-background.fill, rgb("#f7f0e7"))
#assert.eq(m2.panel-grid.colour, rgb("#d9cfbf"))

// ── plot-background canvas via paper override ──────────────────────────────

// Default minimal: blank panel, transparent canvas (no fill on plot-background).
#let m-default = theme-minimal()
#assert.eq(m-default.panel-background.kind, "element-blank")
#assert.eq(m-default.plot-background.kind, "element-rect")
#assert.eq(m-default.plot-background.at("fill", default: none), none)

// Explicit paper paints the canvas; panel stays transparent.
#let m-paper = theme-minimal(paper: rgb("#b22222"))
#assert.eq(m-paper.paper, rgb("#b22222"))
#assert.eq(m-paper.panel-background.kind, "element-blank")
#assert.eq(m-paper.plot-background.fill, rgb("#b22222"))

// Default void: transparent canvas, blank panel.
#let v-default = theme-void()
#assert.eq(v-default.panel-background.kind, "element-blank")
#assert.eq(v-default.plot-background.kind, "element-rect")
#assert.eq(v-default.plot-background.at("fill", default: none), none)

// Explicit paper on void paints the canvas.
#let v-paper = theme-void(paper: rgb("#fff7e6"))
#assert.eq(v-paper.plot-background.fill, rgb("#fff7e6"))

// Spot-override still trumps the paper-driven default.
#let m-blank = theme-minimal(
  paper: rgb("#b22222"),
  plot-background: element-blank(),
)
#assert.eq(m-blank.plot-background.kind, "element-blank")

// ── accent flows through element-geom ──────────────────────────────────────

// Default theme-grey: theme.accent flows into resolve-geom-defaults.accent.
#let g-default = resolve-geom-defaults(merge-theme(theme-grey()))
#assert.eq(g-default.accent, rgb("#3366FF"))
#assert.eq(g-default.ink, black)
#assert.eq(g-default.paper, white)

// Theme-level accent override propagates.
#let g-accent = resolve-geom-defaults(merge-theme(theme-grey(
  accent: rgb("#cc0000"),
)))
#assert.eq(g-accent.accent, rgb("#cc0000"))

// element-geom accent wins over theme-level accent.
#let g-elem = resolve-geom-defaults(merge-theme(theme-grey(
  accent: rgb("#cc0000"),
  geom: element-geom(accent: rgb("#00aa00")),
)))
#assert.eq(g-elem.accent, rgb("#00aa00"))

// Theme without geom slot still surfaces theme.accent.
#let g-empty = resolve-geom-defaults((kind: "theme", accent: rgb("#abcdef")))
#assert.eq(g-empty.accent, rgb("#abcdef"))

// ── Minor gridline cascade (panel-grid major / minor / -x / -y) ────────────

// Default minor halves the resolved panel-grid weight in the same colour.
#let g-merged = merge-theme(theme-grey())
#let g-major = _line-stroke(g-merged, "panel-grid-major-y")
#let g-minor = _line-stroke(g-merged, "panel-grid-minor-y")
#assert.eq(g-minor.paint, g-major.paint)
#assert.eq(g-minor.thickness, g-major.thickness * 0.5)

// A blank panel-grid keeps minors and majors blank too (classic / void).
#assert.eq(
  _line-stroke(merge-theme(theme-classic()), "panel-grid-minor-x"),
  none,
)
#assert.eq(
  _line-stroke(merge-theme(theme-void()), "panel-grid-major-x"),
  none,
)

// Per-axis override: hiding both x weights leaves the y grid drawing.
#let only-y = merge-theme(theme-grey(
  panel-grid-major-x: element-blank(),
  panel-grid-minor-x: element-blank(),
))
#assert.eq(_line-stroke(only-y, "panel-grid-major-x"), none)
#assert.eq(_line-stroke(only-y, "panel-grid-minor-x"), none)
#assert(_line-stroke(only-y, "panel-grid-major-y") != none)
#assert(_line-stroke(only-y, "panel-grid-minor-y") != none)

Extra theme tests passed.
