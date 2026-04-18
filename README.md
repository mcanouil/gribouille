# gribouille

A layered grammar of graphics for Typst.

_Gribouille_ is French for "scribble".
The library implements Wilkinson's grammar of graphics in a ggplot2-inspired, declarative API for Typst documents.

## Status

_Gribouille_ is in active development.

## Quick look

```typst
#import "@preview/gribouille:0.1.0": *

#let df = csv("mtcars.csv", row-type: dictionary)

#plot(
  data: df,
  mapping: aes(x: "wt", y: "mpg", colour: "cyl"),
  layers: (
    geom-point(size: 2pt),
    geom-smooth(method: "lm"),
  ),
  scales: (
    scale-x-continuous(name: "Weight (1000 lbs)"),
    scale-y-continuous(name: "MPG"),
  ),
  facet: facet-wrap("am"),
  theme: theme-minimal(),
)
```

## Scope (v1)

- Geoms: `geom-point`, `geom-line`, `geom-col`, `geom-histogram`, `geom-smooth` (linear only), `geom-ribbon`, `geom-boxplot` (pre-summarised).
- Aesthetics: `x`, `y`, `colour`, `fill`, `size`, `group`, `alpha`.
- Scales: continuous and discrete for position, colour, fill, and size; identity and log10 transforms.
- Coordinates: cartesian with non-dropping limits.
- Stats: `stat-identity`, `stat-count`, `stat-bin`, `stat-smooth`.
- Positions: identity, stack, dodge, jitter.
- Facets: `facet-wrap` with shared scales.
- Themes: `theme-minimal`, `theme-classic`, `theme-void`.
- Automatic legends.

## Dependencies

- Typst 0.14 or later.
- CeTZ 0.5 as the drawing backend.

## Licence

MIT.
