// `guide-legend()` fails by name when a position offset has an `em` part.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: guide-legend: position offset dx must be an absolute length

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#guide-legend(position: (dx: 1em, dy: 0pt))
