// Loads a daily-cumulative star count and release markers from CSV and plots
// them as a midnight-sky step trail: a luminous staircase whose daily counts
// read like a constellation, with the final spike glowing brightest.
// Regenerate the CSVs with: .github/star-history/star-history.sh
//                           .github/star-history/release-history.sh
// Compile with: typst compile .github/star-history/star-history.typ --root .

#import "../../lib.typ": *

#set page(width: 16cm, height: 18cm, margin: 0cm)
// #set page("a4", margin: 2.5cm)

// Named palette: colours reused across several layers. One-off shades (the panel
// gradient, point rim, release tint, transparent bloom ink) stay inline at use.
#let palette = (
  sky-deep: rgb("#0a132e"), // plot margin: a shade darker, to gather the figure
  trail: rgb("#f4d58d"), // cumulative curve: luminous starlight gold
  star: rgb("#ffe7a3"), // daily-count points: bright warm star
  peak: rgb("#ff8c42"), // the spike: hotter amber, separates from the gold
  ink: rgb("#e8ecf5"), // foreground text: soft starlight white
  muted: rgb("#9aa6c4"), // secondary text and ticks
  cloud: rgb("#28406f"), // annotation boxes: moonlit cloud, lighter than the sky
  cloud-edge: rgb("#6b7cb0"), // faint rim catching the moonlight
)

#let raw-stars = csv("star-history.csv", row-type: dictionary).map(row => (
  date: row.date,
  stars: float(row.stars),
))

// Snap the leading 0-star baseline to the first of the creation month so the
// flat segment starts on the first month tick rather than mid-month.
#let stars = (
  (..raw-stars.first(), date: raw-stars.first().date.slice(0, 7) + "-01"),
  ..raw-stars.slice(1),
)

// geom-vline draws from raw `xintercept` values, so release dates are converted
// to numeric days since the 2000-01-01 epoch that scale-x-date trains against.
#let epoch = datetime(year: 2000, month: 1, day: 1)
#let to-days(iso) = (
  datetime(
    year: int(iso.slice(0, 4)),
    month: int(iso.slice(5, 7)),
    day: int(iso.slice(8, 10)),
  )
    - epoch
).days()

#let star-max = stars.map(row => row.stars).fold(0, calc.max)

// One releases dataset (minor/major only, patch dropped): x in epoch days, y just
// above the x-axis baseline so the tiny tags sit clear of the trail and the peak.
#let releases = (
  csv("release-history.csv", row-type: dictionary)
    .filter(row => row.tag.split(".").last() == "0")
    .map(row => (
      x: to-days(row.date),
      y: 6,
      tag: "v" + row.tag,
    ))
)

// The final row carries the spike; it drives the peak marker and its labels.
#let peak = stars.last()
#let peak-jump = int(peak.stars - stars.at(-2).stars)

// Shooting-star fan: one solid gold band tapering from a point at the first date
// (the tail tip) up to the star at the head, where it spans the star's height.
// Both edges are arcs sharing the tip; the top edge meets the star's top point and
// the lower edge its lower-left peak.
#let head-x = to-days(peak.date)
#let head-y = peak.stars
#let tail-x = to-days(stars.first().date) // first date: where the tail tip lands
#let fan-sag = 30 // stars the edges drop from the head down to the tip
#let fan-arc = 1.7 // >1 keeps the edges flat at the head, steep toward the tip
#let head-top = head-y + 2.5 // top edge meets the star's top point
#let head-bot = head-y - 3.5 // lower edge meets the star's lower-left peak
#let tip-y = head-y - 115 // y of the tail tip at the first date
// An arc through (tail-x, tip-y) at the tip and (head-x, hy) at the head.
#let arc-y(x, hy) = {
  let t = (x - tail-x) / (head-x - tail-x)
  hy - fan-sag * calc.pow(1 - t, fan-arc) + (tip-y - hy + fan-sag) * (1 - t)
}
#let fan-band(n) = range(n + 1).map(i => {
  let x = tail-x + (head-x - tail-x) * i / n
  (x: x, ymax: arc-y(x, head-top), ymin: arc-y(x, head-bot))
})

// A cross-thickness gradient cannot ride a single ribbon (a Typst gradient maps to
// the whole bounding box, not the band's local thickness), so the fan is sliced
// into thin sub-bands stacked from the lower to the upper edge, each filled by
// sampling a light -> peak -> light gradient: the amber peak colour runs as a
// bright line down the middle and lightens toward both edges.
#let fan-slices = 32
#let fan-grad = gradient.linear(
  palette.star.transparentize(50%),
  palette.peak.transparentize(50%),
  palette.star.transparentize(50%),
)
#let fan-layers = {
  let rows = fan-band(40)
  range(fan-slices).map(k => {
    let flo = k / fan-slices
    let fhi = (k + 1) / fan-slices
    geom-ribbon(
      data: rows.map(r => (
        x: r.x,
        ymin: r.ymin + (r.ymax - r.ymin) * flo,
        ymax: r.ymin + (r.ymax - r.ymin) * fhi,
      )),
      mapping: aes(x: "x", ymin: "ymin", ymax: "ymax"),
      inherit-aes: false,
      fill: fan-grad.sample((flo + fhi) / 2 * 100%),
      stroke: none,
      alpha: 0.95,
    )
  })
}

#let y-step = 25
#let y-breaks = range(0, calc.floor(star-max / y-step) + 1).map(i => i * y-step)

// One x break per month (first of the month) so the short-month label never
// repeats, unlike the auto breaks that fall mid-month within a single month.
#let month-firsts = (
  stars.map(row => row.date.slice(0, 7) + "-01").dedup().map(to-days)
)

#plot(
  data: stars,
  mapping: aes(x: "date", y: "stars"),
  layers: (
    // Faint luminous glow beneath the trail.
    geom-area(
      stat: "identity",
      fill: palette.trail,
      alpha: 0.1,
      stroke: none,
    ),
    // Releases recede into the sky: thin dashed verticals plus tiny tags set in
    // the empty upper-left, so the trail stays the hero.
    geom-vline(
      data: releases,
      mapping: aes(xintercept: "x"),
      colour: rgb("#6677aa"),
      stroke: 0.4pt,
      linetype: "dashed",
      alpha: 0.45,
    ),
    geom-label(
      data: releases,
      mapping: aes(x: "x", y: "y", label: "tag"),
      inherit-aes: false,
      colour: palette.muted,
      fill: palette.cloud.transparentize(35%),
      stroke: 0.25pt,
      size: 7pt,
      inset: 3pt,
      radius: 5pt,
      anchor: "west",
    ),
    // The day the repository went public: a warm gold marker, distinct from the
    // cool release lines.
    annotate(
      "vline",
      xintercept: to-days("2026-05-17"),
      colour: palette.star,
      stroke: 0.5pt,
      linetype: "dashed",
      alpha: 0.4,
    ),
    // The cumulative trail.
    geom-step(stroke: 1.4pt, colour: palette.trail),
    // Each daily count is a star glyph: a soft halo under a bright sparkle. The
    // glyph's optical centre sits low, so the larger glow is lifted to stay
    // concentric with the bright star (geom-point has no nudge).
    geom-point(
      data: d => d
        .filter(row => row.stars != 0)
        .map(row => (
          ..row,
          stars: row.stars + 0.25,
        )),
      shape: sym.star,
      size: 24pt,
      fill: palette.star,
      alpha: 0.16,
    ),
    geom-point(
      data: d => d.filter(row => row.stars != 0),
      shape: sym.star,
      size: 14pt,
      fill: palette.star,
    ),
    // Shooting-star fan sweeping down-left from behind the head: sliced sub-bands
    // give it an amber centre-line lightening to the edges; drawn before the peak
    // star so the amber head sits over its apex.
    ..fan-layers,
    // The spike glows brightest: its own (lifted) halo, then a hot amber star.
    geom-point(
      data: ((..peak, stars: peak.stars + 1.25),),
      shape: sym.star,
      size: 46pt,
      fill: palette.peak,
      alpha: 0.22,
    ),
    geom-point(
      data: ((..peak, stars: peak.stars + 0.25),),
      shape: sym.star,
      size: 26pt,
      fill: palette.peak,
    ),
    // The count floats in clear sky just above the head, clear of the gold fan.
    annotate(
      "typst",
      x: head-x,
      y: head-y + 10,
      label: [#str(int(peak.stars))],
      colour: rgb("#fff3cf"),
      size: 13pt,
      anchor: "south",
    ),
    annotate(
      "typst",
      x: head-x - 3.5,
      y: 125,
      label: [+#str(peak-jump) in a day],
      colour: palette.peak,
      size: 13pt,
      anchor: "east",
    ),
    // Narrative beats: the private build over the flat run, and the public day.
    annotate(
      "label",
      x: to-days("2026-04-20"),
      y: 12.5,
      label: "Quietly built in private",
      colour: palette.ink,
      fill: palette.cloud.transparentize(20%),
      stroke: 0.6pt + palette.cloud-edge.transparentize(30%),
      size: 12pt,
      inset: 6pt,
      radius: 10pt,
    ),
    annotate(
      "label",
      x: to-days("2026-05-17"),
      y: 37.5,
      label: [#align(center)[Made public \ 17#super[th] of May]],
      colour: palette.star,
      fill: palette.cloud.transparentize(20%),
      stroke: 0.6pt + palette.cloud-edge.transparentize(30%),
      size: 10pt,
      inset: 5pt,
      radius: 10pt,
      anchor: "east",
    ),
  ),
  scales: (
    scale-x-date(
      breaks: month-firsts,
      date-format: "[month repr:long] [year]",
      expand: (0%, auto),
    ),
    scale-y-continuous(
      breaks: y-breaks,
      labels: y => [#box(baseline: -0.4em)[#str(int(y))]#text(size: 2em)[#sym.star]],
      expand: (0%, 6%)
    ),
  ),
  labels: labels(
    title: [
      #set par(justify: true)
      #text(fill: palette.trail, weight: "bold")[Gribouille]'s First #text(fill: palette.peak, weight: "bold")[#str(int(peak.stars))] GitHub Stars#linebreak(justify: true)
    ],
    subtitle: [
      #set par(justify: true)
      Gribouille brings the #text(fill: palette.ink)[grammar of graphics], the idea behind `ggplot2` and `plotnine`, to Typst: layered geoms, scales, and themes for publication-quality charts written in pure markup. Built quietly in private through April, it went #text(fill: palette.star)[public on 17#super[th] May 2026] and shipped #box(
        fill: palette.cloud.transparentize(35%),
        stroke: 0.25pt + palette.cloud-edge.transparentize(30%),
        inset: (x: 3pt, y: 1pt),
        outset: (y: 1pt),
        radius: 4pt,
      )[#text(size: 0.82em, fill: palette.muted)[v0.1.0]] three days later. Each release drew a bigger crowd, and a single day in June carried it past #text(fill: palette.peak)[#str(int(peak.stars)) stars].
    ],
    x: none,
    y: none,
    caption: [
      This very chart was drawn with Gribouille (#link("https://m.canouil.dev/gribouille")[m.canouil.dev/gribouille]). \
      Author: #link("https://mickael.canouil.fr")[mickael.canouil.fr] | Data source: GitHub API
    ],
  ),
  theme: theme-minimal(
    ink: palette.ink,
    paper: palette.sky-deep,
    text: element-text(font: ("Libertinus Serif", "DejaVu Sans Mono")),
    tick-length: 0.12cm,
    panel-background: element-rect(fill: gradient.linear(
      // Hold the dark top longer so it blends into the sky-deep frame, then
      // lighten only toward the lower half of the panel.
      (rgb("#0a1330"), 0%),
      (rgb("#0a1330"), 45%),
      (rgb("#1c2f5e"), 100%),
      dir: ttb,
    )),
    panel-grid-major-x: element-blank(),
    panel-grid-minor: element-blank(),
    panel-grid-major-y: element-line(colour: palette.ink.transparentize(88%)),
    axis-ticks: element-line(colour: palette.muted),
    axis-text: element-text(colour: palette.muted, size: 10pt),
    axis-title: element-text(colour: palette.ink, size: 12pt),
    axis-title-y: element-text(margin: margin(right: 14pt)),
    plot-title: element-text(
      font: "Didot",
      colour: palette.ink,
      size: 25.5pt,
      weight: "regular",
      margin: margin(top: 6pt, bottom: 20pt),
    ),
    plot-subtitle: element-text(
      colour: palette.muted,
      size: 13.3pt,
      margin: margin(bottom: 24pt),
    ),
    plot-caption: element-text(
      colour: palette.muted,
      size: 9.5pt,
      margin: margin(top: 16pt),
    ),
    // Outer frame: pad the whole figure so it breathes inside the page.
    plot-background: element-rect(
      fill: palette.sky-deep,
      inset: margin(top: 22pt, right: 26pt, bottom: 18pt, left: 22pt),
    ),
  ),
  width: auto,
  height: auto,
)
