// Smoke render: a nanoplot axis draws ticks and labels only, within the column.
//
// The axis canvas reaches far past the column on each side, so the axis line
// of theme-bw and the plot background of theme-minimal with a paper colour are
// not drawn. Each axis must sit inside its red frame, with nothing past it.

#import "../../lib.typ": *

#set page(width: 14cm, height: auto, margin: 0.4cm)

#let axis(theme, side) = rect(
  stroke: 0.4pt + red,
  inset: 0pt,
  (
    nanoplot(
      mapping: aes(x: "x", y: "y"),
      layers: (geom-point(),),
      theme: theme,
      domain-field: "x",
    ).axis
  )(domain: (0, 10), width: 4cm, side: side),
)

#align(center, stack(
  spacing: 0.3cm,
  axis(theme-bw(), "bottom"),
  axis(theme-minimal(paper: luma(80%)), "top"),
))
