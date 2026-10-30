// stat-connect() rejects a smooth value that is not positive.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: stat-connect: smooth must be a positive number; got 0

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#stat-connect(smooth: 0)
