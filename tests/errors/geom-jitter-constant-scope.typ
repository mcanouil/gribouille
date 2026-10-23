// `geom-jitter` names itself when it rejects a constant it does not draw.
//
// `geom-jitter` builds its layer through another geom constructor. The error used
// to name that constructor, not the function that the user called.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: geom-jitter: argument must be one of

#import "/lib.typ": geom-jitter

#set page(width: 10cm, height: 8cm, margin: 0pt)

#geom-jitter(xend: 3)
