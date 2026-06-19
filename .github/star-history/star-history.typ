// Loads a daily-cumulative star count and release markers from CSV and plots
// them as a step line with dashed release lines.
// Regenerate the CSVs with: .github/star-history/star-history.sh
//                           .github/star-history/release-history.sh
// Compile with: typst compile .github/star-history/star-history.typ --root .

#import "../../lib.typ": *

#set page(width: 18cm, height: 9.45cm, margin: 0cm)

// Glyph markers (e.g. sym.star) render in the ambient document font, which the
// theme cannot reach, so a Unicode-covering fallback is set at document level.
#set text(font: ("Libertinus Serif", "DejaVu Sans Mono"))

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
#let release-colour = rgb("#d62728")

// One releases dataset (minor/major only, patch dropped): x in epoch days, y at
// the label height, tag text. Drives both the dashed lines and the labels.
#let releases = (
  csv("release-history.csv", row-type: dictionary)
    .filter(row => row.tag.split(".").last() == "0")
    .map(row => (
      x: to-days(row.date),
      y: star-max,
      tag: row.tag,
    ))
)

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
    geom-vline(
      xintercept: releases.map(row => row.x),
      colour: release-colour,
      stroke: 0.6pt,
      linetype: "dashed",
      alpha: 0.6,
    ),
    geom-label(
      data: releases,
      mapping: aes(x: "x", y: "y", label: "tag"),
      inherit-aes: false,
      colour: release-colour,
      fill: white,
      size: 8pt,
      anchor: "south",
    ),
    geom-step(stroke: 1.2pt, colour: rgb("#1f77b4")),
    geom-point(size: 2pt, fill: rgb("#1f77b4"), shape: sym.star),
  ),
  scales: (
    scale-x-date(
      breaks: month-firsts,
      date-format: "[month repr:short] [year]",
    ),
    scale-y-continuous(breaks: y-breaks, expand: (0%, 5%)),
  ),
  labs: labs(
    title: "Gribouille GitHub Stars",
    subtitle: "Cumulative stargazers over time",
    x: "Date",
    y: "Stars",
    caption: [Author: #link("https://mickael.canouil.fr")[mickael.canouil.fr] | Data source: GitHub API],
  ),
  theme: theme-minimal(
    axis-ticks-y: element-blank(),
    tick-length: 0.15cm,
  ),
  width: auto,
  height: auto,
)
