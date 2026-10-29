// `stat-smooth` fails when `level` is negative.
//
// `level: -0.5` used to draw an inverted band.
//
// expect: stat-smooth: level must be in (0, 1); got -0.5

#import "/lib.typ": stat-smooth

#stat-smooth(level: -0.5)
