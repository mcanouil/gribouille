// The stroke error shows the stroke the user wrote and names what is unsupported.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: element-line: stroke must be a length
// expect: Dash, cap and join are not supported
// expect: this stroke sets dash.

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#element-line(stroke: stroke(thickness: 1pt, dash: "dashed"))
