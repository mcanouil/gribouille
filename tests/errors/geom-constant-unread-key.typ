// A geom fails when it gets a constant for an aesthetic it does not draw.
//
// `geom-point` draws no segment end, so `xend: 3` used to be stored in the
// layer params and then ignored. The geom now lists the keys it reads, and
// rejects a constant for any other key.
//
// `tools/check-errors.sh` compiles this file, requires the compile to fail, and
// requires the `error:` line to carry the phrase below.
//
// expect: geom-point: argument must be one of

#import "/lib.typ": geom-point

#set page(width: 10cm, height: 8cm, margin: 0pt)

#geom-point(xend: 3)
