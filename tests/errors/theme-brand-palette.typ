// theme-brand checks palette under its own name.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: theme-brand: palette must be a non-empty array
// expect: theme-brand(palette: 

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#theme-brand((color: (primary: "#E94C3D")), palette: ())
