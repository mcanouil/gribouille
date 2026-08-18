// element-rect margin demos across each background slot.
//
// `inset` is honoured on `plot-background` only — Typst's `block(inset:)`
// pads the content inward and grows the painted fill past it (when a fill
// is set) while keeping the rect bound at the surrounding block edge. Both
// `inset` and `outset` apply on `plot-background` even with no fill or
// stroke, reserving plot padding on their own. Cetz rect surfaces (panel,
// legend, legend-bar) stay glued to their natural bound regardless of
// `inset`, so the rect never bleeds onto neighbours. `strip-background`
// ignores both fields entirely.
//
// `outset` reserves outer whitespace by widening the chrome slot on the
// requested side — the panel canvas shrinks, the rect stays at its
// natural (shrunk) bound.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let d = (
  (x: 1, y: 1, g: "a", k: 0.10),
  (x: 2, y: 2, g: "b", k: 0.40),
  (x: 3, y: 3, g: "c", k: 0.70),
  (x: 4, y: 4, g: "a", k: 0.95),
)

#let common(label, t) = plot(
  data: d,
  mapping: aes(x: "x", y: "y", colour: "g"),
  layers: (geom-point(size: 4pt),),
  labels: labels(title: label),
  theme: t,
  width: 7cm,
  // Tall enough for the right legend: an outset on `legend-background` adds to
  // its height, and a legend that cannot fit the panel now fails the plot.
  height: 5.5cm,
)

#let panel-outset-theme = theme(panel-background: element-rect(
  fill: rgb("#fff3e0"),
  colour: rgb("#cc6600"),
  stroke: 0.6pt,
  outset: margin(top: 0.4cm, right: 0.4cm, bottom: 0.4cm, left: 0.4cm),
))

#let legend-outset-theme = theme(legend-background: element-rect(
  fill: rgb("#e8eaf6"),
  colour: rgb("#3949ab"),
  stroke: 0.5pt,
  outset: margin(right: 0.6cm),
))

#let plot-bg-inset-theme = theme(plot-background: element-rect(
  fill: rgb("#e6f4ea"),
  colour: rgb("#2e7d4a"),
  stroke: 0.6pt,
  inset: margin(top: 0.5cm, right: 0.5cm, bottom: 0.5cm, left: 0.5cm),
))

#let plot-bg-outset-theme = theme(plot-background: element-rect(
  fill: rgb("#e6f4ea"),
  colour: rgb("#2e7d4a"),
  stroke: 0.6pt,
  outset: margin(top: 0.3cm, right: 0.3cm, bottom: 0.3cm, left: 0.3cm),
))

#let plot-bg-nofill-theme = theme(plot-background: element-rect(
  inset: margin(bottom: 0.5cm),
))

#let plot-bg-pct-theme = theme(plot-background: element-rect(
  fill: rgb("#f0f4ff"),
  colour: rgb("#3949ab"),
  stroke: 0.5pt,
  inset: margin(top: 5%, right: 5%, bottom: 5%, left: 5%),
))

#let legend-all-theme = theme(legend-background: element-rect(
  fill: rgb("#e6f4ea"),
  colour: rgb("#2222b2"),
  stroke: 0.5pt,
  inset: margin(top: 0.4cm, right: 0.3cm, bottom: 0.4cm, left: 0.3cm),
  outset: margin(top: 0.8cm, right: 0.3cm, bottom: 0.3cm, left: 0.3cm),
))

#grid(
  columns: 2,
  column-gutter: 0.6cm,
  row-gutter: 0.6cm,
  common("panel-background outset (panel shrinks)", panel-outset-theme),
  common("legend-background outset (extra right gap)", legend-outset-theme),

  common("plot-background inset (fill grows)", plot-bg-inset-theme),
  common("plot-background outset (outer pad)", plot-bg-outset-theme),

  common("plot-background inset 5% (canvas-relative)", plot-bg-pct-theme),
  common("legend-bg inset + outset all sides", legend-all-theme),

  common("plot-background inset bottom, no fill", plot-bg-nofill-theme),

  plot(
    data: (
      (x: 1, y: 1, f: "p"),
      (x: 2, y: 2, f: "p"),
      (x: 1, y: 2, f: "q"),
      (x: 2, y: 1, f: "q"),
    ),
    mapping: aes(x: "x", y: "y"),
    layers: (geom-point(size: 4pt),),
    facet: facet-wrap("f"),
    labels: labels(title: "strip-background fill (inset / outset ignored)"),
    theme: theme(strip-background: element-rect(
      fill: rgb("#fce4ec"),
      colour: rgb("#ad1457"),
      stroke: 0.5pt,
    )),
    width: 8cm,
    height: 4cm,
  ),
)
