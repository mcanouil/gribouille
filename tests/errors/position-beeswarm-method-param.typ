// `position-beeswarm()` rejects a parameter that the chosen method ignores.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: position-beeswarm: adjust
// expect: quasirandom

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#position-beeswarm(method: "center", adjust: 2)
