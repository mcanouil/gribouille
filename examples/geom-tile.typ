// geom-tile: heatmap of x/y/fill.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let weeks = ("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
#let hours = ("06", "09", "12", "15", "18", "21")

#let traffic = ()
#for (i, day) in weeks.enumerate() {
  for (j, hour) in hours.enumerate() {
    let weekend = day == "Sat" or day == "Sun"
    let peak = if weekend { 60 } else { 100 }
    let request-count = (
      peak * (1.0 - calc.abs(j - 2.5) / 5.0) + calc.rem(i * 7 + j * 3, 17)
    )
    traffic.push((day: day, hour: hour, requests: request-count))
  }
}

#plot(
  data: traffic,
  mapping: aes(x: "hour", y: "day", fill: "requests"),
  layers: (geom-tile(stroke: 0.5pt, colour: rgb("#ffffff")),),
  scales: scales(fill: scale-viridis-c(name: "Requests / min"), x: scale-discrete(limits: hours), y: scale-discrete(limits: weeks.rev())),
  labels: labels(
    title: "Hourly Request Volume by Day",
    subtitle: "Peak load lands midday on weekdays",
    x: "Hour of Day",
    y: "Day",
  ),
  theme: theme-minimal(),
  width: 12cm,
  height: 9cm,
)
