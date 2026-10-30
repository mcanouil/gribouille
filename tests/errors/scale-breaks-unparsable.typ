// `scales()` fails when an explicit break does not parse as a number.
//
// A break is a user argument, not a data cell. It used to drop in silence,
// while the same value in `limits` failed.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: scale-continuous: breaks must be a number or an ISO date string; got "abc"

#import "/lib.typ": scale-continuous, scales

#set page(width: 10cm, height: 8cm, margin: 0pt)

#scales(x: scale-continuous(breaks: (1, "abc", 3)))
