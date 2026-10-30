// `geom-crossbar()` rejects a width that is a length.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: geom-crossbar: width must be a number

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#geom-crossbar(width: 5pt)
