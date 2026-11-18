// `position-beeswarm()` rejects `binwidth` and `spacing` under "quasirandom".
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: position-beeswarm: binwidth and spacing
// expect: center

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#position-beeswarm(method: "quasirandom", binwidth: 1)
