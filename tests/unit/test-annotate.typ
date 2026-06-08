// annotate(geom, ..fields) builds a one-row layer with an aesthetic mapping
// pointing each kwarg name at the matching column, and inherit-aes: false.

#import "../../src/annotate.typ": annotate

// Text annotation: x, y, label all become aesthetics with matching columns.
#let lt = annotate("text", x: 1, y: 2, label: "hi")
#assert.eq(lt.kind, "layer")
#assert.eq(lt.geom, "text")
#assert.eq(lt.inherit-aes, false)
#assert.eq(lt.data, ((x: 1, y: 2, label: "hi"),))
#assert.eq(lt.mapping.kind, "aes")
#assert.eq(lt.mapping.x, "x")
#assert.eq(lt.mapping.y, "y")
#assert.eq(lt.mapping.label, "label")
#assert.eq(lt.mapping.colour, none)

// Layer parameters (non-aesthetic kwargs) are forwarded to the geom.
#let lt2 = annotate("text", x: 0, y: 0, label: "x", anchor: "west", dy: 0.3)
#assert.eq(lt2.params.anchor, "west")
#assert.eq(lt2.params.dy, 0.3)

// Aesthetic kwargs that the geom also accepts as a fixed param (e.g., colour
// on geom-text) still go into the mapping/data, not the params dict.
#let lt3 = annotate("text", x: 1, y: 1, label: "lab", colour: red)
#assert.eq(lt3.data, ((x: 1, y: 1, label: "lab", colour: red),))
#assert.eq(lt3.mapping.colour, "colour")

// `size` on text is a Typst length controlling the layer's text size, not an
// aesthetic; it must reach params and stay out of the mapping.
#let lt-size = annotate("text", x: 1, y: 2, label: "hi", size: 12pt)
#assert.eq(lt-size.params.size, 12pt)
#assert.eq(lt-size.mapping.at("size", default: none), none)
#assert.eq(lt-size.data, ((x: 1, y: 2, label: "hi"),))

// Same routing for `geom-label`.
#let ll-size = annotate("label", x: 0, y: 0, label: "boxed", size: 9pt)
#assert.eq(ll-size.params.size, 9pt)
#assert.eq(ll-size.mapping.at("size", default: none), none)

// `size` on `geom-point` stays an aesthetic mapping (default behaviour).
#let lp-size = annotate("point", x: 3, y: 4, size: 5)
#assert.eq(lp-size.mapping.size, "size")
#assert.eq(lp-size.data, ((x: 3, y: 4, size: 5),))

// Point annotation: only x, y -> no label column needed.
#let lp = annotate("point", x: 3, y: 4)
#assert.eq(lp.geom, "point")
#assert.eq(lp.data, ((x: 3, y: 4),))
#assert.eq(lp.mapping.x, "x")
#assert.eq(lp.mapping.y, "y")
#assert.eq(lp.mapping.label, none)
#assert.eq(lp.inherit-aes, false)

// Label annotation: same shape as text, dispatches to geom-label.
#let ll = annotate("label", x: 0, y: 0, label: "boxed")
#assert.eq(ll.geom, "label")
#assert.eq(ll.mapping.label, "label")

// Segment annotation: xend / yend are aesthetics.
#let ls = annotate("segment", x: 0, y: 0, xend: 1, yend: 1)
#assert.eq(ls.geom, "segment")
#assert.eq(ls.data, ((x: 0, y: 0, xend: 1, yend: 1),))
#assert.eq(ls.mapping.xend, "xend")
#assert.eq(ls.mapping.yend, "yend")

// Rect annotation: xmin / xmax / ymin / ymax are aesthetics.
#let lr = annotate("rect", xmin: 0, xmax: 1, ymin: 0, ymax: 1, fill: blue)
#assert.eq(lr.geom, "rect")
#assert.eq(lr.mapping.xmin, "xmin")
#assert.eq(lr.mapping.xmax, "xmax")
#assert.eq(lr.mapping.ymin, "ymin")
#assert.eq(lr.mapping.ymax, "ymax")
#assert.eq(lr.mapping.fill, "fill")

// Vline annotation: xintercept is a layer parameter, not an aesthetic.
#let lv = annotate("vline", xintercept: 5, colour: red)
#assert.eq(lv.geom, "vline")
#assert.eq(lv.params.xintercept, 5)
#assert.eq(lv.params.colour, red)
#assert.eq(lv.data, none)
#assert.eq(lv.mapping, none)
#assert.eq(lv.inherit-aes, false)

// Hline annotation: yintercept is a layer parameter.
#let lh = annotate("hline", yintercept: 3)
#assert.eq(lh.geom, "hline")
#assert.eq(lh.params.yintercept, 3)
#assert.eq(lh.data, none)
#assert.eq(lh.mapping, none)

// Abline annotation: slope and intercept are routed to layer params so the
// geom can read them, even though they appear in the aesthetic key list.
#let la = annotate("abline", slope: 2, intercept: 1)
#assert.eq(la.geom, "abline")
#assert.eq(la.params.slope, 2)
#assert.eq(la.params.intercept, 1)
#assert.eq(la.data, none)
#assert.eq(la.mapping, none)

// `clip` defaults to true and is a layer-level field, never forwarded to the
// geom constructor as a parameter.
#assert.eq(lt.clip, true)
#assert.eq(lp.clip, true)

// `clip: false` is stamped on the layer (both data geoms and params-only
// geoms) and stays out of the params dict.
#let lc = annotate("point", x: 3, y: 4, clip: false)
#assert.eq(lc.clip, false)
#assert.eq(lc.params.at("clip", default: none), none)
#assert.eq(lc.data, ((x: 3, y: 4),))

#let lvc = annotate("vline", xintercept: 5, clip: false)
#assert.eq(lvc.clip, false)
#assert.eq(lvc.params.at("clip", default: none), none)
#assert.eq(lvc.params.xintercept, 5)

Annotate tests passed.
