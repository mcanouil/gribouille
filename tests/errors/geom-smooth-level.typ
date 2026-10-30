// `geom-smooth` reports a bad `level` under its own name.
//
// `level: 1` used to fail in `qnorm`.
//
// expect: geom-smooth: level must be in (0, 1); got 1

#import "/lib.typ": geom-smooth

#geom-smooth(level: 1)
