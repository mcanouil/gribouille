// geom-typst smoke + annotate routing tests.

#import "../../src/geom/typst.typ": geom-typst
#import "../../src/annotate.typ": annotate
#import "../../src/utils/typst-markup.typ": is-typst-markup, typst

// Constructor returns a layer dict tagged with the right geom name.
#let g = geom-typst()
#assert.eq(g.kind, "layer")
#assert.eq(g.geom, "typst")
#assert.eq(g.stat, "identity")
#assert.eq(g.position, "identity")
#assert.eq(g.params.size, 10pt)
#assert.eq(g.params.anchor, "center")
#assert(not "dx" in g.params)
#assert(not "dy" in g.params)
#assert.eq(g.params.label, none)

// Constant `label:` accepts content blocks for direct Typst rendering.
#let g-content = geom-typst(label: [#math.alpha])
#assert.eq(g-content.params.label, [#math.alpha])

// Constant `label:` also accepts a markup string; `geom-typst` always
// evaluates labels as Typst.
#let g-string = geom-typst(label: "$alpha$")
#assert.eq(g-string.params.label, "$alpha$")

// annotate("typst", ...) routes through geom-typst.
#let a-typst = annotate("typst", x: 1, y: 2, label: "*hello*", anchor: "west")
#assert.eq(a-typst.geom, "typst")
#assert.eq(a-typst.inherit-aes, false)
#assert.eq(a-typst.data.len(), 1)
#assert.eq(a-typst.data.at(0).label, "*hello*")
#assert.eq(a-typst.params.anchor, "west")

// annotate("typst", label: [content]) stores the content verbatim in the
// synthetic row; the geom's typst-mark forces eval-as-markup, which returns
// content unchanged so the block renders directly.
#let a-typst-content = annotate("typst", x: 1, y: 2, label: [#math.alpha])
#assert.eq(a-typst-content.geom, "typst")
#assert.eq(a-typst-content.data.at(0).label, [#math.alpha])
#assert.eq(a-typst-content.mapping.label, "label")

// annotate("text", label: typst("...")) preserves the typst tag on the column
// reference so geom-text knows to evaluate the value as Typst markup; the
// row stores the unwrapped source string.
#let a-text = annotate("text", x: 1, y: 2, label: typst("$alpha$"))
#assert.eq(a-text.geom, "text")
#assert.eq(a-text.data.at(0).label, "$alpha$")
#assert(is-typst-markup(a-text.mapping.label))

// Plain string label leaves the mapping untagged.
#let a-plain = annotate("text", x: 1, y: 2, label: "plain")
#assert.eq(a-plain.data.at(0).label, "plain")
#assert.eq(a-plain.mapping.label, "label")

geom-typst + annotate routing tests passed.
