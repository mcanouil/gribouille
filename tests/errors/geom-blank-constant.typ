// `geom-blank` fails with a clear message when it gets an aesthetic constant.
//
// `geom-blank` draws nothing and reads no aesthetic, so it accepts no
// constant. The message used to print an empty list of valid keys.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: geom-blank: takes no aesthetic constants; got "x"

#import "/lib.typ": geom-blank

#set page(width: 10cm, height: 8cm, margin: 0pt)

#geom-blank(x: 3)
