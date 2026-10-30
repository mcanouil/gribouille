// `geom-line()` rejects a linetype that Typst does not know.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: geom-line: linetype must be one of

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#geom-line(linetype: "wiggly")
