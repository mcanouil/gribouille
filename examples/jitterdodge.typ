// position-jitterdodge: dodge groups apart, then jitter within each group.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let trial = ()
#for arm in ("placebo", "low", "high") {
  for week in (1, 2, 3, 4) {
    for i in range(0, 12) {
      let drift = if arm == "high" { 0.6 } else if arm == "low" { 0.3 } else {
        0.0
      }
      let baseline = 4.0 + drift * week + 0.05 * (i - 6)
      trial.push((
        week: week,
        response: baseline + calc.sin(i * 0.7) * 0.3,
        arm: arm,
      ))
    }
  }
}

#plot(
  data: trial,
  mapping: aes(x: "week", y: "response", colour: "arm"),
  layers: (
    geom-jitter(
      size: 2pt,
      alpha: 0.85,
      position: position-jitterdodge(width: 0.12, dodge-width: 0.6),
    ),
  ),
  scales: (
    scale-x-continuous(breaks: (1, 2, 3, 4)),
    scale-colour-brewer(palette: "Dark2"),
  ),
  labels: labels(
    title: "Dose-Response Trial Across Four Weeks",
    subtitle: "Each dose arm is dodged off the week, then jittered within its column",
    x: "Week",
    y: "Response Score",
    colour: "Arm",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
