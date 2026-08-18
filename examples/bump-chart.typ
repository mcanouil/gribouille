// bump-chart: rank trajectories eased through sigmoid connectors.

#import "../lib.typ": *

#set page(width: auto, height: auto, margin: 0cm)

#let ranks = (
  Alpha: (1, 1, 2, 3, 2, 1),
  Boreal: (2, 3, 1, 1, 1, 2),
  Cirrus: (3, 2, 4, 2, 3, 4),
  Delta: (4, 4, 3, 4, 4, 3),
)

#let standings = ()
#for (team, rs) in ranks {
  for (i, r) in rs.enumerate() {
    standings.push((round: i + 1, rank: r, team: team))
  }
}

#plot(
  data: standings,
  mapping: aes(x: "round", y: "rank", colour: "team", fill: "team"),
  layers: (
    geom-line(stat: stat-connect(connection: "sigmoid"), stroke: 2pt),
    geom-point(size: 4pt,),
  ),
  scales: scales(
    x: scale-continuous(breaks: (1, 2, 3, 4, 5, 6)),
    y: scale-continuous(transform: "reverse", breaks: (1, 2, 3, 4)),
    colour: scale-okabe-ito(name: "Team"),
    fill: scale-okabe-ito(name: "Team"),
  ),
  labels: labels(
    title: "Season Standings",
    subtitle: "Sigmoid connectors ease each team between ranks, rank 1 on top",
    x: "Round",
    y: "Rank",
  ),
  theme: theme-minimal(),
  width: 13cm,
  height: 7cm,
)
