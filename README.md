# Gribouille <picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/mcanouil/gribouille/refs/heads/main/docs/assets/images/logo-stacked-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/mcanouil/gribouille/refs/heads/main/docs/assets/images/logo-stacked.svg"><img align="right" width="120" alt="Gribouille logo." src="https://raw.githubusercontent.com/mcanouil/gribouille/refs/heads/main/docs/assets/images/logo-stacked.svg"></picture>

Create elegant graphics with the **Grammar of Graphics** for Typst.

_Gribouille_ is French for "scribble".
The library implements Wilkinson's **Grammar of Graphics** in a declarative API for Typst documents, inspired by [`ggplot2`](https://ggplot2.tidyverse.org) (R) and [`plotnine`](https://plotnine.org) (Python).

Documentation: <https://m.canouil.dev/gribouille>.

> [!WARNING]
> _Gribouille_ is in active development.

## Quick look

```typst
#import "@preview/gribouille:0.2.0": *

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
    geom-errorbar(stat: stat-summary(fun: "mean-sd"), width: 5pt),
    geom-errorbarh(stat: stat-summary(fun: "mean-sd"), height: 5pt),
    geom-label(
      stat: stat-summary(fun: "mean"),
      mapping: aes(label: "species"),
      colour: rgb("#ffffff"),
      size: 8pt,
    ),
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
  labs: labs(
    title: typst("Penguins *Dataset*"),
    subtitle: typst({
      [Flipper length vs body mass by species: ]
      species-colours
        .pairs()
        .map(p => text(fill: p.at(1), weight: "bold")[#p.at(0)])
        .join(", ")
    }),
    caption: "Data from Palmer Archipelago (Antarctica) penguin dataset.",
    colour: "Species",
    fill: "Species",
    shape: "Species",
    x: "Flipper Length (mm)",
    y: "Body Mass (g)",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
```

## Dependencies

See [`typst.toml`](typst.toml) and [`src/deps.typ`](src/deps.typ) for the authoritative Typst compiler and CeTZ versions.

## Contributing

Contributions are welcome.
See [`CONTRIBUTING.md`](CONTRIBUTING.md) for bug reporting, development setup, and commit conventions.
Short identifiers used across the source tree (`ctx`, `spec`, `mapping`, `cx`, `cy`, `lo`, `hi`, …) are catalogued in [`src/GLOSSARY.md`](src/GLOSSARY.md).

## Citation

If you use _Gribouille_ in your work, please cite it.
Citation metadata is provided in [`CITATION.cff`](CITATION.cff).
GitHub renders it via the "Cite this repository" widget on the repository sidebar.

## License

This project is licensed under the MIT License.
See the [LICENSE](LICENSE) file for details.
