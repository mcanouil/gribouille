// `guide-legend()` fails when `ncolumn` is below 1, where it used to clamp to 1.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: guide-legend: ncolumn must be

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#guide-legend(ncolumn: 0)
