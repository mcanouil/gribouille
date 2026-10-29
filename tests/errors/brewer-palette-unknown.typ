// `brewer-palette()` fails on an unknown palette name.
//
// The message uses the `fail-enum` grammar and prints the name through `repr`.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: brewer-palette: name must be one of
// expect: got "Nope"

#import "/lib.typ": brewer-palette

#set page(width: 10cm, height: 8cm, margin: 0pt)

#brewer-palette("Nope")
