// `facet-wrap` rejects a labeller given by name.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: facet-wrap: labeller must be a labeller

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#let f = facet-wrap("g", labeller: "both")
