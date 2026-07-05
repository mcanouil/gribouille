---
name: gribouille
description: >-
  Author grammar-of-graphics plots with the gribouille Typst library: the
  #plot() call, aes() mappings, geom-* layers, stat-* transforms, scale-*,
  coords, facets, and themes. Use when building, editing, or debugging a
  gribouille chart in a Typst document, or when a request maps data to a
  scatter, line, bar, boxplot, smooth, contour, or similar figure in Typst.
---

# Authoring gribouille plots

Gribouille implements Wilkinson's Grammar of Graphics for Typst, modelled on
[`ggplot2`](https://ggplot2.tidyverse.org) (R) and [`plotnine`](https://plotnine.org) (Python).
A plot is a stack of layers over a shared data and aesthetic mapping.

## Import

```typst
#import "@preview/gribouille:0.4.1": *
```

Pin the version to the one the user has installed.
Confirm the current version from `https://m.canouil.dev/gribouille/llms.txt` or `typst.app/universe/package/gribouille` before writing the import.

## Mental model

Data flows forward through one pipeline; no stage reaches back:

```text
data → stat → position → scale → coord → facet → theme → render
```

Build a plot by declaring, not by drawing:

- `data` is a dictionary of columns (arrays), or a built-in dataset (`penguins`, `mpg`, `economics`).
- `mapping: aes(...)` maps column names to aesthetics (`x`, `y`, `colour`, `fill`, `shape`, `size`, `label`, …).
- `layers` is a tuple of `geom-*` constructors; each geom may carry its own `stat`, `position`, and per-layer `mapping`.
- `scales` control how data values map to visual values (axes, colour palettes, …).
- `coord`, `facets`, `labels`, `guides`, `theme` shape the rest.

Late binding resolves a value at a later stage: `after-stat(...)`, `after-scale(...)`, `from-theme(...)`, `stage(...)`.

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
  scales: (
    scale-x-continuous(),
    scale-colour-discrete(...),
    // more scales ...
  ),
  coord: coord-cartesian(),   // optional
  facets: facet-wrap("group"), // optional
  labels: labels(title: "...", x: "...", y: "..."),
  guides: guides(...),         // optional
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
```

## Worked example

```typst
#import "@preview/gribouille:0.4.1": *

#let species-colours = (
  Adelie: rgb("#ff8c00"),
  Chinstrap: rgb("#008B8B"),
  Gentoo: rgb("#800080"),
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
  scales: (
    scale-x-continuous(),
    scale-y-continuous(labels: format-comma()),
    scale-colour-discrete(
      limits: species-colours.keys(),
      palette: species-colours.values(),
    ),
    scale-fill-discrete(
      limits: species-colours.keys(),
      palette: species-colours.values(),
    ),
  ),
  labels: labels(
    title: typst("Penguins *Dataset*"),
    x: "Flipper Length (mm)",
    y: "Body Mass (g)",
    colour: "Species",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
```

## Reference protocol — always confirm arguments

The library is pre-1.0; constructor names and arguments change between releases.
Never invent or recall a geom, stat, scale, or argument from memory.
Confirm every symbol against the published, machine-readable reference, which mirrors the site and is regenerated on every docs build:

1. Fetch the index: `https://m.canouil.dev/gribouille/llms.txt`.
   It lists every documentation page, each linking to a `.llms.md` file.
2. Fetch the page for the symbol you need, for example:
   - `https://m.canouil.dev/gribouille/reference/geoms/geom-smooth.llms.md`
   - `https://m.canouil.dev/gribouille/reference/scales/scale-colour-viridis-d.llms.md`
   - `https://m.canouil.dev/gribouille/reference/stats/stat-summary.llms.md`
   Any published page's `<page>.html` has a sibling `<page>.llms.md`.
3. Use only the arguments documented on that page, with the documented defaults and types.

Reference families under `reference/`: `core`, `geoms`, `stats`, `scales`,
`coord`, `facets`, `positions`, `guides`, `labels`, `themes`, `helpers`,
`datasets`.
Broader tutorials live at `get-started/`, `guides/`, and `examples/`, each with a `.llms.md` companion.

## Validate

Compile before claiming success:

```bash
typst compile plot.typ
```

Errors follow the shape `<scope>: <problem>; got <value>. <hint>` — read the hint, then re-check the argument against its `.llms.md` page.
