// `arrow()` fails when its head length is not a positive length.
//
// The message names the constraint the code applies. It used to quote an
// interval with a 1cm ceiling that nothing enforced, so `arrow(length: 5cm)`
// was accepted while the message said it could not be.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: length must be a positive length

#import "/lib.typ": arrow

#set page(width: 10cm, height: 8cm, margin: 0pt)

#arrow(length: -1pt)
