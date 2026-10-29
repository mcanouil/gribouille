// `scales()` fails when a continuous limit does not parse as a number.
//
// The message uses the `; got` grammar and prints the value as the user wrote it.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: scale-continuous: lower limit must be a number, an ISO date string, or `auto`; got "abc"

#import "/lib.typ": scale-continuous, scales

#set page(width: 10cm, height: 8cm, margin: 0pt)

#scales(x: scale-continuous(limits: ("abc", 3)))
