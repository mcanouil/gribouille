// `position-dodge()` rejects a padding outside [0, 0.9].
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: position-dodge: padding must be in [0, 0.9]

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#position-dodge(padding: 5)
