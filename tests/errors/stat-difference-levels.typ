// stat-difference() rejects levels that are not two distinct strings.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: stat-difference: levels must be two distinct strings; got ("a", "a")

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#stat-difference(levels: ("a", "a"))
