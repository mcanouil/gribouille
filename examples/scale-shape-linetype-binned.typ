// Binned shape and linetype scales: continuous variable cut into n bins, each bin gets one
// shape (point geom) or one dash pattern (line geom).

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let pts = range(0, 12).map(i => (x: i, y: i, w: i + 1))

#let lined = ()
#for q in range(1, 7) {
  for x in range(0, 6) {
    lined.push((x: x, y: x + q * 0.3, q: q))
  }
}

#grid(
  columns: 1,
  row-gutter: 0.4cm,
  plot(
    data: pts,
    mapping: aes(x: "x", y: "y", shape: "w"),
    layers: (geom-point(size: 4pt),),
    scales: scales(shape: scale-binned(n-breaks: 4)),
    labels: labels(
      title: "scale-binned(n-breaks: 4)",
      x: "X",
      y: "Y",
      shape: "Bin",
    ),
    theme: theme-minimal(),
    width: 12cm,
    height: 9cm,
  ),
  plot(
    data: pts,
    mapping: aes(x: "x", y: "y", shape: "w"),
    layers: (geom-point(size: 4pt),),
    scales: scales(shape: scale-binned(n-breaks: 6,
        palette: ("circle", "square", "triangle", "diamond", "cross", "x"),)),
    labels: labels(
      title: "Scale-Shape-Binned with Custom Palette",
      x: "X",
      y: "Y",
      shape: "Bin",
    ),
    theme: theme-minimal(),
    width: 12cm,
    height: 9cm,
  ),
  plot(
    data: lined,
    mapping: aes(x: "x", y: "y", linetype: "q", group: "q"),
    layers: (geom-line(stroke: 1pt),),
    scales: scales(linetype: scale-binned(n-breaks: 3)),
    labels: labels(
      title: "scale-binned(n-breaks: 3)",
      x: "X",
      y: "Y",
      linetype: "Bin",
    ),
    theme: theme-minimal(),
    width: 12cm,
    height: 9cm,
  ),
)
