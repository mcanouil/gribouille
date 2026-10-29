// `stat-smooth` names `level` when it is outside (0, 1).
//
// `level: 1` used to fail inside `qnorm`, and `level: -0.5` drew an inverted band.
//
// expect: stat-smooth: level must be in (0, 1); got 1

#import "/lib.typ": stat-smooth

#stat-smooth(level: 1)
