// `annotate()` passes a key the target geom does not read to the geom.
//
// `geom-point` draws no width, so `width: 3` does not go into the inline row.
// It reaches `geom-point` as a constant, and the geom rejects it, as it
// rejects any constant for a key it does not read.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: geom-point: argument must be one of
// expect: got "width"

#import "/lib.typ": annotate

#set page(width: 10cm, height: 8cm, margin: 0pt)

#annotate("point", x: 1, y: 1, width: 3)
