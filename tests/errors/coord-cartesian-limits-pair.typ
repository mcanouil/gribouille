// `coord-cartesian()` rejects limits that are not a pair of numbers.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: coord-cartesian: x-limits must be
// expect: (lo, hi) pair

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#coord-cartesian(x-limits: (3,))
