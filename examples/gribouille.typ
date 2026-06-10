#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#set page(foreground: context {
  let bg = page.fill
  let dark-bg = if bg == auto or bg == none {
    false
  } else if type(bg) == color {
    luma(bg).components().at(0) < 50%
  } else {
    false
  }
  place(
    top + right,
    dx: -0.25cm,
    dy: 0.25cm,
    image(
      if dark-bg {
        "/docs/assets/images/logo-stacked-dark.svg"
      } else {
        "/docs/assets/images/logo-stacked.svg"
      },
      height: 1cm,
    ),
  )
})

#let species-colours = (
  Adelie: rgb("#ff8c00"),
  Chinstrap: rgb("#008B8B"),
  Gentoo: rgb("#800080"),
)

#let species-card(name, note, colour, ink, paper) = context {
  block(
    width: auto,
    inset: 0pt,
    radius: 4pt,
    fill: paper,
    stroke: (paint: colour, thickness: 0.6pt),
  )[
    #set block(spacing: 0pt)

    #block(
      inset: 2pt,
      radius: 4pt,
      fill: colour,
    )[
      #set text(size: 6pt, weight: "bold", fill: if luma(colour)
        .components()
        .at(0)
        < 50% { white } else { black })
      #set par(spacing: 0pt, leading: 0.85em)
      #name
    ]
    #block(inset: (x: 4pt, y: 3pt))[
      #set text(size: 5.4pt, fill: ink)
      #note
    ]
  ]
}

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
    geom-mark(method: "hull", expand: 5pt, alpha: 0.25),
    geom-errorbar(stat: stat-summary(fun: "mean-sd"), width: 5pt),
    geom-errorbarh(stat: stat-summary(fun: "mean-sd"), height: 5pt),
    geom-typst(
      data: (
        (
          x: 183,
          y: 5000,
          species: "Adelie",
          description: "Smallest of the three; white eye-ring.",
        ),
        (
          x: 208,
          y: 2900,
          species: "Chinstrap",
          description: "Thin black band under the chin.",
        ),
        (
          x: 203,
          y: 6150,
          species: "Gentoo",
          description: "Largest brush-tailed; bright orange bill.",
        ),
      ),
      mapping: aes(
        x: "x",
        y: "y",
        label: after-stat((row, ctx) => species-card(
          row.species,
          row.description,
          species-colours.at(row.species),
          ctx.theme.at("ink", default: black),
          ctx.theme.at("paper", default: white),
        )),
      ),
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
  theme: theme-minimal(
    axis-line: element-line(stroke: 0.5pt),
    tick-length: 0.05cm,
  ),
  guides: guides(
    colour: none,
    fill: none,
    shape: none,
  ),
  width: 12cm,
  height: 9cm,
)
