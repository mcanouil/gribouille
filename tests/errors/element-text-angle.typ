// An element-text angle must be an angle.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: element-text: angle must be an angle

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#element-text(angle: 45)
