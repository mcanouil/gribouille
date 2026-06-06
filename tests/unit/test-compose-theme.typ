// compose theme resolution: explicit wins and propagates, else a shared panel
// theme, else the global theme state.

#import "../../src/compose.typ": (
  _is-compose-spec, _resolve-compose-theme, compose, defer,
)
#import "../../src/plot.typ": plot
#import "../../src/theme/current.typ": theme-set

// Sentinel themes; `_resolve-compose-theme` only compares and stores them, so
// their content is irrelevant to the selection logic.
#let ta = (kind: "theme", name: "a")
#let tb = (kind: "theme", name: "b")
#let tc = (kind: "theme", name: "c")
#let tg = (kind: "theme", name: "global")

// Explicit theme wins over differing panel themes; panels that already carry a
// theme keep it.
#let r1 = _resolve-compose-theme(((theme: ta), (theme: tb)), tc)
#assert.eq(r1.theme, tc)
#assert.eq(r1.panels.first().theme, ta)
#assert.eq(r1.panels.at(1).theme, tb)

// Explicit theme is injected into a panel that sets none; a themed panel is left
// untouched.
#let r2 = _resolve-compose-theme(((theme: none), (theme: tb)), tc)
#assert.eq(r2.theme, tc)
#assert.eq(r2.panels.first().theme, tc)
#assert.eq(r2.panels.at(1).theme, tb)

// No explicit theme: a theme shared by every panel is used, panels unchanged.
#let r3 = _resolve-compose-theme(((theme: ta), (theme: ta)), none)
#assert.eq(r3.theme, ta)
#assert.eq(r3.panels.first().theme, ta)

// A nested compose panel (no `theme` field) inherits the explicit theme while
// keeping its kind, so its own `_render-compose` propagates one level deeper.
#let r4 = _resolve-compose-theme(((kind: "compose"),), tc)
#assert.eq(r4.panels.first().theme, tc)
#assert.eq(r4.panels.first().kind, "compose")

// No explicit theme and panels disagree: fall back to the global state, not the
// first panel. With no global set, the source is `none`.
#context {
  assert.eq(
    _resolve-compose-theme(((theme: ta), (theme: tb)), none).theme,
    none,
  )
}

// Once a global theme is set, mixed panels resolve to it.
#theme-set(tg)
#context {
  assert.eq(_resolve-compose-theme(((theme: ta), (theme: tb)), none).theme, tg)
  // All-none panels also defer to the global theme.
  assert.eq(
    _resolve-compose-theme(((theme: none), (theme: none)), none).theme,
    tg,
  )
}

// The `theme` argument is stored on the compose spec and forwarded by `defer`.
#let panel = defer(plot, layers: (), data: (), width: 4cm, height: 3cm)
#let spec = compose(panel, panel, theme: tc, as-spec: true)
#assert(_is-compose-spec(spec))
#assert.eq(spec.theme, tc)

#let spec-default = compose(panel, panel, as-spec: true)
#assert.eq(spec-default.theme, none)

Compose theme resolution tests passed.
