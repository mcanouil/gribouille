// `scales()` fails when an explicit minor break does not parse as a number.
//
// It used to raise the raw Typst error `cannot compare string and float`.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: scale-continuous: minor-breaks must be a number or an ISO date string; got "a"

#import "/lib.typ": scale-continuous, scales

#set page(width: 10cm, height: 8cm, margin: 0pt)

#scales(x: scale-continuous(minor-breaks: ("a",)))
