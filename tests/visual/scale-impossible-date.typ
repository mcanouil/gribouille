// An impossible ISO date drops its row, as other unusable cells do.
//
// The data holds five points on a date axis. The dates "2020-02-30" and
// "2021-02-29" do not exist, so those rows drop and three points draw:
// 2020-01-15, 2020-02-29 (a leap day), and 2020-04-15. Before the fix,
// "2020-02-30" raised the Typst error `date is invalid`.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#plot(
  data: (
    (d: "2020-01-15", y: 1),
    (d: "2020-02-29", y: 2),
    (d: "2020-02-30", y: 3),
    (d: "2020-04-15", y: 4),
    (d: "2021-02-29", y: 5),
  ),
  mapping: aes(x: "d", y: "y"),
  layers: (geom-point(size: 4pt),),
  scales: scales(x: scale-date(), y: scale-continuous(limits: (0, 6))),
  width: 8cm,
  height: 5cm,
)
