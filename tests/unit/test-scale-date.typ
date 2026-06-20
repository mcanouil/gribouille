// Date / datetime / time scale wrappers carry temporal metadata into the
// trained dict and otherwise behave like a continuous scale.

#import "../../src/scale/date.typ": (
  scale-x-date, scale-x-datetime, scale-x-time, scale-y-date, scale-y-datetime,
  scale-y-time,
)
#import "../../src/scale/train.typ": train

// --- spec dicts carry kind, aesthetic, temporal, and date-format ---

#let xs-date = scale-x-date()
#assert.eq(xs-date.kind, "scale")
#assert.eq(xs-date.aesthetic, "x")
#assert.eq(xs-date.type, "continuous")
#assert.eq(xs-date.temporal, "date")
#assert.eq(xs-date.at("date-format"), "[year]-[month repr:numerical]-[day]")

#let ys-date = scale-y-date(date-format: "[year]")
#assert.eq(ys-date.aesthetic, "y")
#assert.eq(ys-date.temporal, "date")
#assert.eq(ys-date.at("date-format"), "[year]")

#let xs-dt = scale-x-datetime()
#assert.eq(xs-dt.aesthetic, "x")
#assert.eq(xs-dt.temporal, "datetime")
#assert.eq(
  xs-dt.at("date-format"),
  "[year]-[month repr:numerical]-[day] [hour]:[minute]",
)

#let ys-dt = scale-y-datetime()
#assert.eq(ys-dt.aesthetic, "y")
#assert.eq(ys-dt.temporal, "datetime")

#let xs-time = scale-x-time()
#assert.eq(xs-time.aesthetic, "x")
#assert.eq(xs-time.temporal, "time")
#assert.eq(xs-time.at("date-format"), "[hour]:[minute]")

#let ys-time = scale-y-time()
#assert.eq(ys-time.aesthetic, "y")
#assert.eq(ys-time.temporal, "time")

// --- training propagates temporal metadata onto the trained axis ---

#let d = (
  (x: 8766, y: 1),
  (x: 8796, y: 2),
  (x: 8826, y: 3),
)

#let layers = (
  (
    geom: "point",
    mapping: (x: "x", y: "y"),
    data: none,
    inherit-aes: true,
    stat: "identity",
    position: "identity",
    params: (:),
  ),
)

#let trained = train(
  scales: (scale-x-date(),),
  layers: layers,
  mapping: (x: "x", y: "y"),
  data: d,
)
#assert.eq(trained.x.type, "continuous")
#assert.eq(trained.x.temporal, "date")
#assert.eq(trained.x.at("date-format"), "[year]-[month repr:numerical]-[day]")
#assert.eq(trained.x.domain, (8766, 8826))

#let trained-dt = train(
  scales: (scale-y-datetime(date-format: "[hour]:[minute]"),),
  layers: (
    (
      geom: "point",
      mapping: (x: "x", y: "y"),
      data: none,
      inherit-aes: true,
      stat: "identity",
      position: "identity",
      params: (:),
    ),
  ),
  mapping: (x: "x", y: "y"),
  data: ((x: 1, y: 0), (x: 2, y: 3600), (x: 3, y: 7200)),
)
#assert.eq(trained-dt.y.temporal, "datetime")
#assert.eq(trained-dt.y.at("date-format"), "[hour]:[minute]")

// --- ISO-8601 date-string limits clip to the same numeric days the column
// trains against; an `auto` side keeps the trained bound ---

#import "../../src/utils/types.typ": parse-temporal

#let date-rows = (
  (x: "2024-03-01", y: 1),
  (x: "2024-09-01", y: 2),
)
#let lim-layers = (
  (
    geom: "point",
    mapping: (x: "x", y: "y"),
    data: none,
    inherit-aes: true,
    stat: "identity",
    position: "identity",
    params: (:),
  ),
)
#let trained-iso-lim = train(
  scales: (scale-x-date(limits: ("2024-01-01", "2024-12-31")),),
  layers: lim-layers,
  mapping: (x: "x", y: "y"),
  data: date-rows,
)
#assert.eq(
  trained-iso-lim.x.domain,
  (parse-temporal("2024-01-01", "date"), parse-temporal("2024-12-31", "date")),
)

// `auto` on the high side keeps the trained max (parsed from the data).
#let trained-iso-auto = train(
  scales: (scale-x-date(limits: ("2024-01-01", auto)),),
  layers: lim-layers,
  mapping: (x: "x", y: "y"),
  data: date-rows,
)
#assert.eq(
  trained-iso-auto.x.domain.at(0),
  parse-temporal("2024-01-01", "date"),
)
#assert.eq(
  trained-iso-auto.x.domain.at(1),
  parse-temporal("2024-09-01", "date"),
)

Scale date tests passed.
