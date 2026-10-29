// `expand-limits()` fails when a value does not parse as a number.
//
// The value used to drop in silence.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: expand-limits: x must be a number or an ISO date string; got "abc"

#import "/lib.typ": expand-limits

#set page(width: 10cm, height: 8cm, margin: 0pt)

#expand-limits(x: "abc")
