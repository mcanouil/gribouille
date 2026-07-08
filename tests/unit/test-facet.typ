// facet-wrap free-scales validation and dict shape.
//
// Rejection contract: any value of `scales` outside the four below must
// panic with "facet-wrap: scales must be ...". Typst unit tests cannot
// catch panics in-process, so the panic path is verified manually whenever
// the allowed set or the message changes. Same applies to `axes`.

#import "../../src/facet/wrap.typ": facet-wrap

// --- accepted scales values produce a facet dict carrying the policy ---

#let f-fixed = facet-wrap("g")
#assert.eq(f-fixed.scales, "fixed")
#assert.eq(f-fixed.name, "wrap")
#assert.eq(f-fixed.variable, "g")

#let f-free = facet-wrap("g", scales: "free")
#assert.eq(f-free.scales, "free")

#let f-free-x = facet-wrap("g", scales: "free_x")
#assert.eq(f-free-x.scales, "free_x")

#let f-free-y = facet-wrap("g", scales: "free_y")
#assert.eq(f-free-y.scales, "free_y")

// --- accepted axes values produce a facet dict carrying the policy ---

#assert.eq(f-fixed.axes, "margins")

#let f-axes-all = facet-wrap("g", axes: "all")
#assert.eq(f-axes-all.axes, "all")

#let f-axes-x = facet-wrap("g", axes: "all_x")
#assert.eq(f-axes-x.axes, "all_x")

#let f-axes-y = facet-wrap("g", axes: "all_y")
#assert.eq(f-axes-y.axes, "all_y")

facet-wrap free-scales tests passed.
