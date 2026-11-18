// `position-beeswarm()` rejects an unknown method.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: position-beeswarm: method must be one of "quasirandom", "center"; got "hex"

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#position-beeswarm(method: "hex")
