// A geom rejects an unknown position name under its own scope.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry every phrase below.
//
// expect: geom-point: position must be one of

#import "/lib.typ": *

#set page(width: 10cm, height: 8cm, margin: 0pt)

#geom-point(position: "jiter")
