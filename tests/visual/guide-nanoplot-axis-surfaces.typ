// Smoke render: a nanoplot axis draws ticks and labels only, within the column.
//
// The axis canvas reaches far past the column on each side, so the axis lines
// of theme-bw and the plot background of theme-minimal with a paper colour are
// not drawn. Each axis must sit inside its red frame, with nothing past it,
// and the page is wide enough to show a mark at either end of the canvas.

#import "../../lib.typ": *

#set page(width: 18cm, height: auto, margin: 0.4cm)

#let axis(theme, side) = rect(
  stroke: 0.4pt + red,
  inset: 0pt,
  (
    nanoplot(
      mapping: aes(x: "x", y: "y"),
      layers: (geom-point(),),
      theme: theme,
      domain-field: "x",
      axis-height: 1cm,
    ).axis
  )(domain: (0, 10), width: 3cm, side: side),
)

#align(center, stack(
  spacing: 0.3cm,
  axis(theme-bw(), "bottom"),
  axis(theme-minimal(paper: luma(80%)), "top"),
))
