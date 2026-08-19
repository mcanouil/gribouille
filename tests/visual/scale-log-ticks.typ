// Smoke render: the log axis slice. Read each panel for what the unit tests
// cannot assert: the three tick tiers step down in length from the decade to
// the half decade to the rest, `format-log` labels read as powers with real
// superscripts, and a narrow panel still fits those taller labels.

#import "../../lib.typ": *

#let d = (
  (x: 1, y: 3),
  (x: 2, y: 12),
  (x: 3, y: 60),
  (x: 4, y: 250),
  (x: 5, y: 900),
  (x: 6, y: 4000),
  (x: 7, y: 20000),
)

#let panel(title, y-scale, width: 9cm, theme: theme-grey()) = plot(
  data: d,
  mapping: aes(x: "x", y: "y"),
  layers: (geom-point(size: 3pt),),
  scales: scales(y: y-scale),
  guides: guides(y: guide-axis-logticks()),
  labels: labels(title: title),
  theme: theme,
  width: width,
  height: 6cm,
)

#panel("Three tick tiers, automatic breaks", scale-log10())

#panel(
  "breaks-log and format-log together",
  scale-log10(breaks: breaks-log(), labels: format-log()),
)

#panel(
  "Mid tier lengthened past the major",
  scale-log10(labels: format-log()),
  theme: theme-grey(axis-ticks-mid: element-tick(length: 200%)),
)

#panel(
  "Superscript labels in a narrow panel",
  scale-log10(labels: format-log()),
  width: 5cm,
)
