// Inline aesthetic coercion: as-factor("col") / as-numeric("col") return
// mapping-ref annotations; train() honours them to override inferred types.

#import "../../src/data.typ": as-factor, as-numeric
#import "../../src/scale/train.typ": train, mapping-ref-col, mapping-ref-type
#import "../../src/geom/point.typ": geom-point
#import "../../src/aes.typ": aes

// One-arg form returns an annotation dict.
#let a = as-factor("cluster")
#assert.eq(a.kind, "mapping-ref")
#assert.eq(a.var, "cluster")
#assert.eq(a.type, "discrete")

#let n = as-numeric("cluster")
#assert.eq(n.type, "continuous")

// Two-arg form still works on data.
#let df = (
  (cluster: "1", y: "10"),
  (cluster: "2", y: "20"),
  (cluster: "1", y: "30"),
)
#let numeric = as-numeric(df, "y")
#assert.eq(numeric.at(0).y, 10.0)

// Helpers recognise annotations.
#assert.eq(mapping-ref-col(a), "cluster")
#assert.eq(mapping-ref-type(a), "discrete")
#assert.eq(mapping-ref-col("plain"), "plain")
#assert.eq(mapping-ref-type("plain"), none)

// Training respects forced type: cluster inferred as continuous becomes
// discrete when annotated.
#let layers = (geom-point(),)
#let trained = train(
  layers: layers,
  mapping: aes(x: "y", colour: as-factor("cluster")),
  data: df,
)
#assert.eq(trained.colour.type, "discrete")
#assert.eq(trained.colour.domain, ("1", "2"))

Annotation tests passed.
