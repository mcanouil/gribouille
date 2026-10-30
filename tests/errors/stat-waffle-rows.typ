// stat-waffle() rejects rows below 1.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: stat-waffle: rows must be a positive integer; got 0

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#stat-waffle(rows: 0)
