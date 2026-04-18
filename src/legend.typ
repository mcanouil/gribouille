// Guide extraction and legend drawing.
// Supports discrete colour/fill (swatch legend) and continuous colour/fill
// (colourbar), rendered to the right of the panel.

#import "@preview/cetz:0.5.0"
#import "utils/pretty.typ": pretty

#let _guide-title(t, spec, aes-name) = {
  if t.at("spec", default: none) != none and t.spec.at("name", default: none) != none {
    t.spec.name
  } else if spec.mapping != none {
    spec.mapping.at(aes-name, default: aes-name)
  } else {
    aes-name
  }
}

#let guides-for(spec, trained) = {
  let guides = ()
  for aes-name in ("colour", "fill") {
    let t = trained.at(aes-name, default: none)
    if t == none { continue }
    let title = _guide-title(t, spec, aes-name)
    if t.type == "discrete" {
      guides.push((
        kind: "swatch",
        aesthetic: aes-name,
        title: title,
        levels: t.domain,
      ))
    } else if t.type == "continuous" {
      guides.push((
        kind: "colourbar",
        aesthetic: aes-name,
        title: title,
        domain: t.domain,
      ))
    }
  }
  guides
}

#let _palette-for(trained, fallback) = {
  let spec = trained.at("spec", default: none)
  if spec == none { return fallback }
  let p = spec.at("palette", default: auto)
  if p == auto or p == none { fallback } else { p }
}

#let _resolve-colour-simple(trained, value, palette) = {
  if trained == none or value == none { return rgb("#222222") }
  let pal = _palette-for(trained, palette)
  if trained.type == "discrete" {
    let s = str(value)
    let idx = trained.domain.position(v => v == s)
    if idx == none { return rgb("#222222") }
    pal.at(calc.rem(idx, pal.len()))
  } else {
    let (lo, hi) = trained.domain
    if hi == lo { return pal.first() }
    let t = calc.max(0.0, calc.min(1.0, (value - lo) / (hi - lo)))
    let a = pal.first()
    let b = pal.last()
    a.mix((b, t * 100%))
  }
}

#let _format-break(n) = {
  if type(n) == int { return str(n) }
  if calc.abs(n - calc.round(n)) < 1e-9 { return str(calc.round(n)) }
  str(calc.round(n, digits: 3))
}

#let estimate-width(guides) = {
  if guides.len() == 0 { return 0.0 }
  let max-width = 0.0
  for g in guides {
    if g.kind == "swatch" {
      let max-chars = g.title.len()
      for level in g.levels {
        max-chars = calc.max(max-chars, level.len())
      }
      max-width = calc.max(max-width, calc.min(3.5, 0.6 + max-chars * 0.18))
    } else if g.kind == "colourbar" {
      let (lo, hi) = g.domain
      let breaks = pretty(lo, hi, n: 5)
      let max-chars = g.title.len()
      for b in breaks {
        max-chars = calc.max(max-chars, _format-break(b).len())
      }
      // Colourbar strip width + padding + tick labels.
      max-width = calc.max(max-width, 0.45 + 0.2 + max-chars * 0.18)
    }
  }
  max-width
}

#let _swatch-height(guide) = {
  let title-h = 0.45
  let line-h = 0.4
  title-h + line-h * guide.levels.len() + 0.2
}

#let _colourbar-height() = {
  let title-h = 0.45
  let bar-h = 3.0
  title-h + bar-h + 0.3
}

#let _draw-swatch(guide, ctx, ox, cursor) = {
  let title-h = 0.45
  let line-h = 0.4
  let glyph-size = 0.12
  let trained = ctx.trained.at(guide.aesthetic)
  cetz.draw.content(
    (ox, cursor),
    text(size: 8pt, weight: "medium")[#guide.title],
    anchor: "north-west",
  )
  let c = cursor - title-h
  for level in guide.levels {
    let colour = _resolve-colour-simple(trained, level, ctx.palette)
    cetz.draw.circle(
      (ox + glyph-size, c - glyph-size),
      radius: glyph-size,
      fill: colour,
      stroke: none,
    )
    cetz.draw.content(
      (ox + glyph-size * 2 + 0.15, c - glyph-size),
      text(size: 8pt)[#level],
      anchor: "west",
    )
    c -= line-h
  }
}

#let _draw-colourbar(guide, ctx, ox, cursor) = {
  let title-h = 0.45
  let bar-w = 0.35
  let bar-h = 3.0
  let tick-gap = 0.08
  let trained = ctx.trained.at(guide.aesthetic)
  let (lo, hi) = guide.domain
  cetz.draw.content(
    (ox, cursor),
    text(size: 8pt, weight: "medium")[#guide.title],
    anchor: "north-west",
  )
  let bar-top = cursor - title-h
  let bar-bottom = bar-top - bar-h
  let steps = 40
  let step-h = bar-h / steps
  for i in range(steps) {
    let t = (i + 0.5) / steps
    let value = lo + t * (hi - lo)
    let colour = _resolve-colour-simple(trained, value, ctx.palette)
    let y-lo = bar-bottom + i * step-h
    let y-hi = y-lo + step-h
    cetz.draw.rect(
      (ox, y-lo),
      (ox + bar-w, y-hi),
      fill: colour,
      stroke: none,
    )
  }
  cetz.draw.rect(
    (ox, bar-bottom),
    (ox + bar-w, bar-top),
    fill: none,
    stroke: (paint: rgb("#888888"), thickness: 0.2pt),
  )
  let breaks = pretty(lo, hi, n: 5)
  for b in breaks {
    if hi == lo { continue }
    let t = (b - lo) / (hi - lo)
    if t < 0 or t > 1 { continue }
    let cy = bar-bottom + t * bar-h
    cetz.draw.line(
      (ox + bar-w, cy),
      (ox + bar-w + 0.1, cy),
      stroke: (paint: rgb("#555555"), thickness: 0.3pt),
    )
    cetz.draw.content(
      (ox + bar-w + tick-gap + 0.1, cy),
      text(size: 8pt)[#_format-break(b)],
      anchor: "west",
    )
  }
}

#let draw(guides, ctx, origin, height) = {
  if guides.len() == 0 { return }
  let (ox, oy) = origin
  let cursor = oy + height
  for g in guides {
    if g.kind == "swatch" {
      _draw-swatch(g, ctx, ox, cursor)
      cursor -= _swatch-height(g)
    } else if g.kind == "colourbar" {
      _draw-colourbar(g, ctx, ox, cursor)
      cursor -= _colourbar-height()
    }
  }
}
