// `position-beeswarm()` rejects an adjust of zero.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: position-beeswarm: adjust must be a positive number

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#position-beeswarm(adjust: 0)
