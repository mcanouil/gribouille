// Histogram: continuous x binned via stat-bin.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#let samples = (
  (value: 4.2),
  (value: 4.8),
  (value: 5.1),
  (value: 5.3),
  (value: 5.4),
  (value: 5.6),
  (value: 5.7),
  (value: 5.9),
  (value: 6.0),
  (value: 6.0),
  (value: 6.1),
  (value: 6.2),
  (value: 6.2),
  (value: 6.3),
  (value: 6.3),
  (value: 6.4),
  (value: 6.5),
  (value: 6.5),
  (value: 6.6),
  (value: 6.7),
  (value: 6.7),
  (value: 6.8),
  (value: 6.8),
  (value: 6.9),
  (value: 7.0),
  (value: 7.1),
  (value: 7.3),
  (value: 7.5),
  (value: 7.8),
  (value: 8.2),
  (value: 8.6),
)

#plot(
  data: samples,
  mapping: aes(x: "value"),
  layers: (
    geom-histogram(bins: 12),
  ),
  scales: (
    scale-x-continuous(name: "Value", limits: (0, 10)),
    scale-y-continuous(name: "Count"),
  ),
  width: 10cm,
  height: 7cm,
)
