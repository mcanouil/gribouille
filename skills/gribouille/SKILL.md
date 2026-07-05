---
name: gribouille
description: "Use when authoring, editing, or debugging a Gribouille grammar-of-graphics plot in a Typst document: writing a #plot() call with aes() mappings and geom-*, stat-*, or scale-* layers, adding coords, facets, guides, or themes, or turning data into a scatter, line, bar, boxplot, smooth, or contour figure with the @preview/gribouille package."
---

# Authoring gribouille plots

Gribouille is a grammar-of-graphics plotting library for Typst; the API mirrors `ggplot2` (R) and `plotnine` (Python).
A plot layers `geom-*` over shared data and an aesthetic mapping.

## Import

```typst
#import "@preview/gribouille:0.4.1": *
```

Pin the version to the installed one; check it via `llms.txt` or Typst Universe.

## Mental model

Pipeline, forward only:

```text
data → stat → position → scale → coord → facet → theme → render
```

- `data`: a dictionary of column arrays, or a built-in dataset (`penguins`, `mpg`, `economics`).
- `mapping: aes(...)`: column names to aesthetics (`x`, `y`, `colour`, `fill`, `shape`, `size`, `label`, …).
- `layers`: a tuple of `geom-*`; each geom may set its own `stat`, `position`, and `mapping`.
- `scales`: how values map to axes and palettes.
- `coord`, `facets`, `labels`, `guides`, `theme`: everything else.
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

## Reference protocol

The API is pre-1.0; names and arguments change between releases.
Do not recall a geom, stat, scale, or argument from memory; confirm each against the machine-readable reference.

1. Index: `https://m.canouil.dev/gribouille/llms.txt` lists every page and its `.llms.md`.
2. Fetch the symbol's page, e.g., `.../reference/geoms/geom-smooth.llms.md`, `.../reference/scales/scale-colour-viridis-d.llms.md`, `.../reference/stats/stat-summary.llms.md`.
   Every `<page>.html` has a sibling `<page>.llms.md`.
3. Use only the arguments, defaults, and types documented there.

Families under `reference/`: `core`, `geoms`, `stats`, `scales`, `coord`, `facets`, `positions`, `guides`, `labels`, `themes`, `helpers`, `datasets`.
Tutorials: `get-started/`, `guides/`, `examples/`.

## Validate

Compile before claiming success:

```bash
typst compile plot.typ
```

Errors follow the shape `<scope>: <problem>; got <value>. <hint>`; read the hint, then re-check the argument against its `.llms.md` page.
