// facet + compose gutter control: scalar, per-axis dict, and theme default.
//
// Four rows exercise the gutter surface:
//   1. facet-wrap with a tight scalar gutter (both axes 0.1cm);
//   2. facet-grid with an asymmetric `(x:, y:)` gutter;
//   3. facet-wrap left at `auto`, spacing driven by `theme(panel-spacing:)`;
//   4. compose with a `(x:, y:)` dict gutter between panels.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let data = (
  (x: 1, y: 2, grp: "a", side: "top"),
  (x: 2, y: 3, grp: "a", side: "bottom"),
  (x: 3, y: 1, grp: "b", side: "top"),
  (x: 1, y: 4, grp: "b", side: "bottom"),
  (x: 2, y: 2, grp: "c", side: "top"),
  (x: 3, y: 5, grp: "c", side: "bottom"),
)

#stack(
  dir: ttb,
  spacing: 0.6cm,
  plot(
    data: data,
    mapping: aes(x: "x", y: "y"),
    layers: (geom-point(),),
    facet: facet-wrap("grp", ncolumn: 3, gutter: 0.1cm),
    width: 12cm,
    height: 4cm,
  ),
  plot(
    data: data,
    mapping: aes(x: "x", y: "y"),
    layers: (geom-point(),),
    facet: facet-grid(rows: "side", columns: "grp", gutter: (
      x: 1.2cm,
      y: 0.1cm,
    )),
    width: 12cm,
    height: 5cm,
  ),
  plot(
    data: data,
    mapping: aes(x: "x", y: "y"),
    layers: (geom-point(),),
    facet: facet-wrap("grp", ncolumn: 3),
    theme: theme(panel-spacing: 1.4cm),
    width: 12cm,
    height: 4cm,
  ),
  compose(
    defer(plot, data: data, mapping: aes(x: "x", y: "y"), layers: (
      geom-point(),
    )),
    defer(plot, data: data, mapping: aes(x: "x", y: "y"), layers: (
      geom-line(),
    )),
    defer(plot, data: data, mapping: aes(x: "x", y: "y"), layers: (
      geom-point(),
    )),
    defer(plot, data: data, mapping: aes(x: "x", y: "y"), layers: (
      geom-line(),
    )),
    columns: 2,
    gutter: (x: 1.6cm, y: 0.2cm),
    width: 12cm,
    height: 6cm,
  ),
)
