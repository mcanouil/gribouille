// Default theme values consumed by the renderer.
// User themes override individual fields; missing fields fall back here.

#let default-theme = (
  kind: "theme",
  name: "grey",
  panel-fill: rgb("#f2f2f2"),
  grid-colour: white,
  grid-thickness: 0.5pt,
  axis-colour: black,
  axis-thickness: 0.5pt,
  tick-length: 0.1,
  tick-labels: true,
  axis-text-size: 8pt,
  axis-title-size: 9pt,
  legend-text-size: 8pt,
  legend-title-size: 8pt,
)

#let merge-theme(user) = {
  if user == none { return default-theme }
  let merged = default-theme
  for (k, v) in user.pairs() {
    merged.insert(k, v)
  }
  merged
}
