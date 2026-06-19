// Loads a daily-cumulative star count and release markers from CSV and plots
// them as a midnight-sky step trail: a luminous staircase whose daily counts
// read like a constellation, with the final spike glowing brightest.
// Regenerate the CSVs with: .github/star-history/star-history.sh
//                           .github/star-history/release-history.sh
// Compile with: typst compile .github/star-history/star-history.typ --root .

#import "../../lib.typ": *

#set page(width: 18cm, height: 18cm, margin: 0cm)

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
    // Each daily count is a star: a soft halo under a bright point.
    geom-point(
      data: d => d.filter(row => row.stars != 0),
      size: 8pt,
      fill: palette.star,
      stroke: none,
      alpha: 0.16,
    ),
    geom-point(
      data: d => d.filter(row => row.stars != 0),
      size: 4pt,
      fill: palette.star,
      stroke: 0.4pt,
      colour: palette.sky-deep,
    ),
    // The spike glows brightest: its own halo, then a hot amber star.
    geom-point(
      data: (peak,),
      size: 15pt,
      fill: palette.peak,
      stroke: none,
      alpha: 0.22,
    ),
    geom-point(
      data: (peak,),
      size: 7pt,
      fill: palette.peak,
      stroke: 0.5pt,
      colour: rgb("#fff3cf"),
    ),
    // Direct labels where the eye already rests, top-right. Each rides in a
    // moonlit cloud: a soft transparent-text bloom behind a crisp pill.
    annotate(
      "label",
      clip: false,
      x: to-days(peak.date) - 2,
      y: peak.stars,
      label: str(int(peak.stars)) + " ★",
      colour: rgb("#00000000"),
      fill: palette.cloud.transparentize(55%),
      stroke: none,
      size: 13pt,
      inset: 9pt,
      radius: 12pt,
      anchor: "east",
    ),
    annotate(
      "label",
      clip: false,
      x: to-days(peak.date) - 2,
      y: peak.stars,
      label: str(int(peak.stars)) + " ★",
      colour: rgb("#fff3cf"),
      fill: palette.cloud.transparentize(15%),
      stroke: 0.6pt + palette.cloud-edge.transparentize(30%),
      size: 13pt,
      inset: 5pt,
      radius: 10pt,
      anchor: "east",
    ),
    annotate(
      "label",
      clip: false,
      x: to-days(peak.date) - 2,
      y: peak.stars - 16,
      label: "+" + str(peak-jump) + " in a day",
      colour: rgb("#00000000"),
      fill: palette.cloud.transparentize(55%),
      stroke: none,
      size: 10pt,
      inset: 9pt,
      radius: 12pt,
      anchor: "east",
    ),
    annotate(
      "label",
      clip: false,
      x: to-days(peak.date) - 2,
      y: peak.stars - 16,
      label: "+" + str(peak-jump) + " in a day",
      colour: palette.peak,
      fill: palette.cloud.transparentize(15%),
      stroke: 0.6pt + palette.cloud-edge.transparentize(30%),
      size: 10pt,
      inset: 5pt,
      radius: 10pt,
      anchor: "east",
    ),
    // Narrative beats: the private build over the flat run, and the public day.
    annotate(
      "label",
      clip: false,
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
      clip: false,
      x: to-days("2026-05-17"),
      y: 37.5,
      label: [Made public \ 17th of May],
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
      date-format: "[month repr:short] [year]",
      expand: (0%, auto),
    ),
    scale-y-continuous(breaks: y-breaks, expand: (0%, 10%)),
    // Annotations carry literal colours through the colour/fill aesthetics, so
    // keep those scales identity rather than remapping to a palette.
    scale-colour-identity(),
    scale-fill-identity(),
  ),
  coord: coord-cartesian(clip: "off"),
  labels: labels(
    title: [#text(fill: palette.trail)[Gribouille]'s first #text(fill: palette.peak)[#str(int(peak.stars))] GitHub stars],
    subtitle: [
      #set par(justify: true)
      Gribouille brings the #text(fill: palette.ink)[grammar of graphics], the idea behind ggplot2 and plotnine, to Typst: layered geoms, scales, and themes for publication-quality charts written in pure markup. Built quietly in private through April, it went #text(fill: palette.star)[public on 17 May 2026] and shipped v0.1.0 three days later. Each release drew a bigger crowd, and a single day in June carried it past #text(fill: palette.peak)[#str(int(peak.stars)) stars].
    ],
    x: none,
    y: "Stars",
    caption: [
      This very chart was drawn with Gribouille. \
      Author: #link("https://mickael.canouil.fr")[mickael.canouil.fr] | Data source: GitHub API
    ],
  ),
  theme: theme-minimal(
    ink: palette.ink,
    paper: palette.sky-deep,
    text: element-text(font: ("Libertinus Serif", "DejaVu Sans Mono")),
    tick-length: 0.12cm,
    panel-background: element-rect(fill: gradient.linear(
      rgb("#0a1330"),
      rgb("#1c2f5e"),
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
      size: 30pt,
      weight: "regular",
      margin: margin(top: 6pt, bottom: 14pt),
    ),
    plot-subtitle: element-text(
      colour: palette.muted,
      size: 14pt,
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
