// `position-beeswarm()` rejects method "center" with width 0 and auto spacing.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: position-beeswarm: spacing is auto and width is 0
// expect: Set `spacing`

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#position-beeswarm(method: "center", width: 0)
