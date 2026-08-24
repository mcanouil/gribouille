---
name: gribouille
description: "Use when authoring, editing, or debugging a Gribouille grammar-of-graphics plot in a Typst document: writing a #plot() call with aes() mappings and geom-*, stat-*, or scale-* layers, adding coords, facets, guides, or themes, or turning data into a scatter, line, bar, boxplot, histogram, density, violin, ridgeline, 2D-density, beeswarm, smooth, or contour figure with the @preview/gribouille package."
---

# Authoring gribouille plots

Gribouille is a grammar-of-graphics plotting library for Typst.
The API mirrors `ggplot2` (R) and `plotnine` (Python).
A plot layers `geom-*` over shared data and an aesthetic mapping.

## Import

```typst
#import "@preview/gribouille:0.8.0": *
```

Pin the version to the installed one.
Check it via `llms.txt` or Typst Universe.

## Mental model

Pipeline, forward only:

```text
data → stat → position → scale → coord → facet → theme → render
```

- `data`: a dictionary of column arrays, or a built-in dataset (`penguins`, `mpg`, `economics`).
- `mapping: aes(...)`: column names to aesthetics (`x`, `y`, `colour`, `fill`, `shape`, `size`, `alpha`, `linetype`, `label`, …).
  Gribouille rejects unknown channels, including the US spelling `color`.
- `layers`: a tuple of `geom-*`.
  Each geom can set its own `stat`, `position`, `mapping`, and `key` (legend glyph).
  Stat-backed geoms take `stat: auto` to build their default stat from the geom parameters.
- `scales`: how values map to axes and palettes.
  See the scales section below.
- `coord`, `facet`, `labels`, `guides`, `theme`: everything else.
- Late binding: `after-stat(...)`, `after-scale(...)`, `from-theme(...)`, `stage(...)`.

## Call shape

```typst
#plot(
  data: <dict-of-columns or dataset>,
  mapping: aes(x: "...", y: "...", colour: "...", ...),
  layers: (
    geom-point(...),
    geom-smooth(method: "lm", se: true),
    // more layers ...
  ),
  scales: scales(
    x: scale-continuous(),
    colour: scale-discrete(...),
    // more scales ...
  ),
  coord: coord-cartesian(),    // optional
  facet: facet-wrap("group"),  // optional
  labels: labels(title: "...", x: "...", y: "..."),
  guides: guides(...),         // optional; guides(default: none) hides all legends
  theme: theme-minimal(),
  alt: "...",                  // optional accessibility text
  width: 12cm,                 // default 10cm
  height: 9cm,                 // default 7cm
)
```

`as-spec: true` returns the raw spec instead of rendering, for `compose()` composition.

## Scales

Scale constructors are aesthetic-agnostic.
The aesthetic comes from the `scales()` key:

- `scales(colour: scale-viridis-d())`, not `scale-colour-viridis-d()`.
- `scales(x: scale-log10())`, not `scale-x-log10()`.

`plot(scales:)` accepts only the `scales()` dictionary.
There is no positional array.
The same constructor adapts to its key (axis for `x`/`y`, palette for `colour`/`fill`, output range for `size`/`alpha`/…).
Unknown constructor arguments, unknown aesthetics, and positional arguments fail at binding.
The error lists the valid keys.

## Symbol inventory

What exists, by family (regenerate with `lua tools/skill-inventory.lua`).
Arguments, defaults, and types still come from each symbol's `.llms.md` reference page.

<!-- inventory:begin -->

- **Core**: `plot`, `compose`, `defer`, `aes`, `as-factor`, `as-numeric`, `typst`, `after-scale`, `after-stat`, `from-theme`, `stage`.
- **Datasets**: `economics`, `mpg`, `penguins`.
- **Labels**: `labels`.
- **Guides**: `guide-legend`, `guide-axis`, `guide-axis-logticks`, `guide-axis-stack`, `guide-axis-theta`, `guide-custom`, `guides`, `draw-key-blank`, `draw-key-line`, `draw-key-path`, `draw-key-point`, `draw-key-rect`.
- **Geoms**: `annotate`, `geom-point`, `geom-line`, `geom-path`, `geom-step`, `geom-area`, `geom-rect`, `geom-tile`, `geom-bin-2d`, `geom-hex`, `geom-contour`, `geom-contour-filled`, `geom-segment`, `geom-curve`, `geom-spoke`, `geom-polygon`, `geom-ellipse`, `geom-mark`, `geom-col`, `geom-bar`, `geom-histogram`, `geom-freqpoly`, `geom-density`, `geom-density-2d`, `geom-density-2d-filled`, `geom-smooth`, `geom-ribbon`, `geom-boxplot`, `geom-violin`, `geom-density-ridges`, `geom-errorbar`, `geom-errorbarh`, `geom-count`, `geom-linerange`, `geom-crossbar`, `geom-pointrange`, `geom-hline`, `geom-vline`, `geom-abline`, `geom-text`, `geom-typst`, `geom-label`, `geom-jitter`, `geom-beeswarm`, `geom-blank`, `geom-rug`, `geom-function`, `geom-dotplot`, `geom-quantile`, `geom-qq`, `geom-qq-line`.
- **Stats**: `stat-identity`, `stat-count`, `stat-density`, `stat-density-2d`, `stat-density-2d-filled`, `stat-ydensity`, `stat-density-ridges`, `stat-sum`, `stat-function`, `stat-bin`, `stat-bin-2d`, `stat-bin-hex`, `stat-contour`, `stat-contour-filled`, `stat-bindot`, `stat-smooth`, `stat-boxplot`, `stat-summary`, `stat-summary-bin`, `stat-summary-2d`, `stat-summary-hex`, `stat-ecdf`, `stat-unique`, `stat-qq`, `stat-qq-line`, `stat-ellipse`, `stat-quantile`, `stat-manual`, `stat-connect`, `stat-align`, `stat-difference`, `stat-waffle`.
- **Helpers**: `get-alt-text`, `arrow`, `format-comma`, `format-currency`, `format-log`, `format-lower`, `format-number`, `format-percent`, `format-scientific`, `format-title`, `format-upper`, `format-wrap`, `mean`, `mean-cl-boot`, `mean-cl-normal`, `mean-sd`, `mean-se`, `median`, `median-hilow`, `quantile`, `quantiles`, `cut-interval`, `cut-number`, `cut-width`, `resolution`, `qnorm`.
- **Wrangle**: `count`, `summarise`, `distinct`, `drop-na`, `relocate`, `rename`, `select`, `slice-max`, `slice-min`, `pivot-longer`, `pivot-wider`, `anti-join`, `bind-cols`, `bind-rows`, `full-join`, `inner-join`, `left-join`, `semi-join`.
- **Scales**: `scales`, `scale-area`, `scale-binned`, `scale-binned-area`, `scale-brewer`, `scale-continuous`, `scale-date`, `scale-datetime`, `scale-discrete`, `scale-distiller`, `scale-fermenter`, `scale-gradient`, `scale-gradient2`, `scale-gradientn`, `scale-grey`, `scale-hue`, `scale-identity`, `scale-log10`, `scale-manual`, `scale-okabe-ito`, `scale-radius`, `scale-reverse`, `scale-sqrt`, `scale-steps`, `scale-steps2`, `scale-stepsn`, `scale-time`, `scale-viridis-b`, `scale-viridis-c`, `scale-viridis-d`, `dup-axis`, `sec-axis`, `breaks-extended`, `breaks-log`, `breaks-pretty`, `breaks-quantile`, `breaks-width`, `brewer-palette`, `okabe-ito`, `colour-mix`, `expand-limits`.
- **Coord**: `coord-cartesian`, `coord-fixed`, `coord-flip`, `coord-radial`, `coord-transform`.
- **Positions**: `position-stack`, `position-dodge`, `position-fill`, `position-identity`, `position-jitter`, `position-jitterdodge`, `position-beeswarm`, `position-nudge`.
- **Facets**: `facet-wrap`, `facet-grid`, `label-both`, `label-context`, `label-value`, `label-wrap`, `labeller`.
- **Themes**: `theme-grey`, `theme-minimal`, `theme-classic`, `theme-void`, `theme-bw`, `theme-linedraw`, `theme-light`, `theme-dark`, `theme-brand`, `theme`, `element-blank`, `element-geom`, `element-line`, `element-rect`, `element-text`, `element-tick`, `element-typst`, `margin`, `theme-sub-axis`, `theme-sub-axis-bottom`, `theme-sub-axis-left`, `theme-sub-axis-right`, `theme-sub-axis-top`, `theme-sub-axis-x`, `theme-sub-axis-y`, `theme-sub-legend`, `theme-sub-panel`, `theme-sub-plot`, `theme-sub-strip`, `theme-get`, `theme-set`.

<!-- inventory:end -->

## Worked example

```typst
#import "@preview/gribouille:0.8.0": *

#let species-colours = (
  Adelie: rgb("#ff8c00"),
  Chinstrap: rgb("#008B8B"),
  Gentoo: rgb("#800080"),
)

#let species-scale = scale-discrete(
  limits: species-colours.keys(),
  palette: species-colours.values(),
)

#plot(
  data: penguins,
  mapping: aes(
    x: "flipper-len",
    y: "body-mass",
    colour: "species",
    fill: "species",
    shape: "species",
  ),
  layers: (
    geom-point(size: 2pt, alpha: 0.25, stroke: 0.5pt, colour: rgb("#ffffff")),
    geom-smooth(method: "lm", se: true, alpha: 0.2),
    geom-mark(method: "hull", expand: 5pt, alpha: 0.25),
  ),
  scales: scales(
    x: scale-continuous(),
    y: scale-continuous(labels: format-comma()),
    colour: species-scale,
    fill: species-scale,
  ),
  labels: labels(
    title: typst("Penguins *Dataset*"),
    x: "Flipper Length (mm)",
    y: "Body Mass (g)",
  ),
  guides: guides(default: none),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
```

Bind a shared scale once (`species-scale`) and reuse it for every aesthetic that carries the same palette.

## Density and pattern fills

Kernel density estimation is native.
The same KDE core backs `geom-violin`, `geom-density-ridges`, `geom-density-2d`, and `geom-density-2d-filled`:

```typst
#plot(
  data: penguins,
  mapping: aes(x: "body-mass", fill: "species"),
  layers: (geom-density(fill: auto, alpha: 0.4),),
)
```

Fills accept native Typst `tiling` paints, as fixed `fill:` values or through a palette.
Legend swatches render the pattern:

```typst
#let stripes(base, ink) = tiling(size: (5pt, 5pt))[
  #place(box(width: 5pt, height: 5pt, fill: base))
  #place(line(start: (0%, 100%), end: (100%, 0%), stroke: 1pt + ink))
]

#plot(
  data: (g: ("a", "a", "b", "b"), n: (3, 5, 2, 4), k: ("x", "y", "x", "y")),
  mapping: aes(x: "g", y: "n", fill: "k"),
  layers: (geom-col(position: "dodge"),),
  scales: scales(fill: scale-manual(values: (
    stripes(rgb("#fde68a"), rgb("#b45309")),
    stripes(rgb("#bfdbfe"), rgb("#1d4ed8")),
  ))),
)
```

## Gotchas

- Aesthetics use British spelling: `colour`, not `color`.
  On error, `aes()` lists the valid channels.
- Fill opacity defaults to 1 on `geom-area`, `geom-ribbon`, `geom-polygon`, `geom-ellipse`, and `geom-mark`.
  For translucency, pass `alpha:`.
- `stroke:` accepts the native Typst `1.3pt + accent` form (thickness and paint together).
  An explicit `colour:` wins over the embedded paint.
- Unknown `stat`, scale `transform`, `oob`, or `theme()` element names fail fast instead of silently rendering as identity.
- CSV string-numeric columns stay discrete.
  For a continuous scale, call `as-numeric(data, "col")`.

## Reference protocol

The API is pre-1.0.
Names and arguments change between releases.
Do not recall a geom, stat, scale, or argument from memory.
Confirm each against the machine-readable reference.

1. Index: `https://m.canouil.dev/gribouille/llms.txt` lists every page and its `.llms.md`.
2. Fetch the symbol's page, e.g., `.../reference/geoms/geom-smooth.llms.md`, `.../reference/scales/scale-viridis-d.llms.md`, `.../reference/stats/stat-summary.llms.md`.
   Every `<page>.html` has a sibling `<page>.llms.md`.
3. Use only the arguments, defaults, and types documented there.

Families under `reference/`: `core`, `geoms`, `stats`, `scales`, `coord`, `facets`, `positions`, `guides`, `labels`, `themes`, `helpers`, `datasets`.
Tutorials: `get-started/`, `guides/`, `examples/`.

## Validate

Compile before claiming success:

```bash
typst compile plot.typ
```

Errors follow the shape `<scope>: <problem>; got <value>. <hint>`.
Read the hint, then re-check the argument against its `.llms.md` page.
